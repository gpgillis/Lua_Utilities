-- This is a test for accessing an Excel sheet from LUA
-- GPG 20150107

require "luacom"


local excel = luacom.CreateObject("Excel.Application")
assert(excel)

l_workbookName = "c:/lua/misc_experiments/xls_reader_tests/testdata.xlsx"

local book = excel.Workbooks:Open(l_workbookName)
excel.Visible = true

local sheets = book.Worksheets

print(type(sheets) .. " number of worksheets is " .. #sheets)

print("Iterating through the available worksheets via luacom.pairs .. ")
for _,ws in luacom.pairs(sheets) do
	print(type(ws))
	print ("Worksheet : " .. ws.Name)
end

print("Iterating through the available worksheets via luacom.GetEnumerator .. ") 
local worksheets_enum = luacom.GetEnumerator(sheets)

print ("iterator count : " .. #worksheets_enum)

local sheet = worksheets_enum:Next()
while sheet do
	print ("Worksheet via enumerator = " .. sheet.Name)
	print("Let's see what value is stored in the first cell in the " .. sheet.Name .. " worksheet .. ")
	local vals = sheet.Cells(1, 1)
	if (vals.Value2 ~= nil) then 
		print ("The value at A1 is " .. vals.Value2)
	else
		print ("There is no value at A1")
	end
	
	sheet = worksheets_enum:Next()
end


print("OK - lets grab some data from the SecondSheet .. ")

local sheet2 = book.Worksheets("SecondSheet")
if (sheet2) then
	local cols = sheet2.Columns
	print(type(cols))
	print(#cols)
	for i = 1, 10 do
		local val = sheet2.Cells(i)
		if (val.Value2 ~= nil) then print("The value at " .. i .. " is " .. val.Value2) else print("No value found at " .. i .. "!") end
	end 
end


book:Close()


print("Now lets try to create, populate and save a workbook .. ")


-- An example usage from stack overflow:
book  = excel.Workbooks:Add()
sheet = book.Worksheets(1)
sheet.Name = "Our First Sheet"

local maxRow = 30
local maxCol = 10

for row=1, maxRow do
  for col=1, maxCol do
    sheet.Cells(row, col).Value2 = math.floor(math.random() * 100)
  end
end

local range = sheet:Range("A1")

for row=1, maxRow do
  for col=1, maxCol do
    local v = sheet.Cells(row, col).Value2

    if v > 50 then
        local cell = range:Offset(row-1, col-1)

        cell:Select()
        excel.Selection.Interior.Color = 65535
    end
  end
end


book:SaveCopyAs("c:/lua/misc/autopop.xls")
book:Close(false)

excel.DisplayAlerts = false
excel:Quit()
excel = nil


print ("Mas Fina - Mahalo .. ")
