-------------------------------------------------------------------------------
-- gpg Argument Processor : 
-- A command line argument processor and formatter utility
--
-- Author: GPG - 20150702
-- Based on previous argument processor work - this collects this work into a 
-- single utility and provides assistance in making using command line processing
-- easier.
--
--	There is an accompanying unit test file for this module called 'test_gpgArgumentProcessor.lua'
--	that can provide a number of usage examples for this module.
--
--
--[[
The argument process is generally run using a configure and run method set:

Example:

-------------------------------------------------------------------------------
-- ConfigureArgumentProcessor
--
local function ConfigureArgumentProcessor()
	argproc.SetScriptName("MinimumWageUpdate")
	argproc.SetInstructions(intructions)
	
	local function dateStringValidator(a)
		if (gpg.ValidateDateString(a, gpg.DateStringMatchExpression)) then return true, "" end

		return false, a .. " is not in the correct format of YYYYMMDD."
	end
	
	local function lastKeyValidator(a)
		if (a < 1) then return false, "The last key value must be greater than 1." end

		return true, ""
	end

	local flagSpecs = {}

	flagSpecs.datestring = argprog.BuildFlagSpecRecord("d", "datestring", "The date string for the update.", dateStringValidator, true)
	flagSpecs.lastkey = argproc.BuildFlagSpecRecord("k", "last_key", "The last key value the last row in the minimum wage table.", lastKeyValidator, true)
	flagSpecs.debug = argproc.BuildFlagSpecRecord("dbg", "", "Enables display of debugging messages.")

	argproc.SetFlagSpecs(flagSpecs, nil, {datestring, lastkey}

end	-- ConfigureArgumentProcessor

-------------------------------------------------------------------------------
-- RunArgumentProcessor
--
function RunArgumentProcessor(...)
	ConfigureArgumentProcessor()
	local rtn, strs = argproc.ProcessArguments(...)

	if (rtn.success) then
		if (rtn.debug) then
			print("DEBUG SETTING ON")
			gpg.SetShowDebugMessages(true) 
		end
	else
		if (rtn.error) then print (rtn.error) end
		if (rtn.help) then print(rtn.help) end
	end

	return rtn
end	-- RunArgumentProcessor

]]
-------------------------------------------------------------------------------

local modname = ... 
local M = {}

M.private = {}	-- private variables for unit testing.

_G[modname] = M
package.loaded[modname] = M
setmetatable(M, {__index = _G})
setfenv(1, M)

local inspect = require("inspect")

-- Meta information
-- _VERSION = modname .. " 1.0.0"

local gpg = require "gpgUtilities"
gpg.SetShowDebugMessages(false)

local reservedFlagNames = {"success", "error", "help", "flagOrder", "flagCount"}

local zeroFlagCountCallsHelp = true

-------------------------------------------------------------------------------
local l_instructions = ""
function SetInstructions(instructions) l_instructions = instructions end

-------------------------------------------------------------------------------
local l_scriptName = ""
function SetScriptName(name) 
	assert(not(gpg.StringIsNilOrEmpty(name)), "The script name must be defined.")
	l_scriptName = name 
end

-------------------------------------------------------------------------------
-- SetFlagSpecs
--	Initializes the argument processor with flag specifications, success validator
--	flag order and help on zero flags indicator.
--
--	Arguments
--		spec								:	A table containing the flag specification records.
--		successValidator		:	A function that is used to indicate success.
--		flagOrderRecord			:	A table containing the keys from spec defining the order 
--													the flags are to be displayed in help.
--		helpOnZeroFlagCount	:	A value inidicating that help is to be called when no flags
--													are found in the arguments.  Default is true.
--
--	Returns
--		The completed flag specification record.
--
local l_flagSpec = nil
function SetFlagSpecs(spec, successValidator, flagOrderRecord, helpOnZeroFlagCount)
	assert(spec ~= nil and type(spec) == "table", "The flag specifications must be defined in a table.")
	assert(successValidator == nil or type(successValidator) == "function", "The success validator must be a function.")
	assert(flagOrderRecord == nil or type(flagOrderRecord) == "table", "The flag order record must be a table.")

	-- GPG : Consider adding in validation to prevent reservedFlagNames from being specified.

	l_flagSpec = spec
	if (successValidator) then l_flagSpec.success = { flag = "success", data = successValidator } end
	if (flagOrderRecord) then l_flagSpec.flagOrder = { flag = "flagOrder", data = flagOrderRecord } end
	gpg.DebugMessage("SETFLAGSPECS : \n" .. inspect(l_flagSpec))
	if (helpOnZeroFlagCount ~= nil) then zeroFlagCountCallsHelp = helpOnZeroFlagCount end

	return l_flagSpec
end

-------------------------------------------------------------------------------
-- Reset
--	Resets the processor by clearing out local properties.
--
function Reset()
	l_instructions = nil
	l_scriptName = nil
	l_flagSpec = nil
end		-- Reset

-------------------------------------------------------------------------------
-- SetShowDebugMessages
--	Sets the show debug messages flag value.
--
function SetShowDebugMessages(show)
	gpg.SetShowDebugMessages(show)
end		-- SetShowDebugMessages

-------------------------------------------------------------------------------
-- ParseFlags
--		Used to parse out argument flags, generally from a command line.
--
-- Arguments:
--	A variable argument list is used  Arguments can either be a set of 
--	comma separated values, or a table.
--	If a table is used, there can only be a single table in the argument list.
--
--	Returns:
--		Flags table		:	A table with the flag as the key and either the flag set value or boolean true.
--		Strings table	:	A table with any plain strings parsed from the arguments list.
--		Flags count		:	The number of flags parsed.

--		NOTE: If a standard command line arguments table is passed to this function, the Strings table
--					returned will also contain values normally found in the command line arguments table, ie
--					key 0 contains the script name, key -1 contains the interpreter command.
--
-- Example:
-- 		ParseFlags("foo", "--tux=beep", "--bla", "bar", "--baz")
-- would return:
--		Flags table: {["bla"] = true, ["tux"] = "beep", ["baz"] = true}, 
--		Strings table:	{"foo", "bar"}
--		Count : 3
--
function ParseFlags(...)
	local strgs = {...}
	local flags = {}
	local flagsCount = 0

	if (#strgs == 1 and type(strgs[1]) == "table") then strgs = strgs[1] end

	for i = #strgs, 1, -1 do
		assert(type(strgs[i]) ~= "table", "You cannot include a table in a multiple argument parse request.")
		local flag = strgs[i]:match("^%-%-(.*)")
		if flag then
			flagsCount = flagsCount + 1
			local var,val = flag:match("([a-z0-9_%-]*)=(.*)")
			if val then flags[var] = val else flags[flag] = true end
			table.remove(strgs, i)
		end
	end

	return flags, strgs, flagsCount
end	-- ParseFlags

-------------------------------------------------------------------------------
-- CalculateMaxFlagLength
--	Returns the maximum length of the flags in the specification collection.
--
local function CalculateMaxFlagLength(flagSpec)
	assert(flagSpec ~= nil and type(flagSpec) == "table", "The flag specification collection must be table.")
	local flags = {}
	for k,v in pairs(flagSpec) do
		if (not(table.containsValue(reservedFlagNames, flagSpec[k].flag))) then -- Only process actual command line flags.
			table.insert(flags, flagSpec[k].flag) 
		end
	end
	return gpg.CalculateMaxStringLength(flags)
end	-- CalculateMaxFlagLength

-------------------------------------------------------------------------------
-- GenerateProcessArgumentsHelp
--	Generates a help screen based on the flags and instructions provided.
--
local function GenerateProcessArgumentsHelp(flagSpec, scriptName, instructions)
	assert(flagSpec ~= nil and type(flagSpec) == "table", "The flag specification collection must be table.")
	assert(not(gpg.StringIsNilOrEmpty(scriptName)), "The script name must be defined.")

	gpg.DebugMessage("GenerateProcessArgumentsHelp:\n" .. inspect(flagSpec))

	local instruct = (not(gpg.StringIsNilOrEmpty(instructions))) and ("\n" .. instructions .. "\n") or ""
	local usage = "Usage : " .. scriptName .. ".lua "
	local flagDescriptions = "\nFlags:\n"

	keys = table.Keys(flagSpec)
	if (table.containsKey(flagSpec, "flagOrder")) then
		local order = flagSpec.flagOrder.data
		assert(order ~= nil and type(order) == "table" and #order > 0, "The flag order must be a table populated with the flag spec keys as strings.")
		keys = order
	end

	gpg.DebugMessage("GenerateProcessArgumentsHelp - flagSpec keys:\n" .. inspect(keys))

	local maxFlagLength = CalculateMaxFlagLength(flagSpec)

	for _,k in pairs(keys) do
		local v = flagSpec[k]
		if (v ~= nil and not(table.containsValue(reservedFlagNames, v.flag))) then	-- Only process actual command line flags.
			local f = "--" .. v.flag
			if (type(v.default) ~= "boolean" and not(gpg.StringIsNilOrEmpty(v.description))) then f = f .. "=" .. v.description end
			if (not(v.required)) then f = "[" .. f .. "]" end
			usage = usage .. f .. " "
			flagDescriptions = flagDescriptions .. string.format("\t--%s%s : %s%s\n", v.flag, string.rep(" ", maxFlagLength - string.len(v.flag)), v.comment, (v.required and "" or " (OPTIONAL)"))
		end
	end
	usage = string.gsub(usage, "%s$", "")

	return instruct .. usage .. flagDescriptions

end	-- GenerateProcessArgumentsHelp

-------------------------------------------------------------------------------
-- ProcessArguments
--	Process supplied arguments based on flag specifications and validation 
-- 	rules.
--
--	Returns a table containing the parsed and processing data.
--	If there are errors, the returned table will have an error node containing an error message.
--	If help is requested, the returned table will have a help node containing the help text.
-- 	If processing has completed successfully, the returned table will contain a success node with a true value.
--
function ProcessArguments(...)
	gpg.DebugMessage("Processing Arguments ... ")
	assert(l_flagSpec ~= nil and type(l_flagSpec) == "table", "The flag specification collection must be defined with SetFlagSpecs before calling ProcessArguments.")
	assert(not(gpg.StringIsNilOrEmpty(l_scriptName)), "The script name must be defined with SetScriptName before calling ProcessArguments.")

	local pac = {}	-- Initialize the processed arguments collection (pac) - this is the returned data.
	pac.success = false

	-- Field specification setup: Process flag specifications and populate spec, validation, and required collections.
	local specFlags = {}
	local successValidators = {}
	local validators = {}
	local requiredFlags = {}

	for k,v in pairs(l_flagSpec) do
		if (k == "success") then
			assert(v.data and type(v.data) == "function", "If a success key is defined, the success validator function must also be defined.")
			table.insert(successValidators, v.data)
		elseif (k == flagOrder) then -- NO-OP
		else
			assert(table.containsKey(v, "flag"), "The flag specification " .. k .. "  must contain a flag value")
			if (not(table.containsKey(v, "default"))) then v.default = nil end
			specFlags[k] = v
			if (table.containsKey(v, "validator")) then validators[k] = v.validator end
			if (v.required) then table.insert(requiredFlags, k) end
		end
	end

	-- Required Validator Generation: If there are required flags, we need to generate a validator to test for their presence in the pac.
	gpg.DebugMessage("Required Flags:\n " .. inspect(requiredFlags))
	if (#requiredFlags > 0) then
		local validateRequiredFlags = function (a)
			gpg.DebugMessage("A: \n" .. inspect(a))
			for _,k in pairs(requiredFlags) do
				if (not(table.containsKey(a, k))) then return false, "Flag --" .. l_flagSpec[k].flag .. " is required." end 
			end
			return true, ""
		end
		table.insert(successValidators, validateRequiredFlags)
	end

	-- Parse: Parse the command line arguments.
	local flags, strs, flagsCount = ParseFlags(...)
	pac.flagsCount = flagsCount
	
	-- Help Request: If help has been requested, generate help and instruction text, save to pac and return.
	if (table.containsKey(flags, "?") or table.containsValue(strs, "help") or (flagsCount == 0 and zeroFlagCountCallsHelp)) then
		pac.help = GenerateProcessArgumentsHelp(l_flagSpec, l_scriptName, l_instructions)
		return pac, strs
	end

	-- Process:  Process the command line flag arguments against the flag specs.
	for k,v in pairs(specFlags) do
		if (table.containsKey(flags, v.flag)) then 
			pac[k] = flags[v.flag]
		elseif (v.required == false and v.default ~= nil) then 
			pac[k] = v.default 
		else
			-- NO-OP
		end
	end

	-- Success Validation:  We first process any success validators to insure we have all required flags.
	for _,v in pairs(successValidators) do
		local errMsg = ""
		pac.success, errMsg = v(pac)
		if (not(pac.success)) then
			pac.error = errMsg
			break 
		end
	end

	local errorMessageFormat = "ERROR:\tThe value for --%s is invalid - %s\n\t%s"
	-- Flag Specific Validation: If the success validators pass, we process any flag specific validators.
	if (pac.success) then
		for k,v in pairs(validators) do
			local errMsg = ""
			if (table.containsKey(pac, k)) then
				pac.success, errMsg = v(pac[k])
				if (not(pac.success)) then
					pac.error = string.format(errorMessageFormat, l_flagSpec[k].flag, errMsg, l_flagSpec[k].comment) -- "ERROR:\tThe value for --" .. l_flagSpec[k].flag .. " is invalid - " .. errMsg .. "\n\t" .. l_flagSpec[k].comment 
					break
				end
			end
		end
	end

	return pac, strs
end	-- ProcessArguments

-------------------------------------------------------------------------------
-- BuildFlagSpecRecord
--	Creates and returns a flag specification record for use with ProcessArguments.
--
--	Arguments:
--		flag				:	The flag character or text.  The "--" prepend will be added to make the flag active for parsing.
--		description	:	The flag description - used in command instructions generation flag use examples (--flag=description)
--		comment			:	A comment on the flag meaning - used in command instructions.
--		validator		:	A function used to validate the flag - the function should take a single argument (the flag value) 
--									and returns true if the flag value is valid.	(optional - defaults nil)
--		required		:	Set true if the flag is required - missing a required flag indicates an error. (optional - defaults false)
--		default			:	The default value of the flag - required flags cannot have a default value. (optional - defaults nil)
--
function BuildFlagSpecRecord(flag, description, comment, validator, required, default)
	assert(not(gpg.StringIsNilOrEmpty(flag)), "The flag argument is required.")
	assert(description ~= nil, "The description argument is required.")
	assert(not(gpg.StringIsNilOrEmpty(comment)), "The comment argument is required.")
	assert(validator == nil or type(validator) == "function", "The validator must either be nil or a function.")
	assert(required == nil or type(required) == "boolean", "The required argument must either be nil or a boolean value.")

	if (required == nil) then required = false end

	local record = {}
	record.flag = flag
	record.description = description
	record.comment = comment
	record.required = required
	if (default ~= nil) then record.default = default end
	if (validator ~= nil) then record.validator = validator end
	
	if(record.required and record.default ~= nil) then error("A required flag cannot have a default value.") end

	return record
end	-- BuildFlagSpecRecord


