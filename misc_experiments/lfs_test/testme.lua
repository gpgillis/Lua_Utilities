require "lfs"

---[[
print ("Testing the lmd.dll res version")
local vers = lfs.res_version("lmd5.dll")
if (vers == nil) then vers = "n/a" end
print(vers)

print ("Testing the lfs.dll res version")
vers = lfs.res_version("lfs.dll")
if (vers == nil) then vers = "n/a" end
print(vers)
-- ]]

print("Testing the lmd5 attributes")
local attrib = lfs.attributes("lmd5.dll")
if (attrib ~= nil) then
	for k,v in pairs(attrib) do
		print(k .. " : " .. v)
	end
end