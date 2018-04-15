-------------------------------------------------------------------------------
-- References:
-- https://github.com/harningt/luajson
-- https://matthewwild.co.uk/projects/luaexpat/manual.html#introduction
-- https://matthewwild.co.uk/projects/luaexpat/examples.html
-- https://matthewwild.co.uk/projects/luaexpat/examples.html

require "lxp"
local gpg = require "gpgutilities"
local inspect = require "inspect"

local jse = require "json.encode"
local jsd = require "json.decode"

-------------------------------------------------------------------------------
--
function ParseTheXml()
	local count = 0
	callbacks = {
			StartElement = function (parser, name)
					io.write("+ ", string.rep(" ", count), name, "\n")
					count = count + 1
			end,
			EndElement = function (parser, name)
					count = count - 1
					io.write("- ", string.rep(" ", count), name, "\n")
			end
	}

	callbacksWithText = {
			StartElement = function (parser, name)
					io.write("+ ", string.rep(" ", count), name, "\n")
					count = count + 1
			end,
			EndElement = function (parser, name)
					count = count - 1
					io.write("- ", string.rep(" ", count), name, "\n")
			end,
			CharacterData = function (parser, string)
					if (gpg.StringStartsWith(string, "\n")) then return end
					io.write("* ", string.rep(" ", count), string, "\n")
			end
	}

	local t = {}

	p = lxp.new(callbacksWithText)

	local data = gpg.DumpFileToBuffer("testdata.xml", false, nil, 0, false)


	print ("Parsing a table of xml data lines.")
	for _,l in pairs(data) do  -- iterate lines
			p:parse(l)          -- parses the line
	end
	p:parse()               -- finishes the document
	p:close()               -- closes the parser



	local datatext = [[
<calculation_data>
	<client><id>FIRM</id>
		<description></description>
		<do_not_combine_state_unemployment_tax>1</do_not_combine_state_unemployment_tax>
		<tax_jurisdictions>
			<tax_jurisdiction>
				<tax_jurisdiction_key>1</tax_jurisdiction_key>
				<description>Federal</description>
				<tax_jurisdiction_type>Federal</tax_jurisdiction_type>
				<ste_state_code>00</ste_state_code>
				<suta_base_rate>0.0000</suta_base_rate>
				<suta_supplemental_rate>0.0000</suta_supplemental_rate>
			</tax_jurisdiction>
			<tax_jurisdiction>
				<tax_jurisdiction_key>2</tax_jurisdiction_key>
				<description>Michigan</description>
				<tax_jurisdiction_type>State</tax_jurisdiction_type>
				<ste_state_code>26</ste_state_code>
				<has_nexus>1</has_nexus>
				<suta_base_rate>0.0000</suta_base_rate>
				<suta_effective_date>2009-01-01T00:00:00</suta_effective_date>
				<reimburse_suta_charges>0</reimburse_suta_charges>
				<use_alternate_suta_wage_limit>0</use_alternate_suta_wage_limit>
				<use_illinois_suta_fixed_rate>0</use_illinois_suta_fixed_rate>
				<suta_supplemental_rate>0.0000</suta_supplemental_rate>
			</tax_jurisdiction>
		</tax_jurisdictions>
	</client>
</calculation_data>
	]]

	print("\nTrying with p2 parser.")
	local p2 = lxp.new(callbacksWithText)
	p2:parse(datatext)
	p2:parse()
	p2:close()

end		-- ParseTheXml

-------------------------------------------------------------------------------
--
function EncodeTheJson(o)

	if (o == nil) then 
		o = {
		["bob"] = "BigKitty",
		["bikes"] = { ["yamaha"] = "scooterbike", ["triumph"] = "sled", ["harley"] = "blu" },
		["pudge"] = "PudgyKitty",
		["herm"] = "BitchyKitty",
		["kosh"] = "PussPuss",
		["alie"] = "StretchyKitty"
	}
	end

	print(inspect(o))

	local j = jse.encode(o)

	print (j)
	return j

end	-- ParseTheJson

-------------------------------------------------------------------------------
--
function DecodeTheJson()
	
	--local filename = "sampleData.json"
	local filename = "studentData.json"

	local f = io.open(filename, "r")

	if (f == nil) then return nil end

	local data = ""
	
	while (true) do
		local line = f:read("*line")
		
		if (line == nil) then break end
		data = data .. line
	end
	
	print("Decoding the json!")
	
	local o = jsd.decode(data)
	
	print(inspect(o))
	
	return o
	
end		-- DecodeTheJson

-------------------------------------------------------------------------------
--
function InspectTest()
	local t = {1,2,3}
	local mt = {b = 2}
	setmetatable(t, mt)

	local remove_mt = function(item)
		if item ~= mt then return item end
	end

	print(inspect(t))
	print(inspect(t, {process = remove_mt}))
	
	-- mt does not appear
	-- assert(inspect(t, {process = remove_mt}) == "{ 1, 2, 3 }")
end		-- InspectTest

-------------------------------------------------------------------------------
-- MAIN Script
-------------------------------------------------------------------------------

local o = DecodeTheJson()
local j = EncodeTheJson(o)

-- InspectTest()
