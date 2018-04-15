local lfs = require "lfs"

local sourceDir = "c:/save/abtestdata/201305031517"
-- should be "/" for Unix platforms (Linux and Mac)
local DIR_SEP="/" 


function BrowseFolder(root)
	for entity in lfs.dir(root) do
		print (entity)
		if entity~="." and entity~=".." then
			local fullPath=root..DIR_SEP..entity
			--print("root: "..root..", entity: "..entity..", mode: "..(lfs.attributes(fullPath,"mode")or "-")..", full path: "..fullPath)
			local mode=lfs.attributes(fullPath,"mode")
			if mode=="file" then
				--this is where the processing happens. I print the name of the file and its path but it can be any code
				print(root.." > "..entity)
			elseif mode=="directory" then
				BrowseFolder(fullPath);
			end
		end
	end
end

function attrdir (path)
		path = string.gsub(path, "/", "\\")	-- convert to DOS style directory paths
    for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." then
            local f = path..'/'..file
            print ("\t "..f)
            local attr = lfs.attributes (f)
            assert (type(attr) == "table")
            if attr.mode == "directory" then
                attrdir (f)
            else
                for name, value in pairs(attr) do
                    print (name, value)
                end
            end
        end
    end
end



root = string.gsub(sourceDir, "/", "\\")	-- convert to DOS style directory paths
print(root)
local newDir = root .. DIR_SEP .. "BOBBLER"
print ("New DIR = " .. newDir)
local ok, err = lfs.mkdir(root .. DIR_SEP .. "BOBBLER")
if (ok == nil) then print("ERROR : " .. err) end
print ("The Current DIR = " .. lfs.currentdir())

--this is a sample call
BrowseFolder(sourceDir)


--attrdir (sourceDir)