local gpg = require "gpgUtilities"

function DoSomeStuff(...)
	local data
	if (type(...) == "table") then data = ... else data = {...} end

	local fmt = "TestThisItem %s\n"
	local rtn = ""
	
	for k, v in pairs(data) do
		rtn = rtn .. string.format(fmt, v)
	end
	
	return rtn
end

function DoOtherStuff(fun, ...)
	print("The type of the argument is " .. type(fun))

	return fun(...)
end


function ProcessGroups(...)
	local rtn = ""
	local data = {...}
	
	
	for k,v in pairs(data) do
		local r = DoSomeStuff(v)
		if (not(gpg.StringIsNilOrEmpty(r))) then rtn = rtn .. r end
	end
	
	return rtn
end


function DoEverythingCombined(...)
	local args = {...}

	local fmt = "TestThisItem %s\n"
	local rtn = ""
	
	for k, v in pairs(args) do
		local data
		
		if (type(v) == "table") then data = v else data = {v} end
		
		for i, j in pairs(data) do
			rtn = rtn .. string.format(fmt, j)
		end
	end
	
	return rtn
end


print("This is a simple test .. ")

local v = DoSomeStuff("item1", "item2", "item3", "item4")

print("Done ... results are : ")
print(v)

print("Now a callback test .. of sorts")
v = DoOtherStuff(DoSomeStuff, "itemA", "itemB", "itemC")
print(v)


print("Now try processing groups of data ... ")

local numgroup = {"1", "2", "3"}
local letgroup = {"A", "B", "C"}
v = ProcessGroups(numgroup, letgroup)
print(v)
v = ProcessGroups("Z", "X")
print(v)
v = ProcessGroups("H")
print(v)


print("Now try processing groups of data with DoEverythingCombined ... ")

local numgroup = {"1", "2", "3"}
local letgroup = {"A", "B", "C"}
v = DoEverythingCombined(numgroup, letgroup)
print(v)
v = DoEverythingCombined("Z", "X")
print(v)
v = DoEverythingCombined("H")
print(v)
