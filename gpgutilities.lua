-------------------------------------------------------------------------------
--
-- gpg Utilities : A collection of utilities for LUA scripts
-- All rights are reserved. Reproduction or transmission in whole or in part, in
-- any form or by any means, electronic, mechanical or otherwise, is prohibited
-- without the prior written permission of the copyright owner.
--
-------------------------------------------------------------------------------

local modname = ... 
local M = {}
M.private = {}	-- for unit testing access to private variables.
_G[modname] = M
package.loaded[modname] = M
setmetatable(M, {__index = _G})
setfenv(1, M)

require "lfs"


-- Meta information
-- _DESCRIPTION = "A collection of utilities for LUA scripts"
-- _VERSION = modname .. " 1.0.2"

-------------------------------------------------------------------------------
-- This file contains several sections that contain functions of similar uses
--
-- These sections are:
-- MISC FUNCTIONS
-- DEBUGGING FUNCTIONS
-- SQL FUNCTIONS
-- COLLECTIONS FUNCTIONS
-- STRINGS FUNCTIONS
-- DATE FUNCTIONS
-- FILE-DIRECTORY-BUFFER FUNCTIONS
-- TABLE FUNCTIONS
-- STE SPECIFIC FUNCTIONS

-- This is the delimiter strings and patterns for source update data files.
g_delimiterStartDataMinimumString = "---STARTDATA---"
g_delimiterStartDataPattern = "^[%-][%-][%-]+STARTDATA[%-][%-][%-]+$"

g_delimiterStopDataMinimumString = "---STOPDATA---"
g_delimiterStopDataPattern = "^[%-][%-][%-]+STOPDATA[%-][%-][%-]+$"


-------------------------------------------------------------------------------
-- DEBUGGING FUNCTIONS
-------------------------------------------------------------------------------


local g_showDebugMessages = false
-------------------------------------------------------------------------------
function SetShowDebugMessages(show)
	g_showDebugMessages = show
end	
function GetShowDebugMessages()
	return g_showDebugMessages
end
-------------------------------------------------------------------------------
-- DebugMessage
--
function DebugMessage(msg)
	if (not(g_showDebugMessages)) then return end
	
	print("DEBUG: " .. SafeString(msg))
end	-- DebugMessage


-------------------------------------------------------------------------------
-- MISC FUNCTIONS
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Removes all references to a module.
-- Do not call unrequire on a shared library based module unless you are 100% confidant that nothing uses the module anymore.
-- @param m Name of the module you want removed.
-- @return Returns true if all references were removed, false otherwise.
-- @return If returns false, then this is an error message describing why the references weren't removed.
--
function UnRequire(m)
	package.loaded[m] = nil
	_G[m] = nil
	 
	-- Search for the shared library handle in the registry and erase it
	local registry = debug.getregistry()
	local nMatches, mKey, mt = 0, nil, registry['_LOADLIB']
	 
	for key, ud in pairs(registry) do
		if type(key) == 'string' and type(ud) == 'userdata' and getmetatable(ud) == mt and string.find(key, "LOADLIB: .*" .. m) then
			nMatches = nMatches + 1
			if nMatches > 1 then
				return false, "More than one possible key for module '" .. m .. "'. Can't decide which one to erase."
			end
			mKey = key
		end
	end
	 
	if mKey then registry[mKey] = nil end
	 
	return true
end

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
	local args = {...}
	local flags = {}
	local flagsCount = 0

	if (#args == 1 and type(args[1]) == "table") then args = args[1] end

	for i = #args, 1, -1 do
		assert(type(args[i]) ~= "table", "You cannot include a table in a multiple argument parse request.")
		local flag = args[i]:match("^%-%-(.*)")
		if flag then
			flagsCount = flagsCount + 1
			local var,val = flag:match("([a-z_%-]*)=(.*)")
			if val then flags[var] = val else flags[flag] = true end
			table.remove(args, i)
		end
	end

	return flags, args, flagsCount
end	-- ParseFlags

-------------------------------------------------------------------------------
-- DisplayHack
-- Just a display hack to show processing action.
-- This function returns a function for the display spinner and keeps the count 
-- state internally.  If the returned function is called with a 'true' argument,
-- the value of the counter is returned, otherwise the display character is
-- cycled.
-- Example:
-- 	local spinner = DisplayHack()	-- Creates the function 
-- 	spinner()						-- Uses the function to cycle display character
-- 	local count = spinner(true)		-- Returns the value of the spinner count.
-- Arguments:
-- 		interval : 	A divisable by 4 interval for a complete sweep of the display spinner.
--								If interval is nil OR not divisible by 4, then the default interval of 1000 is used.
--
function DisplayHack(interval)
	local count = 0

	if (interval == nil) then interval = 1000 end
	if (math.mod(interval, 4) ~= 0) then interval = 1000 end
	local period = interval / 4

	M.private.period = period
	
	return function (showCount)
		if (showCount == true) then return count end
	
		local c = math.mod(count, interval)
		if (c == 0) then io.write("-\b") end
		if (c == period) then io.write("\\\b") end
		if (c == 2 * period) then io.write("|\b") end
		if (c == 3 * period) then io.write("/\b") end
		count = count + 1
	end
end -- DisplayHack

-------------------------------------------------------------------------------
-- ToInteger
--	Converts a string to an integer - if the string represents a floating point
--	number, the integer portion of the number is returned with no rounding.
--	An error is set if the conversion cannot be performed.
--
--	Arguments
--		str	:	The string to be converted.
--
--	Returns
--		Integer.
--
function ToInteger(str)
    return math.floor(tonumber(str) or error("Could not cast '" .. tostring(str) .. "' to number.'"))
end	-- ToInteger


-------------------------------------------------------------------------------
-- COLLECTIONS FUNCTIONS
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
-- PairsByKey
--	Returns pairs sorted accending by keys
--
--	Arguments
--		t	:	The table containing the data to sort.
--		f	:	A sorting function that will override the standard sort function.
--		
-- Returns
--	key, value in collection sorted by key accending
--
function PairsByKey(t, f)
	local a = {}
	for n in pairs(t) do a[#a + 1] = n end
	table.sort(a, f)
	local i = 0		-- iterator variable
	return function ()
		i = i + 1
		return a[i], t[a[i]]
	end
end	-- PairsByKey

-----------------------------------------------------------------------------
-- UniqueValueEvaluator
-- Maintains a collection of created from an arguement value and returns an 
-- indication if the value is unique to the collection.
-- The arguement values are added to the collection with an option to not added
-- the value.
--
-- Arguments:
--	val:	The value to be evalulated and added to the collection.
--	save:	A flag indicating the value is to be added to the collection.  If this
--				argument is missing, the value is automatically added.
--
-- Example Usage:
--		local gpg = require "gpgutilities"
--		local uvc = gpg.UniqueValueEvaluator()
--		local test1 = {1, 2, 3, 4, 5, 6}
--
--		for k, v in pairs(test1) do
--			if uvc(v) then print("unique") else print("duplicate") end
--		end
--
--		if (uvc(4)) then print("unique") else print("duplicate") end
--		if (uvc(8, false)) then print("unique") else print("duplicate") end
--
function UniqueValueEvaluator()
	local collection = {}
	
	return function (val, save)
		if (save == nil) then save = true end
		
		if (StringIsNilOrEmpty(SafeString(val))) then
			return false
		end
			
		assert(type(val) ~= "table", "A table can not be used as the argument.")

		for _,v in pairs(collection) do
			if v == val then return false end
		end
		if (save) then table.insert(collection, val) end
		return true
	end
end -- UniqueValueEvaluator

-----------------------------------------------------------------------------
-- UniqueSetEvaluator
-- Maintains a collection of keys created from the arguement values and returns an 
-- indication if the key is unique to the collection.
--
-- Arguments:
--	A collection of one or more values from which to generate and evaluate a key.
--
-- Example Usage:
--		local gpg = require "gpgutilities"
--		local usc = gpg.UniqueSetEvaluator()
--
--		if (usc("A", "B", 1)) then print "unique") else print("duplicate") end 	-- should print 'unique'
--		if (usc("A", "B", 2)) then print "unique") else print("duplicate") end 	-- should print 'unique'
--		if (usc("A", "B", 1)) then print "unique") else print("duplicate") end 	-- should print 'duplicate'
--
function UniqueSetEvaluator()
	local collection = {}
	
	return function (...)
		local data = {...}
		assert(type(data) == "table", "Cannot create a table from the provided variable arguments.")
		local key = ""
			
		for k,v in pairs(data) do
			assert(type(v) ~= "table", "At this time, an element of the set cannot be another set.")
				
			local val = SafeString(v)
			if not(StringIsNilOrEmpty(val)) then 
				if StringIsNilOrEmpty(key) then 
					key = val
				else
					key = key .. "-" .. val
				end
			end
		end
	
		DebugMessage("Key = " .. key)
		for k,v in pairs(collection) do
			if v == key then return false end
		end
		
		table.insert(collection, key)

		return true
	end
end -- UniqueSetEvaluator

-------------------------------------------------------------------------------
-- SetContainsValueEvaluator
-- Tests a contained set of values for the existence of a specified value.
-- The test value set is initialized during construction.
--
-- Arguements:
--	collection	:	A table containing the test values set.
--	val					:	The value to test the set for membership.
--
-- Returns:
--	true if the test set contains val; otherwise false.
--
-- Example Usage:
--		local ks = {"A", "B", "C", 1, 2, 3}
--
--		io.write("The test set is {")
-- 		for _,v in pairs(ks) do io.write(v .. ", ") end
-- 		print ("\b\b}\n")
--
-- 		local sck = gpg.SetContainsKeyEvaluator(ks)
--
-- 		local s = {"F", "A", 2, 8, "b", 1}
-- 		for _,v in pairs(s) do
	-- 		io.write("Testing " .. v .. " : ")
	-- 		if (sck(v)) then print("set contains") else print("set does not contain") end
-- 		end
--
function SetContainsValueEvaluator(collection)
	assert(type(collection) == "table", "The evaluator must be initialized with a table.")
	local col = collection
	
	return function(val)
		for _, v in pairs(col) do
			if (v == val) then return true end
		end
		return false
	end
end	-- SetContainsKeyEvaluator


-------------------------------------------------------------------------------
-- CalculateMaxStringLength
--	Calculates the maximum length of any of the strings in a collection.
--	Arguments
--		col	:	The collection to process.
--	Returns
--		The string length of the longer string in the collection.
--
function CalculateMaxStringLength(col)
	if (col == nil) then return 0 end

	local ml = 0
	for _,s in pairs(col) do
		local ls = string.len(tostring(s))
		ml = ml < ls and ls or ml
	end

	return ml
end	-- CalculateMaxStringLength


-------------------------------------------------------------------------------
-- STRINGS FUNCTIONS
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- FormatTitle
--	Formats a title and description into a pleasant block.
--
--	Arguments
--		title						: A collection of title text - must contain at least one title.
--		baseLineLength	: An optional length for the base title block string.
--											Defaults to 80 characters.
--
--	Returns
--		Formatted title text.
--	
function FormatTitle(titles, baseLineLength)
	assert(titles ~= nil and type(titles) == "table", "The titles collection must be a table.")
	if (baseLineLength == nil) then baseLineLength = 80 end

	local headerLine = string.rep("-", baseLineLength)
	local lEnd = "--|"
	local rEnd = "|--"
	local textLineLength = string.len(headerLine) - (string.len(lEnd) + string.len(rEnd))
	local rtn = "\n" .. headerLine .. "\n"

	for _,title in pairs(titles) do
		assert(string.len(title) <= textLineLength, "The title string length is greater than the base text line length of " .. textLineLength .. " characters.")
		local titlePaddingL = string.rep(" ", (textLineLength / 2 - ((string.len(title)) / 2)))
		local titlePaddingR = string.rep(" ", (textLineLength - (string.len(titlePaddingL) + string.len(title))))
		title = string.format("%s%s%s%s%s\n", lEnd, titlePaddingL, title, titlePaddingR, rEnd)
		rtn = rtn .. title
	end
	
	rtn = rtn .. headerLine .. "\n"

	return rtn
end	-- FormatTitle


-------------------------------------------------------------------------------
-- SplitString
-- Splits passed in string at indexing character
--
-- Arguments
--	str				: string to be split at indexChr
--	indexChr	: character used in string as a split point
--
-- Returns
--	s1	: first part of split string if successful
--	s2	: second part of split string if successful
--	*OR*
--	nil : if string can not be split
--
function SplitString(str, indexChr)
	if (str == nil) then return str end

	assert(indexChr, "The index character cannot be nil!")

	local s1, s2 = "", ""
	local splitIndex = string.find(str, indexChr, 1, "plain")		-- locate indexing character

	if (splitIndex ~= nil) then
		s1 = string.sub(str, 1, splitIndex - 1)
		s2 = string.sub(str, splitIndex + 1)
		
		s1 = string.gsub(s1, "^%s", "")
		s1 = string.gsub(s1, "%s*$", "")
		return s1, s2
	end

	return nil

end -- SplitString

-------------------------------------------------------------------------------
-- SplitStringAtFirstWhitespace
-- Splits passed in string at the first whitespace character
--
-- Arguments
--	str				: string to be split
--
-- Returns
--	s1	: first part of split string if successful
--	s2	: second part of split string if successful
--	*OR*
--	nil : if string can not be split
--
function SplitStringAtFirstWhitespace(str)
	if (str == nil) then return str end

	local s1, s2 = "", ""
	local splitIndex = string.find(str, "%s", 1)		-- locate indexing character

	if (splitIndex ~= nil) then
		s1 = string.sub(str, 1, splitIndex - 1)
		s2 = string.sub(str, splitIndex + 1)
		
		s1 = string.gsub(s1, "^%s", "")
		s1 = string.gsub(s1, "%s*$", "")
		return s1, s2
	end

	return nil

end -- SplitStringAtFirstWhitespace

-------------------------------------------------------------------------------
-- StringNilOrEmpty
-- Tests if a string is nil or empty
--
-- Arguments
--	str	:	string to test
--
-- Returns
--	true if str is nil or empty - false otherwise.
--
function StringIsNilOrEmpty(str)
	if (str == nil or str == "") then return true else return false end
end	-- StringIsNilOrEmpty

-------------------------------------------------------------------------------
-- StringStartsWith
-- Tests if a string starts with a target value.
--
-- Arguments
--	str			: string to test
--	target	: the target string.
---
-- Returns
--		true if str starts with target - false otherwise.
--
function StringStartsWith(str, target)
   return string.sub(str, 1, string.len(target)) == target
end	-- StringStartsWith

-------------------------------------------------------------------------------
-- StringEndsWith
-- Tests if a string ends with a target value.
--
-- Arguments
--	str			: string to test
--	target	: the target string.
--
-- Returns
--		true if str starts with target - false otherwise.
--
function StringEndsWith(str, target)
   return target == '' or string.sub(str, -string.len(target)) == target
end	-- StringEndsWith

-------------------------------------------------------------------------------
-- TrimString
-- Trims whitespace from the beginning and end of a string.
--
-- Arguments
--	str			: string to trim.
--
-- Returns
--		the trimmed string.
--
function TrimString(str)
	assert(type(str) == "string", "The source must be a string.")
	return string.gsub(str, "^%s*(.-)%s*$", "%1")
end	-- TrimString

----------------------------------------------------------------
-- FormatStateCode
--	Adds a leading zero to single digit state codes to insure that
--	all state codes are two digits.
--
function FormatStateCode(stateCode)

	DebugMessage("The provided state code is " .. stateCode)
	if (tonumber(stateCode) < 10 and string.len(stateCode) == 1) then
		return "0" .. stateCode
	else
		return stateCode
	end
end	-- FormatStateCode

-------------------------------------------------------------------------------
-- MakeStringTitleCase
-- From LUA String recipies - converts a string of words to Upper Case each word
-- NOTE : The words must be delimited in some fashion (space, etc)
--
-- Arguments
--	sourceStr	:	string to convert
--
-- Returns
--		sourceStr converted to titlecase (capitalize each word in the string)
--
function MakeStringTitleCase(sourceStr)
	local sourceStr = SafeString(sourceStr)

	local function tchelper(first, rest)
		return string.upper(first)..string.lower(rest)
	end
	-- Add extra characters to the pattern if you need to. _ and ' are found in the
	-- middle of identifiers and English words.
	-- We must lower the string first, otherwise Small Caps will be SMall CAps. 
	-- We must also put %w_' into [%w_'] to make it handle normal stuff and extra stuff the same.
	-- This also turns hex numbers into, eg. 0Xa7d4
	local str = string.gsub(string.lower(sourceStr), "(%l)([%w_']*)", tchelper)
	
	return str
	
end	-- MakeStringTitleCase

-------------------------------------------------------------------------------
-- SafeString
-- Insures that a string never is returned as nil - makes display programming
-- easier.
--
-- Arguments
--	sourceStr	:	string to make 'safe'
--
-- Returns 
--	string or empty string if sourceStr is nil
--
function SafeString(sourceStr)
	if (sourceStr == nill) then
		return ""
	else
		return tostring(sourceStr)
	end
end -- SafeString

-------------------------------------------------------------------------------
-- WordCount
-- Counts the number of words found in a string.
--
-- Arguements:
--	source	: The source string to be scanned.
--	word		: The word to be searched for.
--	plain		: true to run a plain search (default)
--						false to perform a regular expression search.
--
-- Returns:
--		The number of instances word is found in source.
--
function WordCount(source, word, plain)
	if (StringIsNilOrEmpty(source)) then return 0 end
		if (StringIsNilOrEmpty(word)) then return 0 end
	
	if plain == nil then plain = true end
	
	local count = 0
	local idx = 1
	while true do
		idx = string.find(source, word, idx, plain)
		if idx == nil then break end
		
		idx = idx + 1
		count = count + 1
	end
	
	return count
end

-------------------------------------------------------------------------------
-- CharacterCount
-- Counts the number of single characters found in a string.
-- Arguements:
--		source	: The source string to be scanned.
--		char		: The character to be searched for.
-- Returns:
--		The number of instances char is found in source.
function CharacterCount(source, char) 
	if (StringIsNilOrEmpty(source)) then return 0 end
	if (StringIsNilOrEmpty(char)) then return 0 end
	assert(string.len(char) == 1, "Character count requires a character not a string.")

	local count = 0 
	local bytechar = string.byte(char)
	for i = 1, #source do
		if string.byte(source, i) == bytechar then count = count + 1 end 
	end 

	return count
end


-------------------------------------------------------------------------------
-- DATE FUNCTIONS
-------------------------------------------------------------------------------


-- Matching expression to be used to test date string input for the format YYYYMMDD.
DateStringMatchExpression = "^[2][0][0-9][0-9][0,1][0-9][0,1,2,3][0-9]$"

-- Matching expression to be used to test STE date string input for the format YYYY-MM-DD
SteDateStringMatchExpression = "^[2][0][0-9][0-9]%-[0,1][0-9]%-[0,1,2,3][0-9]$"

-------------------------------------------------------------------------------
-- ValidateDateString
--	Tests a date string for proper formatting
--
--	Arguments
--		datestring		: The date string to be validated.
--		mexp					: The validation match expression to be used during validation.
--
--	Returns
--		true if the date string is correctly formatted; false otherwise.
--
function ValidateDateString(datestring, mexp)
	assert(not(StringIsNilOrEmpty(mexp)), "You must specify a match expression.")
	if (StringIsNilOrEmpty(datestring)) then return false end

	return string.match(datestring, mexp) ~= nil
end	-- ValidateDateString

-------------------------------------------------------------------------------
-- GetDateString
-- Returns the current date formatted YYYYMMDD
-- WARNING! This function uses OS commands directly!
--
function GetDateString()
	return os.date("%Y%m%d")
end	-- GetDateString

-------------------------------------------------------------------------------
-- DecrementDateString
-- Decrements a passed in date string (format YYYYMMDD) by one day.
-- Note : The month and day will be correct for the year, this is tested in this function.
-- WARNING! This function uses OS commands directly!
--
-- Arguments
--	str		:	Date string in the format YYYYMMDD
--	days	: The number of days to decrement - default is 1.
--
-- Returns
--		Date string decremented by one day in the format YYYYMMDD
--		1.  If passed in date string can not be processed, nil is returned. 
--
function DecrementDateString(str, days)

	if (not(ValidateDateString(str, DateStringMatchExpression))) then return nill end	-- [1]
	if (days == nil) then days = 1 end		-- Default
	days = ToInteger(days)

	local y = string.sub(str, 1, 4)	-- Spit the date string into components
	local m = string.sub(str, 5, 6)
	local d = string.sub(str, 7, 8)

	for i = 1, days, 1 do
		d = d - 1												-- Decrement the day ...
		if (d == 0) then
			m = m - 1											-- Decrement the month if have rolled past day == 1 - reset day to 31 (max possible numer of days in a month)
			d = 31												-- Test new day for correctness using the OS date / time functions
			while (os.date("*t", os.time{year=y, month=m, day=d, hour=0}).day ~= d) do	-- day is wrong, keep subtracting until correct (match)
				d = d - 1
			end
		end
		
		if (m == 0) then								-- Decrement the year if we have rolled past Jan and reset the month to Dec
			y = y - 1											-- No need to test - there is alway 12 months.
			m = 12
		end
																		-- Add leading zeros to day and month if necessary.
		if (string.len(m) == 1) then m = "0" .. m end
		if (string.len(d) == 1) then d = "0" .. d end
	end

	return y .. m .. d							-- Combine and return the decremented date string.

end	-- DecrementDateString


-------------------------------------------------------------------------------
-- FILE-DIRECTORY-BUFFER FUNCTIONS
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
-- CreateDirectory
-- Creates a new directory or overwrites an existing directory if requested.
-- WARNING! This function uses OS commands directly!
--
-- Arguments 
--	path	:	Path and name of directory to create.
--
-- Returns
--	true if directory is created successfully, false otherwise
--
function CreateDirectory(path)
	local rtn = 0
	local create = true
	local newDir = string.gsub(path, "/", "\\")	-- convert to DOS style directory paths

	io.write("Creating directory ... ")

	if (DirectoryExists(newDir)) then
		io.write("The directory:\n" .. newDir .. "\nalready exists!\nOverwrite? (Y/N): ")
		local ans = io.read()
		if (ans == "Y" or ans == "y") then
			rtn = os.execute("rd " .. newDir .. "/S/Q 2>NUL >NUL")
		else
			create = false	-- Do not attempt to create directory			
		end
	end
			
	if (create) then rtn = os.execute("mkdir " .. newDir .. " 2>NUL >NUL") end

	io.write("\n")
	return rtn == 0
end	-- CreateDirectory

-------------------------------------------------------------------------------
-- DirectoryExists
--	Checks to see if a directory exists.
--	WARNING! This function uses OS commands directly!
--
-- Arguments
--	dir	:	Directory to search for - must be FQN.
--
-- Returns
--	true if directory exists - false otherwise.
-- Requirements
--	This method will only work in Windows systems (afaik)
--
function DirectoryExists(dir)
	-- We must convert path into DOS style
	local cmd = "dir /AD ".. string.gsub(dir, '/', '\\' ).." 2>NUL >NUL"
	local rc = os.execute(cmd)
	return rc == 0
end	-- DirectoryExists

-------------------------------------------------------------------------------
-- FileExists
--	Checks to see if a file exists.
--
--	Arguments
--		fileName	:	FQN file name.
--
--	Returns
--		true if file exists; false otherwise.
--
function FileExists(fileName)
	if (StringIsNilOrEmpty(fileName)) then 
		return false end
	
	local f = io.open(fileName)
	if (f == nil) then 
		return false end
	
	io.close(f)
	return true
end	-- FileExists

-------------------------------------------------------------------------------
-- FindLastPathElement
--	Splits the last element in a path from the path - can be used to find the a filename
--	or last directory
--
--	Arguments
--		path	:	path containing elements to be split.
--
--	Returns
--		remainder :	Remainder of path.
--		last			:	Last element (directory or filename) in the path.
--
function FindLastPathElement(path)
	local remainder = ""
	local last= ""
	local dosPath = false

	if (string.find(path, "\\", 1, "plain") ~= nil) then dosPath = true end		-- If we have a DOS style path, remember this.

	path = string.gsub(path, "\\", "/")									-- Convert to UNIX style 

	if (string.sub(path, string.len(path)) == "/") then
		path = string.sub(path, 0, string.len(path) - 1)	-- Slice off the trailing '/' if it exists
	end

	while (path ~= nil) do
		local s1, s2 = SplitString(path, "/")
		if (s1 ~= nil) then
			remainder = remainder .. s1 .. "/"
			path = s2
		else
			last = path
			break
		end
	end

	if (dosPath) then remainder = string.gsub(remainder, "/", "\\") end		-- Convert to DOS style if required

	return remainder, last
end	-- FindLastPathElement

-------------------------------------------------------------------------------
-- CreateOutputFileName
-- 	Creates a filename string.
--
--	Arguments
--		filebase		: filename base and extension to use in the form name.ext
--		useDateStamp	: set 'true' if datestamp injection into filename is desired
--		injectionValue	: (optional) A string value to be injected into the filename between base name and datestamp/extention.
--
--	Returns
--		filename
--
function CreateOutputFileName(filebase, useDateStamp, injectionValue)
	if (StringIsNilOrEmpty(filebase)) then return filebase end

	local path = ""
	local fileName = filebase

	if (useDateStamp == true or injectionValue ~= nil) then
		filebase, path = RemoveDirectoryStructures(filebase)
		if (injectionValue ~= nil) then filebase = string.gsub(filebase, "%.", "_" .. injectionValue .. "%.", 1) end
		if (useDateStamp == true) then filebase = string.gsub(filebase, "%.", "_" .. GetDateString() .. "%.", 1) end
		fileName = path .. filebase
	end

	return fileName
end -- CreateOutputFileName

-------------------------------------------------------------------------------
-- CreateOutputFileNameFromSourceFileName
--	Creates an output filename from the source file name using the supplied extension.
--	Example: sourceFileName test.csv becomes test.sql if outputFileExtension is "sql"
--
--	Arguments
--		sourceFileName			:	The source file name.
--		outputFileExtension	:	The extension that is used when creating the output file name.
--
--	Returns
--		The output file name constructed.
--
function CreateOutputFileNameFromSourceFileName(sourceFileName, outputFileExtension)
	if (StringIsNilOrEmpty(sourceFileName) or StringIsNilOrEmpty(outputFileExtension)) then 
		return sourceFileName 
	end
	
	local filename, path = RemoveDirectoryStructures(sourceFileName)
	local f,e = SplitString(filename, ".")
	
	if (f == nil) then f = filename end
	
	return path .. f .. "." .. outputFileExtension
end	-- CreateOutputFileNameFromSourceFileName

-------------------------------------------------------------------------------
-- GetFileNames
--	Returns a list of filenames that match a pattern in the target directory.
--
--	Arguments
--		sourceDirectory	: The source directory to search.
--		fileNamePattern	: The file name pattern to target desired files (ie *.txt).
--		includePath			: If true, the source path is included in the file name (default)
--											otherwise, only the filename is stored.
--
--		NOTE: The fileNamePattern uses LUA pattern matching, not DOS filename wildcard.
--					See http://www.lua.org/pil/20.2.html for examples and instructions.
--
--	Returns: 
--		rtn							:	A collection of filenames in sourceDirectory that match fileNamePattern.
--		sourceDirectory	:	The fully qualified path to the source directory where the target files were found.
--											This can be used to generate to be used to generate a fully qualified filename (FQN)
--
function GetFileNames(sourceDirectory, fileNamePattern)
	local rtn = {}
	
	if (includePath == nil) then includePath = true end

	if (StringIsNilOrEmpty(fileNamePattern)) then fileNamePattern = ".+" end

	if (StringIsNilOrEmpty(sourceDirectory)) then sourceDirectory = lfs.currentdir() end

	if (not(string.match(sourceDirectory, "^%a:\\?.+"))) then 
		sourceDirectory = lfs.currentdir() .. "\\" .. sourceDirectory
	end
	
	DebugMessage("Pattern  : " .. fileNamePattern)
	DebugMessage("SourceDir: " .. sourceDirectory)
	
	if (not(DirectoryExists(sourceDirectory))) then
		print("ERROR - The provided source directory " .. sourceDirectory .. " does not exist!")
		return rtn
	end
	
	local lastDir = lfs.currentdir()	-- Save the current working directory for restoration.
	lfs.chdir(sourceDirectory)
	
	for file in lfs.dir(sourceDirectory) do
			if lfs.attributes(file,"mode") == "file" then
				if (string.match(file, fileNamePattern)) then table.insert(rtn, file) end
			end
	end

	lfs.chdir(lastDir)	-- Restore the current working directory.

	return rtn, sourceDirectory
end		-- GetFileNames

-------------------------------------------------------------------------------
-- RemoveDirectoryStructures
--	Removes any directory structures from the provided filebase string.
--
--	Arguments
--		filebase	:	The file path and name string to be operated on.
--
--	Returns
--		filename	: The name of the file processed from filebase.
--		path			: The directory structure processed from filebase.
--
function RemoveDirectoryStructures(filebase)
	local path = ""

	if (not(StringIsNilOrEmpty(filebase))) then
		repeat
			local s,e = string.find(filebase, ".+/", 1)
			if (s ~= null) then
				path = path .. string.sub(filebase, s, e)
				filebase = string.sub(filebase, e + 1)
			end
		until (s == null)
	end

	return filebase, path
end	-- RemoveDirectoryStructures

-------------------------------------------------------------------------------
-- DumpBufferToFile
--	Dumps buffer table to file.
--
--	Arguments
--		filebase			: filename base and extension to use in the form name.ext
--		buffer				: table containing items to write to file
--		useDateStamp	: set 'true' if datestamp injection into filename is desired
--		createNewFile	: set 'true' if a new file is desired
--		hideMessage:	: set 'true' to hide the lines saved to file message.
--
--	Requires 
--		CreateOutputFileName function
--
function DumpBufferToFile(filebase, buffer, useDateStamp, createNewFile, hideMessage)
	if (buffer == nil) then return end
	if (hideMessage == nil) then hideMessage = false end

	local attrib = "a"
	if (createNewFile == true) then attrib = "w" end		-- Create a new file if requested

	local count		= table.getn(buffer)
	local fileName	= CreateOutputFileName(filebase, useDateStamp)

	if (count > 0) then																-- If we have buffer data - process to file
		local f = assert(io.open(fileName, attrib))
		if (not(hideMessage)) then io.write("\nSaving " .. count .. " lines to file...") end
		for i = 1, count do assert(f:write(buffer[i], "\n")) end		
		assert(f:close())
		if (not(hideMessage)) then io.write(" Done!\n") end
    else
        if (not(hideMessage)) then io.write("No lines in the buffer.\n") end
	end

end -- DumpBufferToFile

-------------------------------------------------------------------------------
-- DumpStringToFile - 
--	Dumps string to datestamped file with filebase filename.
--
-- 	Arguments
--		filebase			: filename base and extension to use in the form name.ext
--		text					: text to write to file
--		useDateStamp	: set 'true' if datestamp injection into filename is desired
--		createNewFile	: set 'true' if a new file is desired
--
--	Requires
--		CreateOutputFileName function
--
function DumpStringToFile(filebase, text, useDateStamp, createNewFile)
	if (text == nil) then return end

	local attrib = "a"
	if (createNewFile == true) then attrib = "w" end		-- Create a new file if requested

	local fileName = CreateOutputFileName(filebase, useDateStamp)

	f = assert(io.open(fileName, attrib))
	assert(f:write(text, "\n"))
	assert(f:close())
end -- DumpStringToFile

-------------------------------------------------------------------------------
-- DumpFileToBuffer
--	Dumps a text file to a buffer table
--
--	Arguments
--		filename					: FQN filename of file for input
--		allowBlankLines	  :	true to allow blank lines / false to remove them
--		existingBuffer		: an existing buffer to append data to - if nil then a new buffer is used.
--		removeHeaderLines :	set to the number of header lines to remove - 0 or nil removes no lines.
--		honorLuaBlocks		: If true, then lua text continuation blocks are honored if the following are true:
--												The first line in the block must end with the start block indicator '[['
--												The last line in the block must only contain the end block indicator ']]'
--												i.e. 
--												text = [[
--												this is the first line in the block
--												this is the second line in the block
--												]]
--
--	Returns
--		buffer table of file contents or nil
--
function DumpFileToBuffer(filename, allowBlankLines, existingBuffer, removeHeaderLines, honorLuaBlocks)
	if (filename == "" or filename == nil) then return nil end

	if (removeHeaderLines == nil) then removeHeaderLines = 0 end

	local buffer = {}
	if type(existingBuffer) == "table" then buffer = existingBuffer end

	if (honorLuaBlocks == nil) then honorLuaBlocks = false end

	local f = io.open(filename, "r")

	if (f == nil) then return nil end

	while (true) do
		local line = f:read("*line")
		
		if (line == nil) then break end

		if (removeHeaderLines > 0) then
			removeHeaderLines = removeHeaderLines - 1
		else
            line = TrimString(SafeString(line))
			if (line ~= "" or allowBlankLines == true) then
				
				if (honorLuaBlocks and string.match(line, ".%[%[$")) then
					DebugMessage("Found a LUA block")
					local mid = ""
					while (mid ~= "]]") do
						mid = f:read("*line")
						line = line .. mid
					end
				end

				table.insert(buffer, line)
			end
		end
	end

	f:close()

	return buffer
end	-- DumpFileToBuffer

-------------------------------------------------------------------------------
-- DumpCsvFileToTable
--	Dumps a CSV text file to a buffer table.
--	The source file must be structured to have 0 or 1 header lines.  The header 
--	line can be used to name the field data constructed from the source file and
--	must contain a value for each data entry.
--
--	Arguments
--		filename						: FQN filename of file for input.
--		useHeaderForFields	:	If true uses the first header line text for field names.
--		removeHeader				: If true removes the first line from the file from processing.
--													This is useful for a file that has a header that is not used for field naming.
--	Returns
--		buffer table of file contents or nil
--		number of records loaded.
--
function DumpCsvFileToTable(filename, useHeaderForFields, removeHeader)
	local headerFields = nil
	local spinner = DisplayHack()
	local data = {}

	local headerLinesToBeRemoved = 0
	if (not(useHeaderForFields) and removeHeader) then headerLinesToBeRemoved = 1 end

	local source = DumpFileToBuffer(filename, false, nil, headerLinesToBeRemoved)

	if (source == nil) then return nil, 0 end								-- No data to be operated on, bail now.

	for k,v in pairs(source) do
		spinner()
		local record = CSVStringToTable(v)

		if (useHeaderForFields and spinner(true) == 1) then		-- Save the header names for named field record creation.
			headerFields = record
		else
			if (headerFields ~= nil) then												-- Create a named field record
				local t = {}
				for idx,header in pairs(headerFields) do
					if (not(StringIsNilOrEmpty(header))) then 			-- If there is no header for this field ignore it.
						t[header] = record[idx] 
					end
				end
				
				record = t
			end

			table.insert(data, record)													-- Add our created record to our table.
		end
	end

	return data, spinner(true)
end	-- DumpCsvFileToBuffer

-------------------------------------------------------------------------------
-- SelfFlushingOutputBuffer
--	Creates a self flushing output buffer - once the buffer size hits the threshold
--	value, the buffer is flushed to file and reset.
-- Arguments:
--		threshold:	The number of buffer lines stored before the buffer is flushed to file.
--		fileName:		The base name of the output file.
--		useDateStamp	: set 'true' if datestamp injection into filename is desired
--		createNewFile	: set 'true' if a new file is desired - this only applies to the 
--										initial buffer flush, subsequent flushes are appended.
--
function SelfFlushingOutputBuffer(threshold, fileName, useDateStamp, createNewFile)
	local buffer = {}
	local threshold = threshold
	local fileName = fileName
	local useDateStamp = useDateStamp
	local createNewFile = createNewFile
	
	assert(threshold > 0, "The buffer dump threshold is zero or less - this makes NO SENSE")

	function Flush()
		DumpBufferToFile(fileName, buffer, useDateStamp, createNewFile, true)
		buffer = {}
	end	-- Flush

	return function (line)
		if (StringIsNilOrEmpty(line)) then
			Flush()
			return
		end
		table.insert(buffer, line)
		if (#buffer > threshold) then
			Flush()
			if (createNewFile) then createNewFile = false end
		end
	end
end	--OutputBuffer


-------------------------------------------------------------------------------
-- TABLE FUNCTIONS
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- containsKey
--	Extension method to table 
--	Returns 
--		true if supplied table contains the target key.
--
function table.containsKey(tbl, key)
	assert(tbl == nil or type(tbl) == "table", "The table argument must be nil or a table.")
	if (tbl == nil) then return false end
	for k, _ in pairs(tbl) do
		if k == key then return true end
	end
	return false
end	-- table.containsKey

-------------------------------------------------------------------------------
-- containsValue
--	Extension method to table 
--	Returns 
--		true if supplied table contains the target value.
--
function table.containsValue(tbl, val)
	assert(tbl == nil or type(tbl) == "table", "The table argument must be nil or a table.")
	if (tbl == nil) then return false end
	for _, v in pairs(tbl) do
		if (v == val) then return true end
	end
	return false
end	-- table.containsValue

-------------------------------------------------------------------------------
-- Keys
--	Extention method to table
--	Returns
--		A collection containing the keys to a table.
function table.Keys(tbl)
	assert(tbl ~= nil and type(tbl) == "table", "The table argument must be nil or a table.")
	local keys = {}
	for k,_ in pairs(tbl) do
		table.insert(keys, k)
	end
	return keys
end		-- table.Keys


-------------------------------------------------------------------------------
-- Count
--  Extension method to return the length of a table.
--
function table.Count(tbl)
    assert(tbl ~= nil and type(tbl) == "table", "The table arguments must be nil or a table")
    local count = 0
    for k, _ in pairs(tbl) do
        count = count + 1
    end
    return count
end
-------------------------------------------------------------------------------
-- addRange
--	Extension method to table 
--	Adds the records from the additions table to tbl.
--
function table.addRange(tbl, additions)
	assert(tbl ~= nil and type(tbl) == "table", "Destination table must be a table.")
	assert(additions ~= nil and type(additions) == "table", "Additions table must be a table.")
	
	for _,v in pairs(additions) do
		table.insert(tbl, v)
	end
end	-- table.addRange

-------------------------------------------------------------------------------
-- addToSet
function table.addTo(tbl, key, data)
	assert(tbl ~= nil, "The provided table can not be nil.")
	assert(not(StringIsNilOrEmpty(key)), "The provided key can not be nil.")
    tbl[key] = data
end

-------------------------------------------------------------------------------
-- CSVStringToTable
--	Converts a comma delimited string of values into a table of values.
--
--	Arguments
--		str	: string containing comma separated values to be extracted.
--
--	Returns
--		table of values.
--
--	Requires
--		DelimitedStringToTable function
--
function CSVStringToTable(str)
	return DelimitedStringToTable(str, ",")
end	-- CSVStringToTable

-------------------------------------------------------------------------------
-- DelimitedStringToTable
--	Converts a character delimited string of values into a table of values.
--
--	Arguments
--		str				: string containing delimiter separated values to be extracted.
--		delimiter	: The delimiter character - must be a single character.
--
--	Returns
--		table of values
--
--	Requires
--		SplitString function
--
function DelimitedStringToTable(str, delimiter)
	assert(type(str) == "string", "The source must be a string.")
	assert(string.len(delimiter) == 1, "The delimiter must be a single character.")

	local tbl = {}
	
	while (str ~= nil) do
		local s1,s2 = SplitString(str, delimiter)
		
		if (s1 ~= nil) then 
			table.insert(tbl, s1)
			str = s2
		else
			table.insert(tbl, str)
			break
		end
	end
	
	return tbl
end	-- DelimitedStringToTable


-------------------------------------------------------------------------------
-- STE SPECIFIC FUNCTIONS
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
-- GetPreviousPackageDirectory
--	Gets the first previous STE release analysis package directory from the passed in directory specification.
--
--	Arguments
--		currentPath : FQN path specifying a STE release analysis package location.
--
--	Returns
--		The first previous existing STE release analysis package path (FQN)
--
function GetPreviousPackageDirectory(currentPath)
	local prevDumpDir = PREVIOUS_PACKAGE_LOCATION
	if (DirectoryExists(prevDumpDir)) then return prevDumpDir end
	
	io.write("\ncurrentPath = " .. currentPath .. "\n")
	if (string.find(currentPath, STE_CURRENT_VERSION, 1, "plain") ~= nil or string.find(currentPath, STE_PREVIOUS_VERSION, 1, "plain") ~= nil ) then		-- if version specific packages are not available, try locating a datestamped one.
		currentPath = gpg_STE_DBDUMP .. "stedbdump_" .. GetDateString() .. "/"
	end
	io.write("\ncurrentPath = " .. currentPath .. "\n")

	local dosPath = false															-- If we have a DOS style path, remember this.
	if (string.find(currentPath, "\\", 1, "plain") ~= nil) then dosPath = true end		

	currentPath = string.gsub(currentPath, "\\", "/")	-- Convert to UNIX style 
	
	local path, pkg = FindLastPathElement(currentPath)
	local newDir
	
	print("path = " .. path .. " package = " .. pkg)

	local s1, s2 = SplitString(pkg, "_")
	repeat
		s2 = DecrementDateString(s2)
		newDir = path .. s1 .. "_" .. s2
	until (DirectoryExists(newDir))

	newDir = newDir .. "/"												-- Add trailing UNIX style path delimiter 
	if (dosPath) then newDir = string.gsub(newDir, "/", "\\") end		-- Convert to DOS style if required
	
	return newDir
end

-------------------------------------------------------------------------------
-- GetCurrentPackageDirectory
--	Gets the current directory that analysis packages or other data files will be stored in.  
--	Starts search with a package directory that is denoted in 'directory'.  Will attempt to
--	either create the directory (if specified and the directory does not exist) or will attempt
--	to get a previous package directory.
--
--	Arguments
--		directory : Directory to start search.
--		createIfDoesNotExist : Create the package directory if it does not exist.
--
--	Returns
--		FQN to the current package directory
--
function GetCurrentPackageDirectory(directory, createIfDoesNotExist)
	local curDir = directory

	if (not(DirectoryExists(curDir))) then
		if (createIfDoesNotExist) then
			CreateDirectory(curDir)
		else
			curDir = GetPreviousPackageDirectory(curDir)		
		end			
	end

	assert(curDir ~= nil)

	return curDir
end	-- GetCurrentPackageDirectory


-------------------------------------------------------------------------------
-- SQL FUNCTIONS
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
-- DumpSqliteDbSchema
--	Dumps an Sqlite database schema to file.
--	WARNING! This function uses OS commands directly!
--
--	Arguments
--		dbFile					: Name of database file to dump - MUST be in FQN DOS path format (c:\\ \\ \\)
--		dbSchemaFile		:	Name of schema file schema data is saved to - MUST be in FQN Unix path format (c:/ / /)
--		sqlToolsApp			: FQN path and name of Sqlite3 executable file - MUST be in FQN DOS path format (c:\\ \\ \\)
--		sqlToolsScript	:	Name of script file to be created and fed to sqlToolsApp for processing - MUST be in FQN DOS path format (c:\\ \\ \\) 
--
--	Returns						
--		0 if successful, 1 otherwise
--
-- Requirements
--		Sqlite3.exe available on the system for use.
--
function DumpSqliteDbSchema(dbFile, dbSchemaFile, sqlToolsApp, sqlToolsScript)
	-- First lets make sure our paths are in the required format
	dbFile = string.gsub(dbFile, "/", "\\")										-- convert to DOS style 
	dbSchemaFile = string.gsub(dbSchemaFile, "\\", "/")				-- convert to UNIX style
	sqlToolsApp = string.gsub(sqlToolsApp, "/", "\\")					-- convert to DOS style 
	sqlToolsScript = string.gsub(sqlToolsScript, "/", "\\")		-- convert to DOS style 

	-- Create script for Sqlite3 to process and save to file - NOTE The path name MUST be Unix Style!
	local dumpDbCommands = ".schema\n.output " .. dbSchemaFile .. "\n.schema\n.quit\n"
	io.write("Saving SQLite3 command script to file " .. sqlToolsScript .. "\n")
	local f = assert(io.open(sqlToolsScript, "w"))
	f:write(dumpDbCommands)
	f:close()

	io.write("Dumping database schema ... " .. "\n")
	rtn = os.execute(sqlToolsApp .. " " .. dbFile .. " < " .. sqlToolsScript)

	-- io.execute("erase " .. sqlToolsScript)

	return rtn
end -- DumpSqliteDbSchema

-------------------------------------------------------------------------------
-- FixStringForSql
--	Makes a string correct for SQL table use by ...
--		1. Changes nil item to empty string.
--		2. Changes single quote (') to two single quotes ('')
--
--	Arguments
--		text item
--
--	Returns
--		text item corrected as necessary
--
function FixStringForSql(item)
	if (item == nil) then item = "" end
	item = string.gsub(item, "'", "''")
	return item
end	-- FixStringForSql

-------------------------------------------------------------------------------
-- SqlStringHasStupidData
--	Yes the function call says it all ... these datafiles are littered with dumb data faux-pas such as
--	O'Brian, Land 'O' Lakes, Long Point 'SD', Will-'-the-Wisp Camp, and my personal favorite, Merle K 'Mudhole' Smith Airport.
--
--	Finally had to create this function to keep up with the matching patterns to detect these.
--
--	Arguments
--		formatted string that contains an SQL insert statement.
--
--	Returns
--		true if sql string is detected as containing stupid data constructions - false otherwise
--
function SqlStringHasStupidData(sql)
local patterns = {"%a'%a.", "'*%a+'%s", "%a+'',", "%p'%p"}

	for k, pattern in pairs(patterns) do
		if (string.find(sql, pattern, 1)) then return true end
	end
	
	return false		
end	-- SqlStringHasStupidData
