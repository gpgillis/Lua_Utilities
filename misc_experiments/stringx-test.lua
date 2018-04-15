--[[
	This is a silly little recursion test that was inspired by a Daily WTF submission:
	In Java:
						Question 1
					(a) What does the following function do?  
					(b) How could the function be improved?
					(c) Rewrite the function with your suggested improvements.

					String funcX (String s) {
						if (s == null || s.length() == 1 || s.length() == 0) {
							return s;
						} else {
							return funcX(s.substring(1)) + s.substring(0, 1);
						}
					}
]]


function StringX(str, count)
	if (str == nil or string.len(str) <= 1) then
		print("No recursion")
		return str
	else
		if count == string.len(str) then return str else count = count + 1 end
		
		print (string.format("Count = %i, str = %s", count, str))
		return StringX(string.sub(str, 2) .. string.sub(str, 1, 1), count)
	end
end


local s = "This is a string"

print (StringX(s, 0))
print (StringX("this", 0))
print (StringX("t", 0))
