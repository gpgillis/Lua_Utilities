-- Test Matching - this is some example code for string pattern matching
-- Reference:
-- Example code: http://stackoverflow.com/questions/6243829/lua-string-match-problem
-- Pattern matching documentation for LUA: http://www.lua.org/manual/5.1/manual.html#5.4.1

-- GPG 20110608

local s = {
"  Code                                             : 75.570 ",
"  ..dll                                   :          13.559       1",
"  ..node                                    :  4.435    1.833    5461",
"  ..NavRegions                                     :  0.000         "
}

----------------------------------------------------------------
-- PrintSourceStrings
-- Prints the source strings being used in the matching examples
-- so we can better visualize the returned matching data.
function PrintSourceStrings()
	print("These are the source strings being matched ... ")
	for k,v in pairs(s) do print(v) end
	print("")
end

----------------------------------------------------------------
-- FirstMatchExample
-- This is the first matching example code.
function FirstMatchExample()
	print("This is the first matching example ... ")
	
	for k,v in pairs(s) do
		print("matching ... ")
		local m1, m2, m3 = v:match('%s*([%w%.]+)%s*:%s*([%d%.]+)%s*([%d%.]*)%s*([%d%.]*)')
		print("M1 = " .. m1)
		print("M2 = " .. m2)
		print("M3 = " .. m3)
	end
	
end

----------------------------------------------------------------
-- SecondMatch
-- This is the second matching example code.
function SecondMatch()
	print("This is the second matching example ... ")
	
	local moduleInfo, name = {};
	for k,v in pairs(s) do
		for word in v:gmatch("%S+") do
				if (word~=":") then
						word = word:gsub(":", "");
						local number = tonumber(word);
						if (number) then
								moduleInfo[#moduleInfo+1] = number;
						else
								if (name) then
										name = name.." "..word:gsub("%$", "");
								else
										name = word:gsub("%$", "");
								end
						end
				end
		end
	end

		print("Name = " .. name)
	for k,v in pairs(moduleInfo) do
		print("Module info = " .. v)
	end

end


-------------------------------------------------------------------------------
---															Main Script																	---
-------------------------------------------------------------------------------

PrintSourceStrings()
FirstMatchExample()
SecondMatch()