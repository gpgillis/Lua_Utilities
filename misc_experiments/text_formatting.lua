-------------------------------------------------------------------------------
-- This is a experiment in text formatting - mainly for command line help 
-- processes.


local gpg = require("gpgUtilities")


local title = {"ThisScriptName"}
local desc = {
"ThisScriptName", 
"This is a short description"
}


local seventyFourChar = "12345678901234567890123456789012345678901234567890123456789012345678901234"
local eightyChar = "12345678901234567890123456789012345678901234567890123456789012345678901234567890"

print(gpg.FormatTitle(title))
print(gpg.FormatTitle(desc))
print(gpg.FormatTitle({seventyFourChar, seventyFourChar}))
print(gpg.FormatTitle({eightyChar, eightyChar}, 90))

print(gpg.FormatTitle({seventyFourChar, eightyChar, seventyFourChar, eightyChar}, 90))


local f1 = "f1"
local f2 = "flag2"
local f3 = "myFlag3"
local f4 = "myLongFlag4"
local flags = { f1, f2, f3, f4 }


local h1 = "This is header line 1"
local h2 = "This is header line 2 - another line"
local h3 = "This is header line three"
local h4 = "This is just another header line - 4"
local heads = { h1, h2, h3, h4 }


local name = arg[0]
local title1 = "This is my script title"
local title2 = "This is a longer script title."





print("flag count = " .. #flags)

for i = 1, #flags do
	print ("The flag is --" .. flags[i] .. " : " .. heads[i])
end

local mlFlags = gpg.CalculateMaxStringLength(flags)

print ("mL for flags = " .. mlFlags)


for i = 1, #flags do
	print ("The flag is --" .. flags[i] ..string.rep(" ", mlFlags - string.len(flags[i])) .. " : " .. heads[i])
end


