-- MyFormatter - a test of specifying a formatter

local formatter = require "XMLFormatter"
local string = string
local os = os
local tostring = tostring

local modName = ...
print("Loading " .. modName)
module(modName)

local fmt = [[
	<Location_Data>
		<location_code>%s</location_code>
		<tax_type>%s</tax_type>
		<zipcode>%s</zipcode>
		<description>%s, %s</description>
	</Location_Data>]]

function InitializeFormatter(scriptName, unitTesting)
	local systemDate = (unitTesting) and "SYSTEM-DATE" or tostring(os.date("%c")) 	-- We dummy the system date for unit testing
	formatter.SetNodeFormat(fmt, not(unitTesting))
	local comments = {"This is the first comment", "This is the second comment", string.format("Created by %s on %s", scriptName, systemDate) }
	formatter.InitializeBuffer("RootNode", comments)
end

function AddData(...)
	formatter.AddNode(...)
end

-------------------------------------------------------------------------------
--	Adds an error node to the buffer.
function AddError(message)
	formatter.AddError(message)
end

function FinalizeBuffer()
	return formatter.FinalizeBuffer()
end
