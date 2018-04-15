-------------------------------------------------------------------------------
-- Unit Tests for gpg Argument Processor
-- 
-- GPG - 20150703
-------------------------------------------------------------------------------

local argproc = require("gpgArgumentProcessor")
local luaunit = require("LuaUnit")
local inspect = require("inspect")
local gpg = require("gpgUtilities")

local scriptName = "Test_gpgArgumentProcessor"

-------------------------------------------------------------------------------
-- Parse Flags Functions Tests:
TestParseFlagsFunctions = {}
	function TestParseFlagsFunctions:setUp()
		argproc.SetShowDebugMessages(false)
	end
		----------------------------------------
	function TestParseFlagsFunctions:testParseFlagsWithTableArgument()
		local flags =  {["baz"] = true, ["f1"]="Function1", ["bla"] = true, ["tux"] = "beep"}
		local strgs = {"foo", "bar"}
		local count = 4
		local argsTbl = {"foo", "--tux=beep", "--bla", "bar", "--baz", "--f1=Function1"}
		
		local rflags, rstrgs, rcount = argproc.ParseFlags(argsTbl)

		luaunit.assertIsTable(rflags)
		luaunit.assertEquals(rflags, flags)

		luaunit.assertIsTable(rstrgs)
		luaunit.assertEquals(rstrgs, strgs)
		
		luaunit.assertIsNumber(rcount)
		luaunit.assertEquals(rcount, count)
	end
	----------------------------------------
	function TestParseFlagsFunctions:testParseFlagsWithMultipleArguments()
		local flags =  {["baz"] = true, ["f1"]="Function1", ["bla"] = true, ["tux"] = "beep"}
		local strgs = {"foo", "bar"}
		local count = 4

		local rflags, rstrgs, rcount = argproc.ParseFlags("foo", "--tux=beep", "--bla", "bar", "--baz", "--f1=Function1")

		luaunit.assertIsTable(rflags)
		luaunit.assertEquals(rflags, flags)

		luaunit.assertIsTable(rstrgs)
		luaunit.assertEquals(rstrgs, strgs)

		luaunit.assertIsNumber(rcount)
		luaunit.assertEquals(rcount, count)
	end
	----------------------------------------
	function TestParseFlagsFunctions:testParseFlagsWithEmptyArguments()
		local f, s, c = argproc.ParseFlags()	-- no arguments
		luaunit.assertEquals({}, f)
		luaunit.assertEquals({}, s)
		luaunit.assertEquals(c, 0)

		f, s, c = argproc.ParseFlags({})	-- empty table argument
		luaunit.assertEquals({}, f)
		luaunit.assertEquals({}, s)
		luaunit.assertEquals(c, 0)
	end
	----------------------------------------
	function TestParseFlagsFunctions:testParseFlagsWithInvalidArguments()
		local flags =  {["bla"] = true, ["tux"] = "beep", ["baz"] = true}
		local strgs = {"foo", "bar"}
		local count = 3
		luaunit.assertError(argproc.ParseFlags, flag, strgs)
	end

-------------------------------------------------------------------------------
-- Build Flag Spec Record Functions Tests:
-- function BuildFlagSpecRecord(flag, name, comment, default, validator, required)
TestBuildFlagSpecRecordFunctions = {}
	function TestBuildFlagSpecRecordFunctions:setUp()
		argproc.SetShowDebugMessages(false)
	end
		----------------------------------------
	function TestBuildFlagSpecRecordFunctions:testMissingFlagFailure()
	local expectedErrMsg = "The flag argument is required."
		local function validate(a) return a > 0 end
		luaunit.assertErrorMsgContains(expectedErrMsg, argproc.BuildFlagSpecRecord, nil)
	end
	----------------------------------------
	function TestBuildFlagSpecRecordFunctions:testMissingDescriptionFailure()
		local expectedErrMsg = "The description argument is required."
		luaunit.assertErrorMsgContains(expectedErrMsg, argproc.BuildFlagSpecRecord, "f1")
	end
	----------------------------------------
	function TestBuildFlagSpecRecordFunctions:testMissingCommentFailure()
		local expectedErrMsg = "The comment argument is required."
		luaunit.assertErrorMsgContains(expectedErrMsg, argproc.BuildFlagSpecRecord, "f1", "flag1")
	end
	----------------------------------------
	function TestBuildFlagSpecRecordFunctions:testInvalidValidatorFailure()
		local expectedErrMsg = "The validator must either be nil or a function."
		luaunit.assertErrorMsgContains(expectedErrMsg, argproc.BuildFlagSpecRecord, "f1", "flag1", "First Flag", "BROKEN")
	end
	----------------------------------------
	function TestBuildFlagSpecRecordFunctions:testInvalidRequiredFailure()
		local function validate(a) return a > 0 end
		local expectedErrMsg = "The required argument must either be nil or a boolean value."
		luaunit.assertErrorMsgContains(expectedErrMsg, argproc.BuildFlagSpecRecord, "f1", "flag1", "First Flag", nil, "BROKEN")
	end
	----------------------------------------
	function TestBuildFlagSpecRecordFunctions:testRequiredRecordWithDefaultFailure()
		local expectedErrMsg = "A required flag cannot have a default value."
		luaunit.assertErrorMsgContains(expectedErrMsg, argproc.BuildFlagSpecRecord, "f1", "flag1", "This is the first flag", nil, true, "BOB")
	end
	----------------------------------------
	function TestBuildFlagSpecRecordFunctions:testSimpleRecordBuildup()
		local spec = argproc.BuildFlagSpecRecord("f1", "flag1", "This is the first flag")
		luaunit.assertIsTable(spec)
		luaunit.assertEquals(spec.flag, "f1")
		luaunit.assertEquals(spec.description, "flag1")
		luaunit.assertEquals(spec.comment, "This is the first flag")	-- Missing args should be defaulted correctly.
		luaunit.assertNil(spec.default)
		luaunit.assertNil(spec.validator)
		luaunit.assertFalse(spec.required)
	end
	----------------------------------------
	function TestBuildFlagSpecRecordFunctions:testSimpleRecordBuildupBooleanFlag()
		local spec = argproc.BuildFlagSpecRecord("f1", "", "This is the first flag")
		luaunit.assertIsTable(spec)
		luaunit.assertEquals(spec.flag, "f1")
		luaunit.assertEquals(spec.description, "")
		luaunit.assertEquals(spec.comment, "This is the first flag")	-- Missing args should be defaulted correctly.
		luaunit.assertNil(spec.default)
		luaunit.assertNil(spec.validator)
		luaunit.assertFalse(spec.required)
	end
	----------------------------------------
	function TestBuildFlagSpecRecordFunctions:testFullRequiredRecordBuildup()
		local function validate(a) return a > 0 end
		local spec = argproc.BuildFlagSpecRecord("f1", "flag1", "This is the first flag", validate, true)
		luaunit.assertIsTable(spec)
		luaunit.assertEquals(spec.flag, "f1")
		luaunit.assertEquals(spec.description, "flag1")
		luaunit.assertEquals(spec.comment, "This is the first flag")
		luaunit.assertIsNil(spec.default)
		luaunit.assertIs(spec.validator, validate)
		luaunit.assertTrue(spec.required)
	end
	----------------------------------------
	function TestBuildFlagSpecRecordFunctions:testFullDefaultedValueRecordBuildup()
		local function validate(a) return a > 0 end
		local spec = argproc.BuildFlagSpecRecord("f1", "flag1", "This is the first flag", validate, false, "FIRST")
		luaunit.assertIsTable(spec)
		luaunit.assertEquals(spec.flag, "f1")
		luaunit.assertEquals(spec.description, "flag1")
		luaunit.assertEquals(spec.comment, "This is the first flag")
		luaunit.assertEquals(spec.default, "FIRST")
		luaunit.assertIs(spec.validator, validate)
		luaunit.assertFalse(spec.required)
	end


	-------------------------------------------------------------------------------
-- SetFlagSpecs Tests:
-- function SetFlagSpecs(spec, successValidator, tableOrderRecord)
TestSetFlagSpecsFunction = {}
	function TestSetFlagSpecsFunction:setUp()
		argproc.Reset()
		argproc.SetShowDebugMessages(false)
	end
	----------------------------------------
	function TestSetFlagSpecsFunction:testInvalidFlagSpecSettingFailure()
		local expectedErrMsg = "The flag specifications must be defined in a table."
		local spec = {}
		luaunit.assertErrorMsgContains(expectedErrMsg, argproc.SetFlagSpecs, specs)
	end
	----------------------------------------
	function TestSetFlagSpecsFunction:testSetFlagSpegpgnvalidSuccessValidatorFailure()
		local expectedErrMsg = "The success validator must be a function."
		local spec = {}
		spec.firstFlag = argproc.BuildFlagSpecRecord("f1", "flag1", "This is the first flag - it is a required flag.", nil, true)
		spec.secondFlag = argproc.BuildFlagSpecRecord("f2", "flag2", "This is the second flag - it is a defaulted flag.", nil, false, "MasDefaultas")
		spec.thirdFlag = argproc.BuildFlagSpecRecord("f3", "", "This is the third flag - it is a defaulted flag.", nil, true)
		luaunit.assertErrorMsgContains(expectedErrMsg, argproc.SetFlagSpecs, spec, "BOKEN")
	end
	----------------------------------------
	function TestSetFlagSpecsFunction:testSetFlagSpegpgnvalidFlagOrderRecordFailure()
		local expectedErrMsg = "The flag order record must be a table."
		local spec = {}
		spec.firstFlag = argproc.BuildFlagSpecRecord("f1", "flag1", "This is the first flag - it is a required flag.", nil, true)
		spec.secondFlag = argproc.BuildFlagSpecRecord("f2", "flag2", "This is the second flag - it is a defaulted flag.", nil, false, "MasDefaultas")
		spec.thirdFlag = argproc.BuildFlagSpecRecord("f3", "", "This is the third flag - it is a defaulted flag.", nil, true)
		luaunit.assertErrorMsgContains(expectedErrMsg, argproc.SetFlagSpecs, spec, nil, "BOKEN")
	end
	----------------------------------------
	function TestSetFlagSpecsFunction:testSetFlagSpecsFlagSpecOnly()
		local spec = {}
		spec.firstFlag = argproc.BuildFlagSpecRecord("f1", "flag1", "This is the first flag - it is a required flag.", nil, true)
		spec.secondFlag = argproc.BuildFlagSpecRecord("f2", "flag2", "This is the second flag - it is a defaulted flag.", nil, false, "MasDefaultas")
		spec.thirdFlag = argproc.BuildFlagSpecRecord("f3", "", "This is the third flag - it is a defaulted flag.", nil, true)
		local rtn = argproc.SetFlagSpecs(spec)
		luaunit.assertIsTable(rtn)
	end
	----------------------------------------
	function TestSetFlagSpecsFunction:testSetFlagSpecsWithSuccessValidator()
		local successValidator = function(a) return a.firstFlag ~= nil end
		local spec = {}
		
		spec.firstFlag = argproc.BuildFlagSpecRecord("f1", "flag1", "This is the first flag - it is a required flag.", nil, true)
		spec.secondFlag = argproc.BuildFlagSpecRecord("f2", "flag2", "This is the second flag - it is a defaulted flag.", nil, false, "MasDefaultas")
		spec.thirdFlag = argproc.BuildFlagSpecRecord("f3", "", "This is the third flag - it is a defaulted flag.", nil, true)
		local rtn = argproc.SetFlagSpecs(spec, successValidator)
		luaunit.assertIsTable(rtn)
		luaunit.assertTrue(table.containsKey(rtn, "success"))
		luaunit.assertIs(rtn.success.data, successValidator)
	end
	----------------------------------------
	function TestSetFlagSpecsFunction:testSetFlagSpecsWithFlagOrderTable()
		local flagOrder = { "firstFlag", "secondFlag", "thirdFlag" }
		local spec = {}
		
		spec.firstFlag = argproc.BuildFlagSpecRecord("f1", "flag1", "This is the first flag - it is a required flag.", nil, true)
		spec.secondFlag = argproc.BuildFlagSpecRecord("f2", "flag2", "This is the second flag - it is a defaulted flag.", nil, false, "MasDefaultas")
		spec.thirdFlag = argproc.BuildFlagSpecRecord("f3", "", "This is the third flag - it is a defaulted flag.", nil, true)
		local rtn = argproc.SetFlagSpecs(spec, nil, flagOrder)
		luaunit.assertIsTable(rtn)
		luaunit.assertTrue(table.containsKey(rtn, "flagOrder"))
		luaunit.assertIs(rtn.flagOrder.data, flagOrder)
	end


-------------------------------------------------------------------------------
-- Process Arguments Functions Tests:
-- function BuildFlagSpecRecord(flag, name, comment, default, validator, required)
TestProcessArgumentsFunctions = {}
	function TestProcessArgumentsFunctions:setUp()
		argproc.Reset()
		argproc.SetShowDebugMessages(false)
	end
	----------------------------------------
	function TestProcessArgumentsFunctions:testReset()
		local expectedErrMsg = "The flag specification collection must be defined with SetFlagSpecs before calling ProcessArguments."
		local spec = {}
		spec.firstFlag = argproc.BuildFlagSpecRecord("f1", "flag1", "This is the first flag - it is a required flag.", nil, true)
		argproc.SetFlagSpecs(spec)
		argproc.SetScriptName(scriptName)
		argproc.Reset()
		luaunit.assertErrorMsgContains(expectedErrMsg, argproc.ProcessArguments, "--f1=BOB")
	end
	----------------------------------------
	function TestProcessArgumentsFunctions:testSuccessFlagWithNoValidatorFunctionFailure()
		local expectedErrMsg = "If a success key is defined, the success validator function must also be defined."
		local spec = {}
		spec.success = { flag = "success", data = nil}	-- This is not the normal method for setting a success validator - but used for testing.
		spec.firstFlag = argproc.BuildFlagSpecRecord("f1", "flag1", "This is the first flag - it is a required flag.", nil, true)
		spec.secondFlag = argproc.BuildFlagSpecRecord("f2", "flag2", "This is the second flag - it is a defaulted flag.", nil, false, "MasDefaultas")
		spec.thirdFlag = argproc.BuildFlagSpecRecord("f3", "", "This is the third flag - it is a defaulted flag.", nil, true)
		argproc.SetFlagSpecs(spec)
		argproc.SetScriptName(scriptName)
		luaunit.assertErrorMsgContains(expectedErrMsg, argproc.ProcessArguments, "--f=BOB")
	end
	----------------------------------------
	function TestProcessArgumentsFunctions:testProcessArgumentsWithNoScriptNameSetFailure()
		local expectedErrMsg = "The script name must be defined with SetScriptName before calling ProcessArguments."
		local spec = {}
		spec.firstFlag = argproc.BuildFlagSpecRecord("f1", "flag1", "This is the first flag - it is a required flag.", nil, true)
		spec.secondFlag = argproc.BuildFlagSpecRecord("f2", "flag2", "This is the second flag - it is a defaulted flag.", nil, false, "MasDefaultas")
		argproc.SetFlagSpecs(spec)
		luaunit.assertErrorMsgContains(expectedErrMsg, argproc.ProcessArguments, "--f1=BOB")
	end
	----------------------------------------
	function TestProcessArgumentsFunctions:testSuccessFlagDefaultSettings()	-- With no success flag and validator specified, a default success flag should be generated.
		local spec = {}
		spec.firstFlag = argproc.BuildFlagSpecRecord("f1", "flag1", "This is the first flag - it is a required flag.", nil, true)
		spec.secondFlag = argproc.BuildFlagSpecRecord("f2", "flag2", "This is the second flag - it is a defaulted flag.", nil, false, "MasDefaultas")
		spec.thirdFlag = argproc.BuildFlagSpecRecord("f3", "", "This is the third flag - it is a required flag.", nil, true)
		argproc.SetFlagSpecs(spec)
		argproc.SetScriptName(scriptName)
		local r, s = argproc.ProcessArguments({"--f1=bob", "--f2=mas", "--f3"})
		luaunit.assertTrue(r.success)
		luaunit.assertEquals(r.flagsCount, 3)
		luaunit.assertIsTable(s)
		luaunit.assertEquals(#s, 0)
	end
	----------------------------------------
	function TestProcessArgumentsFunctions:testFlagSettings()
		local spec = {}
		spec.firstFlag = argproc.BuildFlagSpecRecord("f1", "flag1", "This is the first flag - it is a required flag.", nil, true)
		spec.secondFlag = argproc.BuildFlagSpecRecord("f2", "flag2", "This is the second flag - it is a defaulted flag.", nil, false, "MasDefaultas")
		spec.thirdFlag = argproc.BuildFlagSpecRecord("f3", "", "This is the third flag - it is a required flag.", nil, true)
		spec.fourthFlag = argproc.BuildFlagSpecRecord("f4", "", "This is the fourth flag - it is a defaulted flag.", nil, false, true)
		spec.fifthFlag = argproc.BuildFlagSpecRecord("f5", "flag5", "This is the fifth flag - it is a defaulted flag.", nil, false, "DefaultValue5")
		argproc.SetFlagSpecs(spec)
		argproc.SetScriptName(scriptName)
		local r, s = argproc.ProcessArguments({"--f1=bob", "--f2=mas", "--f3"})
		luaunit.assertTrue(r.success)
		luaunit.assertEquals(r.flagsCount, 3)
		luaunit.assertIsTable(s)
		luaunit.assertEquals(#s, 0)
		luaunit.assertEquals(r.firstFlag, "bob")
		luaunit.assertEquals(r.secondFlag, "mas")
		luaunit.assertTrue(r.thirdFlag)
		luaunit.assertTrue(r.fourthFlag)
		luaunit.assertEquals(r.fifthFlag, "DefaultValue5")
	end
	----------------------------------------
	function TestProcessArgumentsFunctions:testStringsParsingFromCommandLine()
		local expectedCmdLineStrings = { "FirstString", "SecondString" }
		local spec = {}
		spec.firstFlag = argproc.BuildFlagSpecRecord("f1", "flag1", "This is the first flag - it is a required flag.", nil, true)
		spec.secondFlag = argproc.BuildFlagSpecRecord("f2", "flag2", "This is the second flag - it is a defaulted flag.", nil, false, "MasDefaultas")
		argproc.SetFlagSpecs(spec)
		argproc.SetScriptName(scriptName)
		local r, s = argproc.ProcessArguments({"--f1=bob", "FirstString", "SecondString"})
		luaunit.assertTrue(r.success)
		luaunit.assertEquals(r.flagsCount, 1)
		luaunit.assertIsTable(s)
		luaunit.assertEquals(#s, 2)
		luaunit.assertEquals(s, expectedCmdLineStrings)
	end


-------------------------------------------------------------------------------
-- Test Default Required Flags Validator Functions
TestDefaultRequiredFlagsValidatorFunctions = {}
	----------------------------------------
	function TestDefaultRequiredFlagsValidatorFunctions:setUp()
		argproc.Reset()
		argproc.SetShowDebugMessages(false)
		local spec = {}
		spec.firstFlag = argproc.BuildFlagSpecRecord("first", "", "This is the first flag - required.", nil, true)
		spec.secondFlag = argproc.BuildFlagSpecRecord("second", "", "This is the second flag - optional")
		spec.thirdFlag = argproc.BuildFlagSpecRecord("third", "", "This is the third flag - required.", nil, true)
		argproc.SetFlagSpecs(spec)
		argproc.SetScriptName(scriptName)
	end
	----------------------------------------
	function TestDefaultRequiredFlagsValidatorFunctions:testRequiredFlagsValidation()
		local r1 = argproc.ProcessArguments({"--first"})
		luaunit.assertFalse(r1.success)	-- Should fail - missing required third flag.
		local r2 = argproc.ProcessArguments({"--first", "--second"})
		luaunit.assertFalse(r2.success)	-- Should fail - missing required third flag.
		local r3 =argproc.ProcessArguments({"--first", "--second", "--third"})
		luaunit.assertTrue(r3.success)
	end

-------------------------------------------------------------------------------
-- Test Success Validator Functions
TestSuccessValidatorFunctions = {}
	----------------------------------------
	function TestSuccessValidatorFunctions:setUp()
		argproc.Reset()
		argproc.SetShowDebugMessages(false)
		local successValidator = function (a)
			if (a.thirdFlag ~= "ThirdFlag") then
				if (table.containsKey(a, "thirdFlag")) then 
					return false, "The value for the --third flag should be 'ThirdFlag'."
				else
					return false, "The --third flag is required and must contain a value."
				end
			end
			return true, ""
		end
		
		local spec = {}
		spec.firstFlag = argproc.BuildFlagSpecRecord("first", "", "This is the first flag - required.", nil, true)
		spec.secondFlag = argproc.BuildFlagSpecRecord("second", "flag2", "This is the second flag - optional")
		spec.thirdFlag = argproc.BuildFlagSpecRecord("third", "flag3", "This is the third flag - optional but success validated.")
		spec.forthFlag = argproc.BuildFlagSpecRecord("fourth", "flag4", "This is the forth flag - optional but validated.")
		argproc.SetFlagSpecs(spec, successValidator)
		argproc.SetScriptName(scriptName)
	end
	----------------------------------------
	function TestSuccessValidatorFunctions:testRequiredFieldsValidation()
		local r1, s1 = argproc.ProcessArguments({"--first"})
		luaunit.assertFalse(r1.success)	-- Should fail - no third flag as required by validator function.
		luaunit.assertEquals(r1.flagsCount, 1)
		luaunit.assertIsTable(s1)
		luaunit.assertEquals(#s1, 0)
		luaunit.assertEquals(r1.error, "The --third flag is required and must contain a value.")
		local r2, s2 = argproc.ProcessArguments({"--first", "--third=BOB"})
		luaunit.assertFalse(r2.success)	-- Should fail - third flag is set but has an incorrect value.
		luaunit.assertEquals(r2.flagsCount, 2)
		luaunit.assertIsTable(s2)
		luaunit.assertEquals(#s2, 0)
		luaunit.assertEquals(r2.error, "The value for the --third flag should be 'ThirdFlag'.")
		local r3, s3 = argproc.ProcessArguments({"--first", "--third=ThirdFlag"})
		luaunit.assertTrue(r3.success)
		luaunit.assertEquals(r3.flagsCount, 2)
		luaunit.assertIsTable(s3)
		luaunit.assertEquals(#s3, 0)
		luaunit.assertTrue(r3.firstFlag)
		luaunit.assertEquals(r3.thirdFlag, "ThirdFlag")
	end


-------------------------------------------------------------------------------
-- Test Flag Validator Functions
TestFlagValidatorFunctions = {}
	----------------------------------------
	function TestFlagValidatorFunctions:setUp()
		argproc.Reset()
		argproc.SetShowDebugMessages(false)
		
		local numbericFlagValidator = function (a) 
			if (tonumber(a) > 0) then
				return true, ""
			else
				return false, "The flag value must be greater than zero."
			end
		end
		
		local alphaFlagValidator = function (a) 
			if (a == "BOB") then
				return true, ""
			else
				return false, "The flag value must be 'BOB'."
			end
		end

		local steDateValidator = function (a) 
			if (gpg.ValidateDateString(a, gpg.SteDateStringMatchExpression)) then
				return true, ""
			else
				return false, a .. " is not in the correct format of YYYY-MM-DD."
			end
		end

		local spec = {}
		spec.rqd = argproc.BuildFlagSpecRecord("rqd", "requiredFlag", "This is the required flag - required.", nil, true)
		spec.num = argproc.BuildFlagSpecRecord("num", "numbericFlag", "This is the numberic flag - optional but numberic validated.", numbericFlagValidator)
		spec.alf = argproc.BuildFlagSpecRecord("alf", "alphaFlag", "This is the alpha flag - optional but alpha validated.", alphaFlagValidator)
		spec.dte = argproc.BuildFlagSpecRecord("dte", "dateFlag", "This is the datestring flag - optional but datestring validated.", steDateValidator)
		argproc.SetFlagSpecs(spec)
		argproc.SetScriptName(scriptName)
	end
	----------------------------------------
	function TestFlagValidatorFunctions:testRequiredFlagsValidationOnlyRequiredFlagSetSucceeds()
		local r, s = argproc.ProcessArguments({"--rqd"})
		luaunit.assertTrue(r.success)
		luaunit.assertEquals(r.flagsCount, 1)
		luaunit.assertIsTable(s)
		luaunit.assertEquals(#s, 0)

	end
	----------------------------------------
	function TestFlagValidatorFunctions:testRequiredFlagsValidationNumbericFlagFails()
		local expectedErrMsg = "ERROR:\tThe value for --num is invalid - The flag value must be greater than zero.\n\tThis is the numberic flag - optional but numberic validated."
		local r, s = argproc.ProcessArguments({"--rqd", "--num=0"})
		luaunit.assertFalse(r.success)
		luaunit.assertEquals(r.flagsCount, 2)
		luaunit.assertIsTable(s)
		luaunit.assertEquals(#s, 0)
		luaunit.assertEquals(r.error, expectedErrMsg)
	end
	----------------------------------------
	function TestFlagValidatorFunctions:testRequiredFlagsValidationNumbericFlagSucceeds()
		local r, s = argproc.ProcessArguments({"--rqd", "--num=10"})
		luaunit.assertTrue(r.success)
		luaunit.assertEquals(r.flagsCount, 2)
		luaunit.assertIsTable(s)
		luaunit.assertEquals(#s, 0)
		luaunit.assertTrue(r.rqd)
		luaunit.assertEquals(tonumber(r.num), 10)
	end
	----------------------------------------
	function TestFlagValidatorFunctions:testRequiredFlagsValidationAlphaFlagFails()
		local expectedErrMsg = "ERROR:\tThe value for --alf is invalid - The flag value must be 'BOB'.\n\tThis is the alpha flag - optional but alpha validated."
		local r = argproc.ProcessArguments({"--rqd", "--alf"})
		luaunit.assertFalse(r.success)
		luaunit.assertEquals(r.error, expectedErrMsg)
	end
	----------------------------------------
	function TestFlagValidatorFunctions:testRequiredFlagsValidationAlphaFlagSucceeds()
		local r = argproc.ProcessArguments({"--rqd", "--alf=BOB"})
		luaunit.assertTrue(r.success)
	end
	----------------------------------------
	function TestFlagValidatorFunctions:testRequiredFlagsValidationDateStringFlagFails()
		local expectedErrMsg = "ERROR:\tThe value for --dte is invalid - 20151012 is not in the correct format of YYYY-MM-DD.\n\tThis is the datestring flag - optional but datestring validated."
		local r = argproc.ProcessArguments({"--rqd", "--dte=20151012"})
		luaunit.assertFalse(r.success)
		luaunit.assertEquals(r.error, expectedErrMsg)
	end
	----------------------------------------
	function TestFlagValidatorFunctions:testRequiredFlagsValidationDateStringFlagSucceeds()
		local r = argproc.ProcessArguments({"--rqd", "--dte=2015-10-12"})
		luaunit.assertTrue(r.success)
	end


-------------------------------------------------------------------------------
-- Test Help Functions
TestHelpFunctions = {}
	----------------------------------------
	function TestHelpFunctions:setUp()
	local instructions = [[
			*** The gpg Argument Processor ***
These are example instructions for the argument processor unit tests.

This is just a block of example text.

The last line of the instructions text block.
]]
		argproc.Reset()
		argproc.SetShowDebugMessages(false)
		argproc.SetScriptName(scriptName)
		argproc.SetInstructions(instructions)

		local spec = {}
		spec.rqd = argproc.BuildFlagSpecRecord("rqd", "requiredFlag", "This is the required flag - required.", nil, true)
		spec.num = argproc.BuildFlagSpecRecord("num", "numbericFlag", "This is the numberic flag - optional but numberic validated.")
		spec.alf = argproc.BuildFlagSpecRecord("alf", "alphaFlag", "This is the alpha flag - optional but alpha validated.")
		spec.dte = argproc.BuildFlagSpecRecord("dte", "dateFlag", "This is the datestring flag - optional but datestring validated.")
		spec.bol = argproc.BuildFlagSpecRecord("bol", "", "This is a boolean flag - optional.")
		local flagOrder = {"rqd", "num", "alf", "dte", "bol"}
		argproc.SetFlagSpecs(spec, nil, flagOrder)
	end
	----------------------------------------
	function TestHelpFunctions:TestHelpRequestWithNoArguments()
	local results = [[

			*** The gpg Argument Processor ***
These are example instructions for the argument processor unit tests.

This is just a block of example text.

The last line of the instructions text block.

Usage : Test_gpgArgumentProcessor.lua --rqd=requiredFlag [--num=numbericFlag] [--alf=alphaFlag] [--dte=dateFlag] [--bol]
Flags:
	--rqd : This is the required flag - required.
	--num : This is the numberic flag - optional but numberic validated. (OPTIONAL)
	--alf : This is the alpha flag - optional but alpha validated. (OPTIONAL)
	--dte : This is the datestring flag - optional but datestring validated. (OPTIONAL)
	--bol : This is a boolean flag - optional. (OPTIONAL)
]]
	
		local r = argproc.ProcessArguments()
		luaunit.assertFalse(r.success)
		luaunit.assertFalse(table.containsKey(r, "error"))
		luaunit.assertTrue(table.containsKey(r, "help"))
		luaunit.assertEquals(r.help, results)
	end
	----------------------------------------
	function TestHelpFunctions:TestHelpRequestWithHelpString()
	local results = [[

			*** The gpg Argument Processor ***
These are example instructions for the argument processor unit tests.

This is just a block of example text.

The last line of the instructions text block.

Usage : Test_gpgArgumentProcessor.lua --rqd=requiredFlag [--num=numbericFlag] [--alf=alphaFlag] [--dte=dateFlag] [--bol]
Flags:
	--rqd : This is the required flag - required.
	--num : This is the numberic flag - optional but numberic validated. (OPTIONAL)
	--alf : This is the alpha flag - optional but alpha validated. (OPTIONAL)
	--dte : This is the datestring flag - optional but datestring validated. (OPTIONAL)
	--bol : This is a boolean flag - optional. (OPTIONAL)
]]
	
		local r = argproc.ProcessArguments("help")
		luaunit.assertFalse(r.success)
		luaunit.assertFalse(table.containsKey(r, "error"))
		luaunit.assertTrue(table.containsKey(r, "help"))
		luaunit.assertEquals(r.help, results)
	end
	----------------------------------------
	function TestHelpFunctions:TestHelpRequestWithHelpFlag()
	local results = [[

			*** The gpg Argument Processor ***
These are example instructions for the argument processor unit tests.

This is just a block of example text.

The last line of the instructions text block.

Usage : Test_gpgArgumentProcessor.lua --rqd=requiredFlag [--num=numbericFlag] [--alf=alphaFlag] [--dte=dateFlag] [--bol]
Flags:
	--rqd : This is the required flag - required.
	--num : This is the numberic flag - optional but numberic validated. (OPTIONAL)
	--alf : This is the alpha flag - optional but alpha validated. (OPTIONAL)
	--dte : This is the datestring flag - optional but datestring validated. (OPTIONAL)
	--bol : This is a boolean flag - optional. (OPTIONAL)
]]
	
		local r = argproc.ProcessArguments("--?")
		luaunit.assertFalse(r.success)
		luaunit.assertFalse(table.containsKey(r, "error"))
		luaunit.assertTrue(table.containsKey(r, "help"))
		luaunit.assertEquals(r.help, results)
	end

-------------------------------------------------------------------------------
-- Test Help With Zero Flags Settings Functions
TestHelpOnZeroFlagFunctions = {}
	----------------------------------------
	function TestHelpOnZeroFlagFunctions:setUp()
	local instructions = [[
			*** The gpg Argument Processor ***
These are example instructions for the argument processor unit tests.

This is just a block of example text.

The last line of the instructions text block.
]]
		argproc.Reset()
		argproc.SetShowDebugMessages(false)
		argproc.SetScriptName(scriptName)
		argproc.SetInstructions(instructions)
		
		local successVal = function(c)
			assert(c ~= nil and type(c) == "table", "why?")
			return true, ""
		end

		local spec = {}
		spec.num = argproc.BuildFlagSpecRecord("num", "numbericFlag", "This is the numberic flag - optional but numberic validated.")
		spec.alf = argproc.BuildFlagSpecRecord("alf", "alphaFlag", "This is the alpha flag - optional but alpha validated.")
		spec.dte = argproc.BuildFlagSpecRecord("dte", "dateFlag", "This is the datestring flag - optional but datestring validated.")
		spec.bol = argproc.BuildFlagSpecRecord("bol", "", "This is a boolean flag - optional.")
		local flagOrder = {"num", "alf", "dte", "bol"}
		argproc.SetFlagSpecs(spec, successVal, flagOrder, false)
	end
	----------------------------------------
	function TestHelpOnZeroFlagFunctions:TestHelpRequestWithNoArguments()

		local r = argproc.ProcessArguments()
		luaunit.assertTrue(r.success)												-- Should fall through and succeed.
		luaunit.assertFalse(table.containsKey(r, "error"))	-- No errors.
		luaunit.assertFalse(table.containsKey(r, "help"))		-- No help requested.
	end
	----------------------------------------
	function TestHelpOnZeroFlagFunctions:TestHelpRequestWithHelpString()
	local results = [[

			*** The gpg Argument Processor ***
These are example instructions for the argument processor unit tests.

This is just a block of example text.

The last line of the instructions text block.

Usage : Test_gpgArgumentProcessor.lua [--num=numbericFlag] [--alf=alphaFlag] [--dte=dateFlag] [--bol]
Flags:
	--num : This is the numberic flag - optional but numberic validated. (OPTIONAL)
	--alf : This is the alpha flag - optional but alpha validated. (OPTIONAL)
	--dte : This is the datestring flag - optional but datestring validated. (OPTIONAL)
	--bol : This is a boolean flag - optional. (OPTIONAL)
]]
	
		local r = argproc.ProcessArguments("help")
		luaunit.assertFalse(r.success)
		luaunit.assertFalse(table.containsKey(r, "error"))
		luaunit.assertTrue(table.containsKey(r, "help"))
		luaunit.assertEquals(r.help, results)
	end
	----------------------------------------
	function TestHelpOnZeroFlagFunctions:TestHelpRequestWithHelpFlag()
	local results = [[

			*** The gpg Argument Processor ***
These are example instructions for the argument processor unit tests.

This is just a block of example text.

The last line of the instructions text block.

Usage : Test_gpgArgumentProcessor.lua [--num=numbericFlag] [--alf=alphaFlag] [--dte=dateFlag] [--bol]
Flags:
	--num : This is the numberic flag - optional but numberic validated. (OPTIONAL)
	--alf : This is the alpha flag - optional but alpha validated. (OPTIONAL)
	--dte : This is the datestring flag - optional but datestring validated. (OPTIONAL)
	--bol : This is a boolean flag - optional. (OPTIONAL)
]]
	
		local r = argproc.ProcessArguments("--?")
		luaunit.assertFalse(r.success)
		luaunit.assertFalse(table.containsKey(r, "error"))
		luaunit.assertTrue(table.containsKey(r, "help"))
		luaunit.assertEquals(r.help, results)
	end

-- END TestHelpOnZeroFlagFunctions

-------------------------------------------------------------------------------
-- Test Help With Zero Flags Settings Functions
TestHelpOnVariousLengthFlags = {}
	----------------------------------------
	function TestHelpOnVariousLengthFlags:setUp()
	local instructions = [[
			*** The gpg Argument Processor ***
These are example instructions for the argument processor unit tests.

This is just a block of example text.

The last line of the instructions text block.
]]
		argproc.Reset()
		argproc.SetShowDebugMessages(false)
		argproc.SetScriptName(scriptName)
		argproc.SetInstructions(instructions)
		
		local successVal = function(c)
			assert(c ~= nil and type(c) == "table", "why?")
			return true, ""
		end

		local spec = {}
		spec.a = argproc.BuildFlagSpecRecord("a", "A_Flag", "This is the A Flag.")
		spec.ab = argproc.BuildFlagSpecRecord("ab", "AB_Flag", "This is the AB Flag.")
		spec.abc = argproc.BuildFlagSpecRecord("abc", "ABC_Flag", "This is the ABC Flag.")
		spec.abcd = argproc.BuildFlagSpecRecord("abcd", "ABCD_Flag", "This is the ABCD Flag.")
		local flagOrder = {"a", "abcd", "ab", "abc" }
		argproc.SetFlagSpecs(spec, successVal, flagOrder, false)
	end
	----------------------------------------
	function TestHelpOnVariousLengthFlags:TestHelpRequest()
	local results = [[

			*** The gpg Argument Processor ***
These are example instructions for the argument processor unit tests.

This is just a block of example text.

The last line of the instructions text block.

Usage : Test_gpgArgumentProcessor.lua [--a=A_Flag] [--abcd=ABCD_Flag] [--ab=AB_Flag] [--abc=ABC_Flag]
Flags:
	--a    : This is the A Flag. (OPTIONAL)
	--abcd : This is the ABCD Flag. (OPTIONAL)
	--ab   : This is the AB Flag. (OPTIONAL)
	--abc  : This is the ABC Flag. (OPTIONAL)
]]
	
		local r = argproc.ProcessArguments("help")
		luaunit.assertFalse(r.success)
		luaunit.assertFalse(table.containsKey(r, "error"))
		luaunit.assertTrue(table.containsKey(r, "help"))
		luaunit.assertEquals(r.help, results)
	end
-- END TestHelpOnVariousLengthFlags


-------------------------------------------------------------------------------
-- Test Handling Flag Order Issues
TestFlagOrderIssues = {}
	----------------------------------------
	function TestFlagOrderIssues:TestFlagOrderWithMissingFlag()
	local instructions = [[
			*** The gpg Argument Processor ***
These are example instructions for the argument processor unit tests.

This is just a block of example text.

The last line of the instructions text block.
]]
		argproc.Reset()
		argproc.SetShowDebugMessages(false)
		argproc.SetScriptName(scriptName)
		argproc.SetInstructions(instructions)

		local spec = {}
		spec.rqd = argproc.BuildFlagSpecRecord("rqd", "requiredFlag", "This is the required flag - required.", nil, true)
		spec.num = argproc.BuildFlagSpecRecord("num", "numbericFlag", "This is the numberic flag - optional but numberic validated.")
		spec.alf = argproc.BuildFlagSpecRecord("alf", "alphaFlag", "This is the alpha flag - optional but alpha validated.")
		spec.dte = argproc.BuildFlagSpecRecord("dte", "dateFlag", "This is the datestring flag - optional but datestring validated.")
		local flagOrder = {"rqd", "num", "alf", "dte", "bol"}
		argproc.SetFlagSpecs(spec, nil, flagOrder)
	local results = [[

			*** The gpg Argument Processor ***
These are example instructions for the argument processor unit tests.

This is just a block of example text.

The last line of the instructions text block.

Usage : Test_gpgArgumentProcessor.lua --rqd=requiredFlag [--num=numbericFlag] [--alf=alphaFlag] [--dte=dateFlag]
Flags:
	--rqd : This is the required flag - required.
	--num : This is the numberic flag - optional but numberic validated. (OPTIONAL)
	--alf : This is the alpha flag - optional but alpha validated. (OPTIONAL)
	--dte : This is the datestring flag - optional but datestring validated. (OPTIONAL)
]]
	
		local r = argproc.ProcessArguments()
		luaunit.assertFalse(r.success)
		luaunit.assertFalse(table.containsKey(r, "error"))
		luaunit.assertTrue(table.containsKey(r, "help"))
		luaunit.assertEquals(r.help, results)
	end
	----------------------------------------
	function TestFlagOrderIssues:TestFlagOrderWithFlagsThatAreNotStrings()
	local instructions = [[
			*** The gpg Argument Processor ***
These are example instructions for the argument processor unit tests.

This is just a block of example text.

The last line of the instructions text block.
]]
		argproc.Reset()
		argproc.SetShowDebugMessages(false)
		argproc.SetScriptName(scriptName)
		argproc.SetInstructions(instructions)

		local spec = {}
		spec.rqd = argproc.BuildFlagSpecRecord("rqd", "requiredFlag", "This is the required flag - required.", nil, true)
		spec.num = argproc.BuildFlagSpecRecord("num", "numbericFlag", "This is the numberic flag - optional but numberic validated.")
		local flagOrder = {rqd, num}
		argproc.SetFlagSpecs(spec, nil, flagOrder)
		
		local expectedErrMsg = "The flag order must be a table populated with the flag spec keys as strings."	

		luaunit.assertErrorMsgContains(expectedErrMsg, argproc.ProcessArguments)
	end
	----------------------------------------
-- END TestFlagOrderIssues


-------------------------------------------------------------------------------
-- 												MAIN
-------------------------------------------------------------------------------

print("\n-------------------------------------------------------------------------------")
print("Running gpg-ArgumentProcessor unit tests: \n\n")
os.exit(luaunit.LuaUnit.run("-v"))