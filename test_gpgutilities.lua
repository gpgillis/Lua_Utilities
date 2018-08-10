-------------------------------------------------------------------------------
-- Unit Tests for gpg Utilities
-- 
-- GPG - 20150604
-------------------------------------------------------------------------------

local gpg = require("gpgUtilities")
local luaunit = require("LuaUnit")
local inspect = require("inspect")

-------------------------------------------------------------------------------
-- Misc Functions Tests:
TestMiscFunctions = {}
	function TestMiscFunctions:setUp()
		gpg.SetShowDebugMessages(false)
	end

		----------------------------------------
	-- Debug message tests
		----------------------------------------

	function TestMiscFunctions:testSettingDebugMessagesFlag()
		luaunit.assertFalse(gpg.GetShowDebugMessages())
		gpg.SetShowDebugMessages(true)
		luaunit.assertTrue(gpg.GetShowDebugMessages())
	end

	function TestMiscFunctions:tearDown()
		gpg.SetShowDebugMessages(false)
	end

		----------------------------------------
	-- ParseFlags tests
		----------------------------------------

	function TestMiscFunctions:testParseFlagsWithTableArgument()
		local flags =  {["bla"] = true, ["tux"] = "beep", ["baz"] = true}
		local strgs = {"foo", "bar"}
		local count = 3
		local argsTbl = {"foo", "--tux=beep", "--bla", "bar", "--baz"}
		
		local rflags, rstrgs, rcount = gpg.ParseFlags(argsTbl)

		luaunit.assertIsTable(rflags)
		luaunit.assertEquals(rflags, flags)

		luaunit.assertIsTable(rstrgs)
		luaunit.assertEquals(rstrgs, strgs)
		
		luaunit.assertIsNumber(rcount)
		luaunit.assertEquals(rcount, count)
	end

	function TestMiscFunctions:testParseFlagsWithMultipleArguments()
		local flags =  {["bla"] = true, ["tux"] = "beep", ["baz"] = true}
		local strgs = {"foo", "bar"}
		local count = 3

		local rflags, rstrgs, rcount = gpg.ParseFlags("foo", "--tux=beep", "--bla", "bar", "--baz")

		luaunit.assertIsTable(rflags)
		luaunit.assertEquals(rflags, flags)

		luaunit.assertIsTable(rstrgs)
		luaunit.assertEquals(rstrgs, strgs)

		luaunit.assertIsNumber(rcount)
		luaunit.assertEquals(rcount, count)
	end
	
	function TestMiscFunctions:testParseFlagsWithEmptyArguments()
		local f, s, c = gpg.ParseFlags()	-- no arguments
		luaunit.assertEquals({}, f)
		luaunit.assertEquals({}, s)
		luaunit.assertEquals(c, 0)

		f, s, c = gpg.ParseFlags({})	-- empty table argument
		luaunit.assertEquals({}, f)
		luaunit.assertEquals({}, s)
		luaunit.assertEquals(c, 0)
	end
	
	function TestMiscFunctions:testParseFlagsWithInvalidArguments()
		local flags =  {["bla"] = true, ["tux"] = "beep", ["baz"] = true}
		local strgs = {"foo", "bar"}
		local count = 3
		luaunit.assertError(gpg.ParseFlags, flag, strgs)
	end

		----------------------------------------
	-- DisplayHack tests
		----------------------------------------

	function TestMiscFunctions:testDisplayHackSimple()
		local spinner = gpg.DisplayHack(1000)
		luaunit.assertIsFunction(spinner)
		luaunit.assertEquals(gpg.private.period, 250)

		local iterations = 100
		for i = 1, iterations do
			spinner()
		end

		luaunit.assertEquals(spinner(true), iterations)
	end

	function TestMiscFunctions:testDisplayHackNeedsIntervalCorrection()
		local spinner = gpg.DisplayHack(1313)
		luaunit.assertIsFunction(spinner)
		luaunit.assertEquals(gpg.private.period, 250)
	end
	
	function TestMiscFunctions:testDisplayHackNilIntervalCorrection()
		local spinner = gpg.DisplayHack()
		luaunit.assertIsFunction(spinner)
		luaunit.assertEquals(gpg.private.period, 250)
	end

	----------------------------------------
	-- ToInteger Tests
	----------------------------------------
	function TestMiscFunctions:testToInteger_ValidNumber_ReturnsInteger()
		local teststrg = "2050"
		local expected = 2050
		luaunit.assertEquals(gpg.ToInteger(teststrg), expected)
	end
	
	function TestMiscFunctions:testToInteger_AlphaInput_ThrowsError()
		local teststrg = "ABC"
		luaunit.assertError(gpg.ToInteger, teststrg)
	end
	
	function TestMiscFunctions:testToInteger_FloatInput_ReturnsInteger()
		local teststrg = "12.23"
		local expected = 12
		luaunit.assertEquals(gpg.ToInteger(teststrg), expected)
	end

-- END TestMiscFunctions class

-------------------------------------------------------------------------------
-- Collections Functions Tests
TestCollectionsFunctions = {}

	----------------------------------------
	-- PairsByKey tests
		----------------------------------------
	
	function TestCollectionsFunctions:testPairsByKeyWithNumberKeys()
		local col = { ["2"] = "two", ["4"] = "four", ["1"] = "one", ["3"] = "three"}
		local sorted = gpg.PairsByKey(col)
		luaunit.assertIsFunction(sorted)

		local target = 1
		for k,v in sorted do
			luaunit.assertEquals(tonumber(k), target)
			target = target + 1
		end
	end

	function TestCollectionsFunctions:testPairsByKeyWithNumberKeysInvertedOrder()
		local col = { ["2"] = "two", ["4"] = "four", ["1"] = "one", ["3"] = "three"}
		local sorted = gpg.PairsByKey(col, function (a, b) return a > b end)
		luaunit.assertIsFunction(sorted)

		local target = 4
		for k,v in sorted do
			luaunit.assertEquals(tonumber(k), target)
			target = target - 1
		end
	end

	function TestCollectionsFunctions:testPairsByKeyWithAlphKeys()
		local col = { ["charlie"] = "charlie", ["alpha"] = "alpha", ["delta"] = "delta", ["beta"] = "beta"}
		local sorted = gpg.PairsByKey(col)
		luaunit.assertIsFunction(sorted)

		local targets = {"delta", "charlie", "beta", "alpha"}		-- NOTE:  This collection is used as a LIFO stack for validation of sorted keys.
		for k,v in sorted do
			local target = table.remove(targets)
			luaunit.assertEquals(k, target)
		end
	end

	----------------------------------------
	-- UniqueValueEvaluator tests
		----------------------------------------
	
	function TestCollectionsFunctions:testUniqueValueEvaluatorFailsWithCollectionArgument()
		local e = gpg.UniqueValueEvaluator()
		luaunit.assertIsFunction(e)
		luaunit.assertError(e, {1, 2, 3})
	end

	function TestCollectionsFunctions:testUniqueValueEvaluator()
		local e = gpg.UniqueValueEvaluator()
		luaunit.assertIsFunction(e)

		for i = 1, 10 do
			luaunit.assertTrue(e(i))							-- These should all be unique.
		end

		for i = 1, 10, 2 do
			luaunit.assertFalse(e(i))							-- These should all be duplicates.
		end

		local testVal = 100
		luaunit.assertTrue(e(testVal, false))		-- Should be unique but the value not saved to the evaluator.
		luaunit.assertTrue(e(testVal))					-- Should still be unique but save the value.
		luaunit.assertFalse(e(testVal))					-- Value is no longer unique.

	end
	
		----------------------------------------
	-- UniqueSetEvaluator tests
		----------------------------------------

	function TestCollectionsFunctions:testUniqueSetEvaluatorFailsWithCollectionInArguments()
		local usc = gpg.UniqueSetEvaluator()
		luaunit.assertIsFunction(usc)
		luaunit.assertError(usc, {1, 2, {"bob", "bill"}, 3})
	end

	function TestCollectionsFunctions:testUniqueSetEvaluatorWithNilArgument()
		local usc = gpg.UniqueSetEvaluator()
		luaunit.assertIsFunction(usc)
		luaunit.assertTrue(usc(nil))
		luaunit.assertFalse(usc(nil))
	end

	function TestCollectionsFunctions:testUniqueSetEvaluator()
		local usc = gpg.UniqueSetEvaluator()
		luaunit.assertIsFunction(usc)
		luaunit.assertTrue(usc(1, 2, 3, 4))
		luaunit.assertTrue(usc("A", "B", "C", "D"))
		luaunit.assertFalse(usc(1, 2, 3, 4))
		luaunit.assertFalse(usc("A", "B", "C", "D"))
	end

	----------------------------------------
	-- SetContainsValueEvaluator tests
		----------------------------------------

	function TestCollectionsFunctions:testSetContainsValueEvaluator()
		local testSet = {1, 2, 3, 4, "A", "B", "C"}
		local skv = gpg.SetContainsValueEvaluator(testSet)
		luaunit.assertIsFunction(skv)

		for _,v in pairs(testSet) do
			luaunit.assertTrue(skv(v))
		end

		luaunit.assertFalse(skv(5))
		luaunit.assertFalse(skv("BOB"))
	end
	
	function TestCollectionsFunctions:testSetContainsValueEvaluatorInitializationFails()
		luaunit.assertError(gpg.SetContainsValueEvaluator, nil)
		luaunit.assertError(gpg.SetContainsValueEvaluator, "")
	end

		----------------------------------------
	-- CalculateMaxStringLength tests
		----------------------------------------
	function TestCollectionsFunctions:testCalculateMaxStringLengthWithNilCollection()
		luaunit.assertEquals(gpg.CalculateMaxStringLength(nil), 0)
	end

	function TestCollectionsFunctions:testCalculateMaxStringLength()
		local f1 = "f1"
		local f2 = "flag2"
		local f3 = "myFlag3"
		local f4 = "myLongFlag4"
		local flags = { f1, f2, f3, f4 }
		luaunit.assertEquals(gpg.CalculateMaxStringLength(flags), 11)
	end

--	END TestCollectionsFunctions


-------------------------------------------------------------------------------
-- String Functions Tests
TestStringFunctions = {}

	function TestStringFunctions:testSplitString()
		local s1, s2 = gpg.SplitString("This is the first part, this is the second", ",")
		luaunit.assertEquals(s1, "This is the first part")
		luaunit.assertEquals(s2, " this is the second")
		
		s1, s2 = gpg.SplitString("This string cannot be split", "*")
		luaunit.assertIsNil(s1)
		luaunit.assertIsNil(s2)
		
		s1, s2 = gpg.SplitString(", This is the second part - there is no first part", ",")
		luaunit.assertEquals(s1, "")
		luaunit.assertEquals(s2, " This is the second part - there is no first part")

		s1, s2 = gpg.SplitString("This is the first part - there is no second part, ", ",")
		luaunit.assertEquals(s1, "This is the first part - there is no second part")
		luaunit.assertEquals(s2, " ")
		
		-- Now tab delimited
		s1, s2 = gpg.SplitString("This is the first part	this is the second", "\t")
		luaunit.assertEquals(s1, "This is the first part")
		luaunit.assertEquals(s2, "this is the second")

		s1, s2 = gpg.SplitString("	This is the second part - there is no first part", "\t")
		luaunit.assertEquals(s1, "")
		luaunit.assertEquals(s2, "This is the second part - there is no first part")

		s1, s2 = gpg.SplitString("This is the first part - there is no second part	", "\t")
		luaunit.assertEquals(s1, "This is the first part - there is no second part")
		luaunit.assertEquals(s2, "")
	end

	function TestStringFunctions:testStringIsNilOrEmpty()
		luaunit.assertTrue(gpg.StringIsNilOrEmpty(nil))
		luaunit.assertTrue(gpg.StringIsNilOrEmpty(""))
		luaunit.assertFalse(gpg.StringIsNilOrEmpty("This is a test string"))
	end

	function TestStringFunctions:testStringStartsWith()
		luaunit.assertTrue(gpg.StringStartsWith("Bob is a big kitty", "Bob"))
		luaunit.assertFalse(gpg.StringStartsWith("Bob is a big kitty", "bob"))
	end

	function TestStringFunctions:testStringEndsWith()
		luaunit.assertTrue(gpg.StringEndsWith("Bob is a big kitty.", "kitty."))
		luaunit.assertFalse(gpg.StringEndsWith("Bob is a big kitty", "bob"))
	end

	function TestStringFunctions:testTrimString()
		local test = "This is the test string"
		local withspaces = "       " .. test .. "           "
		
		luaunit.assertEquals(gpg.TrimString(withspaces), test)
	end

	function TestStringFunctions:testFormatStateCode()
		luaunit.assertEquals(gpg.FormatStateCode("1"), "01")
		luaunit.assertEquals(gpg.FormatStateCode("10"), "10")
	end
	
	function TestStringFunctions:testSafeString()
		luaunit.assertEquals(gpg.SafeString(nil), "")
		luaunit.assertEquals(gpg.SafeString("TestString"), "TestString")
	end

	function TestStringFunctions:testMakeStringTitleCase()
		luaunit.assertEquals(gpg.MakeStringTitleCase(""), "")		-- Should not fail and should return empty string.
		luaunit.assertEquals(gpg.MakeStringTitleCase(nil), "")	-- Should not fail and should return empty string.
		luaunit.assertEquals(gpg.MakeStringTitleCase("the way We were and Other stories"), "The Way We Were And Other Stories")
	end
	
	function TestStringFunctions:testWordCount()
		local test = "This test string contains a number of words and the string method in test counts the number of times the word string is used."
		local count = 3
		luaunit.assertEquals(gpg.WordCount(test, "string"), count)
		luaunit.assertEquals(0, gpg.WordCount("This Is A Test String", "JONES"))
		luaunit.assertEquals(0, gpg.WordCount("This Is A Test String", ""))
		luaunit.assertEquals(0, gpg.WordCount(""))
	end
	
	function TestStringFunctions:testCharacterCount()
		local test = "This string contains a number of characters"
		local count = 4		-- There are 4 's' characters in this string.
		
		luaunit.assertEquals(gpg.CharacterCount(test, "s"), count)
		luaunit.assertEquals(gpg.CharacterCount("", ""), 0)
		luaunit.assertEquals(gpg.CharacterCount(test, ""), 0)
		luaunit.assertError(gpg.CharacterCount, test, "CB")
	end
	
	----------------------------------------
	-- FormatTitle tests
	----------------------------------------

	function TestStringFunctions:testFormatTitleFailed()
		local seventyFourChar = "12345678901234567890123456789012345678901234567890123456789012345678901234"
		local eightyChar = "12345678901234567890123456789012345678901234567890123456789012345678901234567890"

		luaunit.assertError(gpg.FormatTitle, nil)
		luaunit.assertError(gpg.FormatTitle, {eightyChar})
		luaunit.assertError(gpg.FormatTitle, {seventyFourChar, eightyChar})
	end

	function TestStringFunctions:testFormatTitleCentered()
		local title = "12345678901"
		local desc = "1234567890123456789"

		local expectedS = [[

--------------------------------------------------------------------------------
--|                                12345678901                               |--
--------------------------------------------------------------------------------
]]
		local expectedD = [[

--------------------------------------------------------------------------------
--|                                12345678901                               |--
--|                            1234567890123456789                           |--
--------------------------------------------------------------------------------
]]

		luaunit.assertEquals(gpg.FormatTitle({title}), expectedS)
		luaunit.assertEquals(gpg.FormatTitle({title, desc}), expectedD)
	end

	function TestStringFunctions:testFormatTitleStandardLength()
		local seventyFourChar = "12345678901234567890123456789012345678901234567890123456789012345678901234"
		local expected74S = [[

--------------------------------------------------------------------------------
--|12345678901234567890123456789012345678901234567890123456789012345678901234|--
--------------------------------------------------------------------------------
]]
		local expected74D = [[

--------------------------------------------------------------------------------
--|12345678901234567890123456789012345678901234567890123456789012345678901234|--
--|12345678901234567890123456789012345678901234567890123456789012345678901234|--
--------------------------------------------------------------------------------
]]

		luaunit.assertEquals(gpg.FormatTitle({seventyFourChar}), expected74S)
		luaunit.assertEquals(gpg.FormatTitle({seventyFourChar, seventyFourChar}), expected74D)
	end

	function TestStringFunctions:testFormatTitleCustomLength()
		local eightyChar = "12345678901234567890123456789012345678901234567890123456789012345678901234567890"
		local expected80S = [[

------------------------------------------------------------------------------------------
--|  12345678901234567890123456789012345678901234567890123456789012345678901234567890  |--
------------------------------------------------------------------------------------------
]]
		local expected80D = [[

------------------------------------------------------------------------------------------
--|  12345678901234567890123456789012345678901234567890123456789012345678901234567890  |--
--|  12345678901234567890123456789012345678901234567890123456789012345678901234567890  |--
------------------------------------------------------------------------------------------
]]

		luaunit.assertEquals(gpg.FormatTitle({eightyChar}, 90), expected80S)
		luaunit.assertEquals(gpg.FormatTitle({eightyChar, eightyChar}, 90), expected80D)
	end

-- END TestStringFunctions

-------------------------------------------------------------------------------
-- Date Function Tests

TestDateFunctions = {}

	function TestDateFunctions:testValidateDateString_DateString_IsValid()
		local testdate = "20150102"
		luaunit.assertTrue(gpg.ValidateDateString(testdate, gpg.DateStringMatchExpression))
	end

	function TestDateFunctions:testValidateDateString_DateString_IsInvalid()
		local testdate = "2015A102"
		luaunit.assertFalse(gpg.ValidateDateString(testdate, gpg.DateStringMatchExpression))
	end
	
	function TestDateFunctions:testValidateDateString_SteDateString_IsValid()
		local testdate = "2015-01-02"
		luaunit.assertTrue(gpg.ValidateDateString(testdate, gpg.SteDateStringMatchExpression))
	end
	
	function TestDateFunctions:testValidateDateString_SteDateString_IsInvalid()
		local testdate = "20150102"
		luaunit.assertTrue(gpg.ValidateDateString(testdate, gpg.DateStringMatchExpression))
	end

	function TestDateFunctions:testGetDateString()
		local testdate = gpg.GetDateString()
		luaunit.assertTrue(gpg.ValidateDateString(testdate, gpg.DateStringMatchExpression))
	end

	function TestDateFunctions:testDecrementDateString_InvalidDate_ReturnsNil()
		local testdate = "1234"
		local expected = nil
		luaunit.assertEquals(gpg.DecrementDateString(testdate), expected)
	end

	function TestDateFunctions:testDecrementDateString_DecrementOneDate_ValidReturn()
		local testdate = "20150103"
		local expected = "20150102"
		luaunit.assertEquals(gpg.DecrementDateString(testdate), expected)
	end

	-- The DecrementDateString function should be able to handle year bounderies.
	function TestDateFunctions:testDecrementDateString_DecrementAcrossYear_ValidReturn()
		local testdate = "20150101"
		local expected = "20141231"
		luaunit.assertEquals(gpg.DecrementDateString(testdate), expected)
	end

	function TestDateFunctions:testDecrementDateString_MultipleDateDecrement_ValidReturn()
		local testdate = "20150510"
		local decdays = 12
		local expected = "20150428"
		luaunit.assertEquals(gpg.DecrementDateString(testdate, decdays), expected)
	end

	-- The DecrementDateString should be able to handle leap years.
	function TestDateFunctions:testDecrementDateString_DecrementInLeapYear_ValidReturn()
		local testdate = "20120301"
		local expected = "20120229"
		luaunit.assertEquals(gpg.DecrementDateString(testdate), expected)
	end

-- END Test Date Functions class

-------------------------------------------------------------------------------
-- Table function test class

TestTableFunctions = {}
---------------------------------------
-- Test table extention methods.
---------------------------------------

	function TestTableFunctions:setUp()
		self.testTbl = { ["A"] = "record1", ["B"] = 2, ["C"] = "record3" }
	end

	function TestTableFunctions:testContainsKeyExtentionFunction()
		luaunit.assertError(table.containsKey, "A")
		luaunit.assertFalse(table.containsKey(nil, "A"))
		luaunit.assertTrue(table.containsKey(self.testTbl, "A"))
		luaunit.assertFalse(table.containsKey(self.testTbl, "Z"))
	end

	function TestTableFunctions:testContainsValueExtensionFunction()
	luaunit.assertError(table.containsValue, "A")
	luaunit.assertFalse(table.containsValue(nil, "A"))
	luaunit.assertTrue(table.containsValue(self.testTbl, "record1"))
	luaunit.assertTrue(table.containsValue(self.testTbl, 2))
	luaunit.assertFalse(table.containsValue(self.testTbl, "record9"))
	end
	
	function TestTableFunctions:testKeysExtensionFunction()
		local expected = {}
		for k,_ in pairs(self.testTbl) do
			table.insert(expected, k)
		end
		luaunit.assertError(table.Keys, nil)
		luaunit.assertEquals(table.Keys(self.testTbl), expected)
	end

	function TestTableFunctions:testAddRangeExtensionFunction()
		local tt = { 2, 4, 6, 8, 10 }
		local ad = { 1, 3, 7, 9, 11 }
		local expected = tt
		for _,v in pairs(ad) do
			table.insert(tt, v)
		end
		table.addRange(tt, ad)
		luaunit.assertEquals(tt, expected)
		luaunit.assertError(table.addRange, nil, tt)
		luaunit.assertError(table.addRange, tt, nil)
	end

	function TestTableFunctions:testDelimitedStringToTable()
		local str = "bob|george|ben|tim|tom|tony"
		local expected = { "bob","george","ben","tim","tom","tony" }
		luaunit.assertEquals(gpg.DelimitedStringToTable(str, "|"), expected)
		
		str = "|bob|george|ben|"
		expected = {"", "bob", "george", "ben", ""}
		luaunit.assertEquals(gpg.DelimitedStringToTable(str, "|"), expected)
		
		str = "	Status	Code	File	Line	Column	Project	Read/Write	"
		expected = {"Status", "Code", "File", "Line", "Column", "Project", "Read/Write", ""}
		luaunit.assertEquals(gpg.DelimitedStringToTable(str, "\t"), expected)
	end

	-- The CSVStringToTable function calls into the DelimitedStringToTable function 
	--with a comma delimiter but we test it anyways.
	function TestTableFunctions:testCSVStringToTable()
		local str = "bob,george,ben,tim,tom,tony"
		local expected = { "bob","george","ben","tim","tom","tony" }
		luaunit.assertEquals(gpg.CSVStringToTable(str), expected)
	end
	
	function TestTableFunctions:tearDown()
		self.testTbl = nil
	end

-- END Test table functions class

-------------------------------------------------------------------------------
-- The following tests the directory, file and buffer utility method:

---------------------------------------
-- Directory functions tests
---------------------------------------
TestDirectoryFunctions = {}

	function TestDirectoryFunctions:setUp()
		self.testdir = "DirTestDirectory"
		os.execute("rd " .. self.testdir .. "/S/Q 2>NUL >NUL")
	end

	function TestDirectoryFunctions:testDirectoryCreation()
		luaunit.assertFalse(gpg.DirectoryExists(self.testdir))
		gpg.CreateDirectory(self.testdir)
		luaunit.assertTrue(gpg.DirectoryExists(self.testdir))
	end

	function TestDirectoryFunctions:testFindLastPathElement()
		local expected_remainder = "c:/test1/test2/"
		local expected_last = "test3"
		local testpath = expected_remainder .. expected_last

		local remainder, last = gpg.FindLastPathElement(testpath)
		luaunit.assertEquals(remainder, expected_remainder)
		luaunit.assertEquals(last, expected_last)
	end

	function TestDirectoryFunctions:tearDown()
		os.execute("rd " .. self.testdir .. "/S/Q 2>NUL >NUL")
	end

--	END Test Directory Functions


---------------------------------------
-- Filenames Tests
---------------------------------------
TestCreateFilenames = {}

	function TestCreateFilenames:testBasicFilenameCreation()
		local testbase = "BaseName.txt"
		luaunit.assertEquals(gpg.CreateOutputFileName(testbase, false), testbase)
	end

	function TestCreateFilenames:testDateStampedFilenameCreation()
		local testbase = "BaseName.txt"
		local expected = "BaseName_" .. gpg.GetDateString() .. ".txt"
		luaunit.assertEquals(gpg.CreateOutputFileName(testbase, true), expected)
	end

	function TestCreateFilenames:testCreateFilenameWithInjectionValue()
		local testbase = "BaseName.txt"
		local injection = "Injection"
		local expected = "BaseName_Injection.txt"
		luaunit.assertEquals(gpg.CreateOutputFileName(testbase, false, injection), expected)
	end

	function TestCreateFilenames:testCreateFilenameFromSourceName()
		local testbase = "BaseName.txt"
		local testext = "csv"
		expected = "BaseName.csv"
		luaunit.assertEquals(gpg.CreateOutputFileNameFromSourceFileName(testbase, testext), expected)
	end

-- END TestCreateFilenames class

---------------------------------------
-- 
---------------------------------------

-------------------------------------------------------------------------------
-- 												MAIN
-------------------------------------------------------------------------------

print("\n-------------------------------------------------------------------------------")
print("Running gpg-Utilities unit tests: \n\n")
os.exit(luaunit.LuaUnit.run("-v"))