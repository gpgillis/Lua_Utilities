-------------------------------------------------------------------------------
-- Generic Tax Exmption Code Map Formatter
-- Formats generic tax exemption to state code usage map.
--
-- GPG 20130201

require "gpgSTEConfig"
local gpg = require "gpgUtilities"
local formatter = require "TextFormatter"
local STE_CURRENT_VERSION = STE_CURRENT_VERSION
local string = string
local os = os
local tostring = tostring

local modName = ...
print("Loading " .. modName)
module(modName)

local fmt = [[
	{"%s", new List<string> { %s } },]]

-------------------------------------------------------------------------------
-- Initialize the formatter.
function InitializeFormatter(scriptName, unitTesting)
	local systemDate = (unitTesting) and "SYSTEM-DATE" or tostring(os.date("%c")) 	-- We dummy the system date for unit testing.
	local steVer = (unitTesting) and "STE-VERSION" or STE_CURRENT_VERSION						-- We dummy the STE version for unit testing.
	formatter.SetNodeFormat(fmt, not(unitTesting))
	local comments = {"Generic tax code to applicable state code map", "Changes to this code should only be done via the generator.", string.format("Code created by %s for STE version %s on %s", scriptName, steVer, systemDate) }
	formatter.InitializeBuffer("Generated genericTaxExemptionUseMap", comments)
	formatter.AddPreparedNode("private readonly static Dictionary<string, List<string>> genericTaxExemptionUseMap = new Dictionary<string, List<string>>")
	formatter.AddPreparedNode("{")
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
	formatter.AddPreparedNode("};")
	return formatter.FinalizeBuffer()
end

