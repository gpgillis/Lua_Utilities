-------------------------------------------------------------------------------
-- XLS Reader Test
--	Test fixture for the xlsreader.lua module
-------------------------------------------------------------------------------

local xls = require "XLSReader"

local g_workbookName = "c:/lua/misc_experiments/xls_reader_tests/testdata.xlsx"
local g_worksheetName = "FirstSheet"
--local g_xlsFields = {"State Name", "State Code", "Rate", "Effective Date", "BobColumn", "StartRun", "EndRun"}
local g_xlsFields = {"State Name", "State Code", "Rate", "Effective Date", "StartRun", "EndRun"}

-------------------------------------------------------------------------------
-- DebugDumpBuffer
--	A debugging method that dumps out the buffer collections.
-- Arguments
--	buffer							: The buffer being dumped to display.
--	fields							: The fields collection for the provided data (if you want the display in that order)
--												If fields is nil, buffer is simply dumped on field , value basis.
--
function DebugDumpBuffer(buffer, fields)

	for _,rec in pairs(buffer) do
		if (fields ~= nil) then
			for _,field in pairs(fields) do
				io.write("\t" .. field .. " = " .. rec[field] .. "\n")
			end
		else
			for field,val in pairs(rec) do
				io.write("\t" .. field .. " = " .. val .. "\n")
			end
		end
		print()
	end
end	--DebugDumpBuffer

-------------------------------------------------------------------------------
-- MAIN SCRIPT 
-------------------------------------------------------------------------------

print("Testing the XLS Reader module ...")

--xls.SetMaxRows(10)
--xls.SetRequireAllFieldsIndexed(false)
--xls.SetEndLoadingOnFirstBlankRowFound(false)
--xls.SetShowDebugMessages(true)

xls.AddFieldNames(g_xlsFields)
local buffer = xls.ReadXlsFile(g_workbookName, g_worksheetName)

xls.SetShowDebugMessages(false)

print ("\nNow we will display the data that we have loaded ... ")
DebugDumpBuffer(buffer, g_xlsFields)
