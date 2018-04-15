-------------------------------------------------------------------------------
-- ENCAPSFUNC
--
--	An experiment for function encapsulation for success evaluations (as the property of a function).
--

local gpg = require "gpgUtilities"
local inspect = require "inspect"

function TestMe(a)
	return a > 0
end


function Process(a1, a2, a3, a4)
	local rtn = { success = nil, a1 = nil, a2 = nil, a3 = nil, a4 = nil, val = nil}
	
	local function successEval(collection)
		assert(collection ~= nil and type(collection) == "table", "What?")
		local c = collection
		return function()
			print(inspect(c))
			local s = c.a1 ~= nil and c.a2 ~= nil and c.a3 ~= nil and c.a4 ~= nil
			s = s and TestMe(c.a1)
			s = s and TestMe(c.a2)
			if (not(s)) then c.help = true end
			return s
		end
	end
	
	local function val(collection)
		assert(collection ~= nil and type(collection) == "table", "what?")
		local c = collection
		return function ()
			return (c.success()) and c.a1 + c.a2 + c.a3 + c.a4 or 0
		end
	end
	
	rtn.a1 = a1
	rtn.a2 = a2
	rtn.a3 = a3
	rtn.a4 = a4
	rtn.success = successEval(rtn)
	rtn.val = val(rtn)
	return rtn
end


local rtn = Process(0, 2, 3, 4)

print(gpg.FormatTitle({"ENCAPSFUNC", "A function encapsulation experiment."}))

print(inspect(rtn))

if (rtn.success()) then 
	print("Success!") 
	print(rtn.val())
else 
	print("FAIL!")
	print(rtn.val())
end