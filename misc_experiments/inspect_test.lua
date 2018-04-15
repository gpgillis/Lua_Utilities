-------------------------------------------------------------------------------
-- INSPECT TEST:
-- 
-- Testing the inspect debugging utility 
-- https://github.com/kikito/inspect.lua
-- locally located at /lua/lua/inspect.lua
--
-- From the inpect documentation:
--		Human-readable representation of Lua tables 
--
--		This library transforms any Lua value into a human-readable representation. It is especially useful for debugging errors in tables.
--
--		The objective here is human understanding (i.e. for debugging), not serialization or compactness.
--
--	GPG 20150604
-------------------------------------------------------------------------------

local inspect = require("inspect")

local t = {1, 2, 3}
local mt = { b = 2 }
setmetatable(t, mt)

local dict = {a=1, b=2, c=3}


local remove_mt = function(item)
	if (item ~= mt) then return item end
end

print ("Inspecting dict")
print(inspect(dict))

print("Inspecting t")

print (inspect(t))

print("Inspecting t w/o meta")
print (inspect(t, {process = remove_mt}))

print("Asserting t")
assert(inspect(t, {process = remove_mt}) == "{ 1, 2, 3 }")

