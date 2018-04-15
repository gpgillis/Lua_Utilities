-- Testing localization of data elements with require files directive:

local gpg = require "gpgUtilities"

local reader = require "utility"


-- There is a local g_myData variable in the utility.lua file - this is the basis of the scope test.
local g_myData = {"A", "B", "C", "D"}


print("Printing the local data table:")
for k,v in pairs(g_myData) do
	print("K = " .. k .. " V = " .. v)
end

print("Printing the reader data before initialization:")
reader.PrintMyData()

print("Loading the reader with data:")

reader.AddMyData("W", "X", "Y", "Z")

print("Printing the reader data after initialization:")
reader.PrintMyData()

print("Printing the local data:")
for k,v in pairs(g_myData) do
	print("K = " .. k .. " V = " .. v)
end


print("Clearing the reader data:")
--reader.ClearMyData()
reader.AddMyData()

print("Printing the reader data after clearing:")
reader.PrintMyData()

print("Initialize reader data with local data:")
reader.AddMyData(g_myData)

print("Printing the reader data after initialization:")
reader.PrintMyData()

print("The end... ")




