-- MySillyFormatter - more formatting tests and examples with a silly bent.

local formatter = require "XmlFormatter"

local string = string
local os = os
local tostring = tostring

local modName = ...
print("Loading " .. modName)
module(modName)


-------------------------------------------------------------------------------
-- Initialize the formatter.
function InitializeFormatter(scriptName, unitTesting)
	formatter.SetNodeFormat([[
		<Bob_Data>
			<location_location>%s</location_location>
			<tax_type>%s</tax_type>
			<zippyDoDa>%s</zippyDoDa>
			<description>%s, %s</description>
		</Bob_Data>]], not(unitTesting))
	local systemDate = (unitTesting) and "SYSTEM-DATE" or tostring(os.date("%c")) 	-- We dummy the system date for unit testing
	local comments = {"Silly as this is.", "This is my other formatter.", string.format("Created by %s on %s", scriptName, systemDate) }
	formatter.InitializeBuffer("RootyTootTootNode", comments)
end

-------------------------------------------------------------------------------
-- Format data and add to the buffer. 
function AddData(...)
	formatter.AddNode(...)
end

-------------------------------------------------------------------------------
--	Adds an error node to the buffer.
function AddError(message)
	formatter.AddError(message)
end

-------------------------------------------------------------------------------
--	Finalizes and returns the formatted data buffer.
function FinalizeBuffer()
	return formatter.FinalizeBuffer()
end

