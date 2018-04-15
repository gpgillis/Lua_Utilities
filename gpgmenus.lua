-------------------------------------------------------------------------------
-- gpg Menus : A collection of menu utilities for LUA scripts
-- All rights are reserved. Reproduction or transmission in whole or in part, in
-- any form or by any means, electronic, mechanical or otherwise, is prohibited
-- without the prior written permission of the copyright owner.
--
-- Author: GPG - 20110420
-------------------------------------------------------------------------------

--[[
This module provides a set of methods that can be used to create and
process a menu system for command prompt interaction with a user

This allows for simple menuing requirements in application code and frees
the consumer from repeating menu code in all applications that require menus

Example menu setup for an application:

1.  Add in the gpg Menus module:

		local menu = require("gpgMenus")

2.  The menu items and corresponding functions are contained in a menu table:

		The first element is the string that will show on the menu, the second is the 
		function call for that menu selection.

		This function call can be defined in two ways - either as the function itself 
		or a string containing the function name.
		
		The advantage of having the function call itself is if a function is deleted from
		the script, you will know the first time the script is run since there will be
		an initialization error.  The disadvantage is that the menu must be defined after
		all functions that will be used in the menu are defined in the file.  
		
		The opposite advantages and disadvantages are true for strings containing the 
		function name - the menu can be defined anywhere in the script but if a function
		called out in the menu definition has been removed, you will only know from an 
		exception when the missing function is called via the menu.
		
		For a function name string "Menu_RunBob" is the call to the function Menu_RunBob()
		For a function name itself you use the function name without the parenthesis.

		A menu defined with strings:
		local menuCombined = 
		{
				{"Run Bob Item", "Menu_RunBob"},
				{"Run George Item", "Menu_RunGeorge"},
				{"Run Sam Item", "Menu_RunSam"},
				{"Exit", "Menu_QuitApp"}
		}

		The same menu defined with functions:
		local menuCombined = 
		{
				{"Run Bob Item", Menu_RunBob},
				{"Run George Item", Menu_RunGeorge},
				{"Run Sam Item", Menu_RunSam},
				{"Exit", Menu_QuitApp}
		}

3.  Make sure that your application defines a quit method that sets the menu quit flag.

		This can be done in a number of ways.  You can have a function that sets the quit flag and
		call that function.  This is useful if you have other clean up code that needs to be run.

		Example (called for menu selection 'Exit' in the above menu definition example):
		function QuitApp()
			menu.SetQuitRequest()
		end
		
		A simpler method is to define the 'Exit' menu selection to call menu.SetQuitRequest()
		directly.
		
		local menuCombined = 
		{
			{"Run Bob Item", Menu_RunBob},
			{"Run George Item", Menu_RunGeorge},
			{"Run Sam Item", Menu_RunSam},
			{"Exit", menu.SetQuitResponse}
		}

4.  In the main scripting code - initialize and use the menu:

		local menuName = "Main"
		local menuHeader = "My Menu Selections"

		if (menu.InitializeMenu(menuName, menuHeader, false, menuCombined, true)) then
			repeat menu.ShowMenu() until (menu.ProcessMenuSelection(io.read()))
		end

		Note that the third argument in InitializeMenu is optional - if this argument
		is set true AND there is a menu selection that contains 'quit' or 'exit' (case insensitive)
		then that function is used as a quit function if the user enters an empty string as the
		menu selection.

		Any closing code can be placed after this block of code or in the application quit method.

-- There are other examples unit tests file located at test_gpgmenus.lua.

Happy Menuing ... 

]]

local modname = ... 
local M = {}

M.private = {}	-- private variables for unit testing.

_G[modname] = M
package.loaded[modname] = M
setmetatable(M, {__index = _G})
setfenv(1, M)

local inspect = require("inspect")

-- Meta information
-- _DESCRIPTION = "A collection of menu utilities for LUA scripts"
-- _VERSION = modname .. " 1.0.0"

local gpg = require "gpgUtilities"
gpg.SetShowDebugMessages(false)

local l_defaultMenuName = "DEFAULTMENUNAME"
local l_menuCount = 0
local l_menuName = ""
local l_availableMenus = {}
local l_menuItems = {}
local l_menuActions = {}
local l_quitItemAction = ""
local l_quitRequest = false
local l_headerText = ""
local l_isSubMenu = false

local l_parentMenuStack = {}	-- Stack to store parent menu when running sub menus.


-------------------------------------------------------------------------------
-- Reset:
--	Resets the menu handler - either reset only the current menu variables
--	or reset the entire handler.
--
--	Arguments
--		resetAll	: If true the entire menu handler is cleared.
--
function Reset(resetAll)
	if (resetAll == nil) then resetAll = false end
	
	l_menuName = ""
	l_menuItems = {}
	l_menuActions = {}
	l_quitItemAction = ""
	l_quitRequest = false
	l_headerText = ""
	l_isSubMenu = false

	if (resetAll) then
		l_availableMenus = {}
		l_menuCount = 0
	end
	
end		-- Reset

-------------------------------------------------------------------------------
-- InitializeMenu
-- Sets up menu for operations using a combined list of items and actions.
--
--	Arguments:
--		name									:	Menu name - the key that will be used to look up and run the menu.
--		header								:	Header text for the menu.
--		isSubMenu							:	Flag indicating this is a sub menu.  A submenu will reset the quit flag on exit.
--		combinedItemActions		: A list of combined menu items and actions - each row in list is a list of { item, action }
--		quitOnEmptySelection	:	If true then an empty selection causes the application to quit.
--														Note - if set true then a menu item called "Quit" or "Exit' is required.
--
-- Returns:
--	true if menu has been initialized; false otherwise.
--
function InitializeMenu(name, header, isSubMenu, combinedItemActions, quitOnEmptySelection)
	assert(combinedItemActions ~= nil and type(combinedItemActions) == "table", "The combinedItemActions collection must be a table.")
	local items = {}
	local actions = {}

	for i = 1, #combinedItemActions do
		table.insert(items, combinedItemActions[i][1])
		table.insert(actions, combinedItemActions[i][2])
	end

	return InitializeMenuWithSeparateItems(name, header, isSubMenu, items, actions, quitOnEmptySelection)
end	-- InitializeMenu

-------------------------------------------------------------------------------
-- InitializeMenuWithSeparateItems
--	Sets up menu for operations using a separate list of items and actions.
--
--	Arguments:
--		name									:	Menu name - the key that will be used to look up and run the menu.
--		header								:	Header text for the menu.
--		isSubMenu							:	Flag indicating this is a sub menu.  A submenu will reset the quit flag on exit.
--		items 								:	A list of items to show as the menu selections.
--		actions								:	A list of actions that correspond to the item selections.
--		quitOnEmptySelection	:	If true then an empty selection causes the application to quit.
--														Note - if set true then a menu item called "Quit" or "Exit' is required.
--
--	Returns:
--		true if menu has been initialized; false otherwise.
--
function InitializeMenuWithSeparateItems(name, header, isSubMenu, items, actions, quitOnEmptySelection)
	if (gpg.StringIsNilOrEmpty(name)) then name = l_defaultMenuName end
	if (gpg.StringIsNilOrEmpty(header)) then header = "" end
	if (isSubMenu == nil) then isSubMenu = false end
	assert(items ~= nil and type(items) == "table", "The items collection must be a table.")
	assert(actions ~= nil and type(actions) == "table", "The actions collection must be a table.")
	assert(#items == #actions, "Initialization ERROR - the number of selection items does not equal the number of actions!")

	local quitAction = ""

	if (quitOnEmptySelection) then
		for i = 1, #items do
			test = string.upper(items[i])
			if (string.find(test, "QUIT") ~= nil or string.find(test, "EXIT") ~= nil or string.find(test, "RETURN") ~= nil ) then 
				quitAction = actions[i] 
				break
			end
		end

		assert(not(gpg.StringIsNilOrEmpty(quitAction)), "Quit on blank selection is set but no 'Quit', 'Return' or 'Exit' menu item has been found.")
	end

	l_availableMenus[name] = { headerText = header, isSub = isSubMenu, menuItems = items, menuActions = actions, quitItemAction = quitAction }
	l_menuCount = l_menuCount + 1
	if (gpg.GetShowDebugMessages()) then print("Menus table contains : \n" .. inspect(l_availableMenus)) end

	M.private.menuCount = l_menuCount
	M.private.menuInitializedAsSub = isSubMenu

	return true
end	-- InitializeMenu

-------------------------------------------------------------------------------
-- SetQuitRequest
--	Sets the quit request flag to be used by ProcessMenuSelection for return value.
--
function SetQuitRequest()
	l_quitRequest = true
end	-- SetQuitRequest

-------------------------------------------------------------------------------
-- PerformMenuAction
--	Converts menu action string from menuActions into a method call or simply
--	runs the provided action.
--
--	Arguments:
--		action	: The action to be performed.
--
local function PerformMenuAction(action)
	local act = action
	
	if (type(action) == "string") then
		if (_G[action] == nil) then _G[action] = loadstring(action) end
		assert(_G[action] ~= nil, "The defined action " .. action .. " is not defined as a function!")
		action = _G[action]
	end

	M.private.action = action
	action()
end	-- PerformMenuAction

-------------------------------------------------------------------------------
-- ProcessMenuSelection
--	Process a menu selection into an menu action call.
--
--	Arguments:
--		selection	: The index into the menu items array that corresponds to the desired action.
--
--	Returns:
--		true if the quit request flag is set; false otherwise.
--
function ProcessMenuSelection(selection)
	if (not(gpg.StringIsNilOrEmpty(l_quitItemAction)) and gpg.StringIsNilOrEmpty(selection)) then
		PerformMenuAction(l_quitItemAction)
		return l_quitRequest
	end

	selection = tonumber(selection)
	if(selection == nil or selection > #l_menuActions) then
		print("\nInvalid menu selection - please make another selection.")
		return false
	end

	for i = 1, #l_menuActions do
		if i == selection then PerformMenuAction(l_menuActions[i]) end
	end

	return l_quitRequest
end	-- ProcessMenuSelection

-------------------------------------------------------------------------------
-- RestoreParent
--	Restores the parent menu from a sub menu in operation.
--
function RestoreParent()
	gpg.DebugMessage("Entering RestoreParent from menu " .. l_menuName .. " l_isSubMenu == " .. tostring(l_isSubMenu))
	assert (l_isSubMenu, "Calling restore parent from a non-sub menu in operation is invalid!")
	assert(table.containsKey(l_parentMenuStack, l_menuName), "No parent for the menu " .. l_menuName .. " can be found.")

	ShowMenu(l_parentMenuStack[l_menuName])
end		-- RestoreParent

-------------------------------------------------------------------------------
-- LoadMenu
--	Loads a menu and prepares for operation.
--	Arguments
--		name : Name of the menu to load - needs to be the same name the menu was defined with.
--
function LoadMenu(name)

	if (gpg.StringIsNilOrEmpty(name)) then
		name = l_menuCount == 1 and table.Keys(l_availableMenus)[1] or l_defaultMenuName
	end
	assert(table.containsKey(l_availableMenus, name), "The requested menu " .. name .. " has not be defined!")
	
	if (l_availableMenus[name].isSub) then		-- Save the parent menu name for restoration.
		gpg.DebugMessage("A sub menu " .. name .. " has been requested for parent menu " .. l_menuName)
		l_parentMenuStack[name] = l_menuName
		gpg.DebugMessage("\n" .. inspect(l_parentMenuStack))
	end

	Reset(false)
	l_menuName = name
	l_menuItems = l_availableMenus[name].menuItems
	l_menuActions = l_availableMenus[name].menuActions
	l_quitItemAction = l_availableMenus[name].quitItemAction
	l_headerText = l_availableMenus[name].headerText
	l_isSubMenu = l_availableMenus[name].isSub
	
	M.private.menuName = l_menuName
	M.private.headerText = l_headerText
	M.private.isSubMenu = l_isSubMenu

end	-- LoadMenu

-------------------------------------------------------------------------------
-- ShowMenu
--	Displays the menu contents and related prompt strings.
--
function ShowMenu(name)
	gpg.DebugMessage("ShowMenu called for menu " .. (name ~= nil and name or "*None Specified*"))
	
	if (gpg.StringIsNilOrEmpty(name) or name ~= l_menuName) then LoadMenu(name) end
	if (not(gpg.StringIsNilOrEmpty(l_headerText))) then print(l_headerText) end
	assert(#l_menuItems > 0, "There are no menu items to show - why?")

	for i = 1, #l_menuItems do
		print(string.format("%i.\t%s", i, l_menuItems[i]))
	end
	io.write("\nPlease make a selection : ")
end	-- ShowMenu
