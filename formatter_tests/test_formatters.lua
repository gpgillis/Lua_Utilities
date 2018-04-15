-------------------------------------------------------------------------------
-- This is a unit test set and example usages for our XML and TEXT formatters.
--
-- The unit tests are performed first, with a choice of running the examples after.
-- The expected output for the unit tests was generated from running the formatters
-- and any deviations found should be carefully checked before modification to the
-- expected output definitions.

-- This test and example set requires the following formatter definition files local to this file:
local formatter = require "XmlFormatter"
local otherFormatter = require "MyFormatter"
local sillyFormatter = require "MySillyFormatter"
local textFormatter = require "MyTextFormatter"

local luaunit = require "LuaUnit"
local gpg = require "gpgUtilities"

local scriptName = arg[0]

-------------------------------------------------------------------------------
--  This example shows the use of our XML formatter with named formats.
--
function ExampleXmlFormatter(unitTesting)
	local systemDate = (unitTesting) and "SYSTEM-DATE" or tostring(os.date("%c")) 	-- We dummy the system date for unit testing

	local comments = {"This is the first comment", "This is the second comment", string.format("Created by %s on %s", scriptName, systemDate) }
	formatter.InitializeBuffer("RootNode", comments)

	local spec = [[
	<County_Description>
		<state_code>%s</state_code>
		<county_code>%s</county_code>
		<description>%s</description>
	</County_Description>]]

	formatter.AddNamedFormat("CountyData", spec)

	spec = [[
	<School_Description>
		<state_code>%s</state_code>
		<county_code>%s</county_code>
		<school_code>%s</school_code>
		<description>%s</description>
	</School_Description>]]

	formatter.AddNamedFormat("SchoolData", spec)

	formatter.AddNamedNode("CountyData", "26", "161", "Washtenaw")
	formatter.AddNamedNode("CountyData", "39", "125", "Lucas")
	formatter.AddNamedNode("SchoolData", "39", "125", "1234", "Lucase CSD")
	formatter.AddNamedNode("SchoolData", "39", "002", "4223", "Bobbler CSD")

	return formatter.FinalizeBuffer()
end	-- TestXmlFormatter

-------------------------------------------------------------------------------
--
function RunExampleXmlFormatter()
	local buffer = ExampleXmlFormatter()
	print("\nResults:\n")
	for k,v in pairs(buffer) do print(v) end
end

-------------------------------------------------------------------------------
-- This example is used to show how the same data can be used to generate
-- different outputs depending on the formatter in use.
function ExampleOtherFormatter(theFormatter, unitTesting)
	theFormatter.InitializeFormatter(scriptName, unitTesting)
	theFormatter.AddData("25-126-625625", "SIT", "48130", "State Income", "Michigan")
	theFormatter.AddData("25-126-123123", "SUI", "48103", "Unemployement", "Michigan")
	theFormatter.AddData("25-115-645896", "CITY", "48130", "City Tax", "Michigan")
	theFormatter.AddError("This is an error message test")
	return theFormatter.FinalizeBuffer()
end	-- TestXmlFormatter

-------------------------------------------------------------------------------
-- 
function RunExampleOtherFormatter(theFormatter)
	local buffer = ExampleOtherFormatter(theFormatter)
	print("\nResults:\n")
	for k,v in pairs(buffer) do print(v) end
end		-- RunExampleOtherFormatter

-------------------------------------------------------------------------------
-- This is a text formatter example - it generates a C# function.
function ExampleTextFormatter(textFormatter, unitTesting)
	textFormatter.InitializeFormatter(scriptName, unitTesting)
	textFormatter.AddData("SIT", "02, 03, 04, 05")
	textFormatter.AddData("FIT", "25, 26, 27, 28")
	textFormatter.AddData("CITY", "32, 33, 34, 35")
	textFormatter.AddData("EIT", "42, 43, 44, 45")
	textFormatter.AddError("This is an error message test")
	return textFormatter.FinalizeBuffer()
end	--ExampleTextFormatter

-------------------------------------------------------------------------------
-- 
function RunExampleTextFormatter(textFormatter)
	local buffer = ExampleTextFormatter(textFormatter)
	print("\nResults:\n")
	for k,v in pairs(buffer) do print(v) end
end	-- RunExampleTextFormatter

-------------------------------------------------------------------------------
--
function RunAllExamples()
	print("\n-------------------------------------------------------------------------------")
	print("Standard XML formatter example:\n")
	RunExampleXmlFormatter()
	print("\n\n")

	print("\n-------------------------------------------------------------------------------")
	print("Custom extension of the XML formatter example:\n")
	RunExampleOtherFormatter(otherFormatter)
	print("\n\n")

	print("\n-------------------------------------------------------------------------------")
	print("Custom extension of the XML formatter with silly formatter example:\n")
	RunExampleOtherFormatter(sillyFormatter)
	print("\n\n")

	print("\n-------------------------------------------------------------------------------")
	print("Custom extension of the Text formatter used to generate C# code example:\n")
	RunExampleTextFormatter(textFormatter)
	print("\n\n")
end	-- RunAllExamples


-------------------------------------------------------------------------------
-- UNIT TESTS
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--
function GenerateFormatterOutputForComparison(buffer)
	local output = ""
	for _,line in pairs(buffer) do
		output = output .. line .. "\n"
	end
	return output
end	-- GenerateFormatterOutputForComparison

TestFormatters = {}

	---------------------------------------------------------
	-- XML Formatter Test
	---------------------------------------------------------
	function TestFormatters:testXmlFormatter()
		local expected = [[
<?xml version="1.0" encoding="us-ascii"?>
<!--This is the first comment-->
<!--This is the second comment-->
<!--Created by test_formatters.lua on SYSTEM-DATE-->
<RootNode>
	<County_Description>
		<state_code>26</state_code>
		<county_code>161</county_code>
		<description>Washtenaw</description>
	</County_Description>
	<County_Description>
		<state_code>39</state_code>
		<county_code>125</county_code>
		<description>Lucas</description>
	</County_Description>
	<School_Description>
		<state_code>39</state_code>
		<county_code>125</county_code>
		<school_code>1234</school_code>
		<description>Lucase CSD</description>
	</School_Description>
	<School_Description>
		<state_code>39</state_code>
		<county_code>002</county_code>
		<school_code>4223</school_code>
		<description>Bobbler CSD</description>
	</School_Description>
</RootNode>
]]
		luaunit.assertEquals(GenerateFormatterOutputForComparison(ExampleXmlFormatter(true)), expected)
	end
	
	---------------------------------------------------------
	-- Extended XML Formatter Test
	---------------------------------------------------------
	function TestFormatters:testOtherFormatter()
		local expected = [[
<?xml version="1.0" encoding="us-ascii"?>
<!--This is the first comment-->
<!--This is the second comment-->
<!--Created by test_formatters.lua on SYSTEM-DATE-->
<RootNode>
	<Location_Data>
		<location_code>25-126-625625</location_code>
		<tax_type>SIT</tax_type>
		<zipcode>48130</zipcode>
		<description>State Income, Michigan</description>
	</Location_Data>
	<Location_Data>
		<location_code>25-126-123123</location_code>
		<tax_type>SUI</tax_type>
		<zipcode>48103</zipcode>
		<description>Unemployement, Michigan</description>
	</Location_Data>
	<Location_Data>
		<location_code>25-115-645896</location_code>
		<tax_type>CITY</tax_type>
		<zipcode>48130</zipcode>
		<description>City Tax, Michigan</description>
	</Location_Data>
<ERROR>This is an error message test</ERROR>
</RootNode>
]]
		luaunit.assertEquals(GenerateFormatterOutputForComparison(ExampleOtherFormatter(otherFormatter, true)), expected)
	end

	---------------------------------------------------------
	-- Silly Extended XML Formatter Test
	---------------------------------------------------------
	function TestFormatters:testOtherFormatterSilly()
		local expected = [[
<?xml version="1.0" encoding="us-ascii"?>
<!--Silly as this is.-->
<!--This is my other formatter.-->
<!--Created by test_formatters.lua on SYSTEM-DATE-->
<RootyTootTootNode>
		<Bob_Data>
			<location_location>25-126-625625</location_location>
			<tax_type>SIT</tax_type>
			<zippyDoDa>48130</zippyDoDa>
			<description>State Income, Michigan</description>
		</Bob_Data>
		<Bob_Data>
			<location_location>25-126-123123</location_location>
			<tax_type>SUI</tax_type>
			<zippyDoDa>48103</zippyDoDa>
			<description>Unemployement, Michigan</description>
		</Bob_Data>
		<Bob_Data>
			<location_location>25-115-645896</location_location>
			<tax_type>CITY</tax_type>
			<zippyDoDa>48130</zippyDoDa>
			<description>City Tax, Michigan</description>
		</Bob_Data>
<ERROR>This is an error message test</ERROR>
</RootyTootTootNode>
]]
		luaunit.assertEquals(GenerateFormatterOutputForComparison(ExampleOtherFormatter(sillyFormatter, true)), expected)
	end

	---------------------------------------------------------
	-- Extended Text Formatter Test
	---------------------------------------------------------
	function TestFormatters:testTextFormattter()
		local expected = [[
// Generic tax code to applicable state code map
// Changes to this code should only be done via the generator.
// Code created by test_formatters.lua for STE version STE-VERSION on SYSTEM-DATE
// Generated genericTaxExemptionUseMap --START--
private readonly static Dictionary<string, List<string>> genericTaxExemptionUseMap = new Dictionary<string, List<string>>
{
	{"SIT", new List<string> { 02, 03, 04, 05 } },
	{"FIT", new List<string> { 25, 26, 27, 28 } },
	{"CITY", new List<string> { 32, 33, 34, 35 } },
	{"EIT", new List<string> { 42, 43, 44, 45 } },
// ERROR: This is an error message test
};
// Generated genericTaxExemptionUseMap --END--
]]
		luaunit.assertEquals(GenerateFormatterOutputForComparison(ExampleTextFormatter(textFormatter, true)), expected)
	end

-- END TestFormatters


-------------------------------------------------------------------------------
-- Main Script
-------------------------------------------------------------------------------


print("-------------------------------------------------------------------------------")
print("\nRunning Unit Tests\n")
luaunit.LuaUnit.run("-v")

print("\n\n")
print("-------------------------------------------------------------------------------")
io.write("Run Formatter Examples (Y/N)? ")
local ans = io.read()
if (string.upper(ans) == "Y") then 
	print("\n\nRunning Formatter Examples:\n")
	RunAllExamples()
end
