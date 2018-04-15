-------------------------------------------------------------------------------
-- Unit Tests for gpg Menus
-- 
-- There are examples and unit tests both mixed into this file.
-- The unit tests are run first, followed by the menu examples.
-- See the 'MAIN' section of this file.
--
-- GPG - 20150604
-------------------------------------------------------------------------------


local menu = require("gpgMenus")
local luaunit = require("LuaUnit")
local inspect = require("inspect")

-------------------------------------------------------------------------------
-- Stub functions used by the menu examples:
-------------------------------------------------------------------------------

function Menu_RunBob() print("\n** Run_Bob\n") end
function Menu_RunGeorge() print("\n** Run_George\n") end
function Menu_RunSam() print("\n* Run_Sam\n") end

function Menu_RunBobSub() print("\n** ** Run_Bob_Sub\n") end
function Menu_RunGeorgeSub() print("\n** ** Run_George_Sub\n") end
function Menu_RunSamSub() print("\n** ** Run_Sam_Sub\n") end

function Menu_RunSecondOne() print("\n** Run Second One\n") end
function Menu_RunSecondTwo() print("\n** Run Second Two\n") end
function Menu_RunSecondThree() print("\n** Run Second Three\n") end

local l_subMenuName = "SubMenu"
function Menu_RunSubMenu()
	print("\n-- This is the sub menu:")
	repeat menu.ShowMenu(l_subMenuName) until (menu.ProcessMenuSelection(io.read()))
	menu.RestoreParent()
end

function Menu_QuitApp() print("** Menu_QuitApp") menu.SetQuitRequest() end

-------------------------------------------------------------------------------
-- Menu definitions used by examples:
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- A menu with actions defined with strings:
local menuStrings = 
{
		{"Run Bob Item", "Menu_RunBob"},
		{"Run George Item", "Menu_RunGeorge"},
		{"Run Sam Item", "Menu_RunSam"},
		{"Exit", "Menu_QuitApp"}
}

-------------------------------------------------------------------------------
-- The same menu with actions defined with functions:
local menuFunctions = 
{
		{"Run Bob Item", Menu_RunBob},
		{"Run George Item", Menu_RunGeorge},
		{"Run Sam Item", Menu_RunSam},
		{"Exit", Menu_QuitApp}
}

-------------------------------------------------------------------------------
-- A secondary menu with actions defined with functions
local menuFunctionsSecond = 
{
		{"Run Second Item One", Menu_RunSecondOne},
		{"Run Second Item Two", Menu_RunSecondTwo},
		{"Run Second Item Three", Menu_RunSecondThree},
		{"Exit", menu.SetQuitRequest},
}

-------------------------------------------------------------------------------
-- A menu that contains a sub menu selection:
local menuPrimary = 
{
		{"Run Bob Item", Menu_RunBob},
		{"Run George Item", Menu_RunGeorge},
		{"Run Sub Menu Item", Menu_RunSubMenu},
		{"Exit", Menu_QuitApp}
}
-- The sub menu for above:
local menuSecondary = 
{
		{"Run Bob Sub Item", Menu_RunBobSub},
		{"Run George Sub Item", Menu_RunGeorgeSub},
		{"Run Sam Sub Item", Menu_RunSamSub},
		{"Return", menu.SetQuitRequest}
}


-------------------------------------------------------------------------------
-- ShowMenuHeaderForExample
--	A consistent UI element that displays the header text for each menu example.
--
function ShowMenuHeaderForExample(header)
	print("\n\n-------------------------------------------------------------------------------")
	print("EXAMPLE : " .. header .. "\n\n")
end		-- ShowMenuHeaderForExample

-------------------------------------------------------------------------------
-- RunMenuExamples
-- A collection of menu examples
--
function RunMenuExamples ()

	print("\n\n-------------------------------------------------------------------------------")
	print("A selection of menu examples:")
	print("-------------------------------------------------------------------------------")

	local menuName = ""
	local menuHeader = ""

	-------------------------------------------------------------------------------
	-- Menu Example: default menu name, actions defined by strings.
	menuHeader = "A menu example with menu actions defined by strings:"
	ShowMenuHeaderForExample(menuHeader)
	menu.InitializeMenu(menuName, menuHeader, false, menuStrings, true)
	repeat menu.ShowMenu(menuName) until (menu.ProcessMenuSelection(io.read()))
	menu.Reset(true)

	-------------------------------------------------------------------------------
	-- Menu Example: single menu, default menu name, actions defined by functions.
	menuHeader = "A menu example with menu actions defined by functions:"
	ShowMenuHeaderForExample(menuHeader)
	menu.InitializeMenu(menuName, menuHeader, false, menuStrings, true)
	repeat menu.ShowMenu(menuName) until (menu.ProcessMenuSelection(io.read()))
	menu.Reset(true)

	-------------------------------------------------------------------------------
	-- Menu Example: mutiple menus, run each by selecting the menu by name.
	menuName = "MultiMenu"
	menuHeader = "A menu example with multiple menues:"
	ShowMenuHeaderForExample(menuHeader)
	menu.InitializeMenu(menuName, menuHeader, false, menuFunctions, true)
	menu.InitializeMenu(menuName .. "2", menuHeader, false, menuFunctionsSecond, true)
	print ("Running the first menu:")
	repeat menu.ShowMenu(menuName) until (menu.ProcessMenuSelection(io.read()))
	print ("\n\nRunning the second menu:")
	repeat menu.ShowMenu(menuName .. "2") until (menu.ProcessMenuSelection(io.read()))
	menu.Reset(true)

	-------------------------------------------------------------------------------
	-- Menu Example: A menu with a sub menu.
	menuHeader = "A menu example with a menu that contains a sub menu:"
	subMenuHeader = "The sub menu:"
	menuName = "MainMenu"
	subMenuName = l_subMenuName
	ShowMenuHeaderForExample(menuHeader)
	menu.InitializeMenu(menuName, menuHeader, false, menuPrimary, true)
	menu.InitializeMenu(subMenuName, subMenuHeader, true, menuSecondary, true)
	print ("-- Running the first menu:")
	repeat menu.ShowMenu(menuName) until (menu.ProcessMenuSelection(io.read()))
	menu.Reset(true)
	
end		-- RunMenuExamples


-------------------------------------------------------------------------------
-- Unit Test Definitions
-------------------------------------------------------------------------------

TestgpgMenus = {}
	-------------------------------------------------------------------------------
	-- Setup
	function TestgpgMenus:setUp()
		menu.Reset(true)
	end

	-------------------------------------------------------------------------------
	-- Failure: Menu initialized without an items/actions collection
	function TestgpgMenus:testMenuInitializationWithNoItemActionCollectionFailure()
		menu.Reset(true)
		luaunit.assertError(menu.InitializeMenu, "", "", false, nil)
	end

	-------------------------------------------------------------------------------
	-- Failure: Quit on blank selection but no quit, return or exit menu item found.
	function TestgpgMenus:testQuitOnBlankSelectedWithNoExitItemFailure()
		menu.Reset(true)
		local menuBroken = 
		{
				{"Run Second Item One", Menu_RunSecondOne},
				{"Run Second Item Two", Menu_RunSecondTwo},
				{"Run Second Item Three", Menu_RunSecondThree},
				{"Exit", ""}
		}

		menuName = "broken"
		menuHeader = "Broken Menus"

		luaunit.assertError(menu.InitializeMenu, menuName, menuHeader, false, menuBroken, true)
	end

	-------------------------------------------------------------------------------
	-- Failure : Items count ~= actions count.
	function TestgpgMenus:testItemsCountNotEqualToActionsCountFailure()
		menu.Reset(true)
		local mungedMenuItems = { "RunBob", "RunSam", "Exit"}
		local mungedMenuActions = { Menu_RunBob, Menu_RunSam }
		luaunit.assertError(menu.InitializeMenuWithSeparateItems, "broken", "", false, mungedMenuItems, mungedMenuActions, true)
	end

	-------------------------------------------------------------------------------
	-- Failure : Test Menu Initialization. Load and Action with invalid load menu name
	function TestgpgMenus:testMenuLoadWithInvalidName()
		menu.Reset(true)
		local menuName = "MainMenu"
		local menuHeader = "This is the menu header."
		luaunit.assertTrue(menu.InitializeMenu(menuName, menuHeader, false, menuFunctions, true))
		luaunit.assertEquals(menu.private.menuCount, 1)
		luaunit.assertFalse(menu.private.IsSubMenu)
		luaunit.assertError(menu.LoadMenu, "InvalidName")
	end

	-------------------------------------------------------------------------------
	-- Failure : Test sub menu call with no sub menu
	function TestgpgMenus:testSubMenuInitializeAndLoad()
		menu.Reset(true)
		local menuName = "MainMenu"
		local menuHeader = "This is the menu header."
		
		-- Initialize and load a parent menu - show succeed.
		luaunit.assertTrue(menu.InitializeMenu(menuName, menuHeader, false, menuFunctions, true))
		menu.LoadMenu(menuName)
		luaunit.assertEquals(menu.private.menuName, menuName)
		luaunit.assertEquals(menu.private.menuCount, 1)
		luaunit.assertFalse(menu.private.IsSubMenu)

		-- Call to restore parent - should fail because the current menu is not a sub menu.
		luaunit.assertErrorMsgContains("Calling restore parent from a non-sub menu in operation is invalid!", menu.RestoreParent)

		-- Initialize and load a sub menu and call restore parent - should succeed.
		luaunit.assertTrue(menu.InitializeMenu(menuName .. "_SUB", menuHeader, true, menuFunctions, true))
		luaunit.assertEquals(menu.private.menuCount, 2)
		luaunit.assertTrue(menu.private.menuInitializedAsSub)
		menu.LoadMenu(menuName .. "_SUB")
		luaunit.assertEquals(menu.private.menuName, menuName .. "_SUB")
		luaunit.assertTrue(menu.private.isSubMenu)
		menu.RestoreParent()
		luaunit.assertEquals(menu.private.menuName, menuName)
		luaunit.assertFalse(menu.private.isSubMenu)
	end

		-------------------------------------------------------------------------------
	-- Success : Test Menu Initialization. Load and Action
	function TestgpgMenus:testMenuInitializationWithNoMenuName()
		menu.Reset(true)
		local menuName = ""
		local menuHeader = "This is the menu header."
		luaunit.assertTrue(menu.InitializeMenu(menuName, menuHeader, false, menuFunctions, true))
		luaunit.assertEquals(menu.private.menuCount, 1)
		menu.LoadMenu()
		luaunit.assertEquals(menu.private.headerText, menuHeader)
	end

	-------------------------------------------------------------------------------
	-- Success : Test Menu Initialization. Load and Action
	function TestgpgMenus:testMenuInitializationLoadAndAction()
		menu.Reset(true)
		local menuName = "MainMenu"
		local menuHeader = "This is the menu header."
		luaunit.assertTrue(menu.InitializeMenu(menuName, menuHeader, false, menuFunctions, true))
		luaunit.assertEquals(menu.private.menuCount, 1)
		menu.LoadMenu(menuName)
		luaunit.assertEquals(menu.private.menuName, menuName)
		menu.ProcessMenuSelection("2")
		luaunit.assertEquals(menu.private.action, Menu_RunGeorge)
	end

	-------------------------------------------------------------------------------
	--
	function TestgpgMenus:tearDown()
		menu.Reset(true)
	end

-- end TestgpgMenus


-------------------------------------------------------------------------------
--										MAIN 
-------------------------------------------------------------------------------
luaunit.LuaUnit.run("-v")


print("\n\n")
print("-------------------------------------------------------------------------------")
io.write("Run Menu Examples (Y/N)? ")
local ans = io.read()
if (string.upper(ans) == "Y") then 
	RunMenuExamples()
	print("\n\n** Complete")
end
