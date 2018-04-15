-- This is a test of command line parsing
-- GPG 20120521

local gpg = require("gpgutilities")


print("What command line arguments did we get? - ")

if (#arg >= 1) then 
	for i = 0, #arg, 1 do print("\t" .. arg[i]) end
else 
	print("none") 
end

print("\nTesting parsing the provided command line arguments ...")
local arguments, str = gpg.ParseFlags(arg);
for k, v in pairs(arguments) do print("K = " .. gpg.SafeString(k) .. " V = " .. tostring(v)) end
for k, v in pairs(str) do print ("String : (" .. k .. ") " .. gpg.SafeString(v)) end

print ("\nThis is a test of command line parsing")

local arguments, str = gpg.ParseFlags("foo", "--tux=beep", "--bla", "bar", "--baz")

if (type(arguments) ~= "table") then 
	print("There does not seem to be a table here")
	exit(0)
end

for k, v in pairs(arguments) do print("K = " .. gpg.SafeString(k) .. " V = " .. tostring(v)) end
	for k, v in pairs(str) do print ("String : (" .. k .. ") " .. gpg.SafeString(v)) end

if (#arg >= 1) then
	print("\nNow lets parse against the provided command line arguments:")
	arguments, str = gpg.ParseFlags(arg)

	for k, v in pairs(arguments) do print("K = " .. gpg.SafeString(k) .. " V = " .. tostring(v)) end
	for k, v in pairs(str) do print ("String : (" .. k .. ") " .. gpg.SafeString(v)) end
	
if table.containsKey(arguments, "?") then print ("Help was requested") end	
	
end