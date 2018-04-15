-- Testing localization of data elements using require file directives.

local modname = ... 
local M = {}
_G[modname] = M
package.loaded[modname] = M
setmetatable(M, {__index = _G})
setfenv(1, M)


-- There is a local copy of g_myData in the consumer code - this is the basis of the scope test.
local g_myData = nil


-------------------------------------------------------------------------------
--
function AddMyData(...)
	local args = {...}
	local flags = {}

	if (#args == 0) then ClearMyData() end
	
	if (#args == 1 and type(args[1]) == "table") then args = args[1] end

	g_myData = args

end 

-------------------------------------------------------------------------------
--
function PrintMyData()
	if (g_myData == nil) then return end
	
	
	for k,v in pairs(g_myData) do
		print("K = " .. k .. " V = " .. v)
	end

end

-------------------------------------------------------------------------------
--
function ClearMyData()

	g_myData = nil
	
end