-------------------------------------------------------------------------------
-- Testing table initializations
-- includes some 'inspect' debugging usage!
--
-- GPG 20150605
-------------------------------------------------------------------------------


local inspect = require("inspect")
local gpg = require("gpgUtilities")

local items = {"FirstItem", "SecondItem", "ThirdItem"}
local items2 = {"FirstItem2", "SecondItem2", "ThirdItem2"}

local actions = {"FirstAction", "SecondActions", "ThirdAction"}
local actions = {"FirstAction2", "SecondActions2", "ThirdAction2"}

local quitAct = "QuitMe"
local quitAct2 = "QuitMe2"



local menus = {}


menus["First"] = {menuItems = items, menuActions = actions, quitAction = quitAct}
menus["Second"] = {menuItems = items2, menuActions = actions2, quitAction = quitAct2}

print("Menu test!")

print(inspect(menus))


for k,v in pairs(menus["First"].menuItems) do
	print("Menu Item " .. v .. " is location " .. k)
end

for k,v in pairs(menus["First"].menuActions) do
	print("Menu Action " .. v .. " is location " .. k)
end

print ("Quit action is " .. menus["First"].quitAction)

local keys = table.Keys(menus)

print(inspect(menus[keys[1]].menuItems))
