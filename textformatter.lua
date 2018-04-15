-------------------------------------------------------------------------------
-- Text Formatter 
-- A helper utility to assist in formatting data into text file (usually code).
-- This utility will generate simple text nodes based on a provide node format and
-- a set of data strings. The compiled data can then be retrieved as a table of strings
-- which then can be saved as a file or manipulated further.
--
-- GPG 20110615
--
-- Meta information
-- _DESCRIPTION = "A utility to assist in text formatting of data."
-- _VERSION = modname .. " 1.0.0"
-------------------------------------------------------------------------------
--
-- Example:
--
-------------------------------------------------------------------------------

local gpg = require "gpgUtilities"
local assert = assert
local table = table
local type = type
local pairs = pairs
local string = string
local unpack = unpack
local print = print

local modName = ...
print("Loading " .. modName)
module(modName)

local nodeFormat = ""
local namedNodeFormats = {}
local rootNodeName = ""
local buffer = {}
local bufferFinalized = false

-------------------------------------------------------------------------------
-- SetNodeFormat
--	Sets the node format string.
--
--	Arguments
--		fmt		:	The node format string.
--		show	: If true - the node format is displayed to stdio.
--
function SetNodeFormat(fmt, show)
	if (show) then print("Setting node format with : " .. fmt) end
	nodeFormat = fmt
end	-- SetNodeFormat

-------------------------------------------------------------------------------
-- InitializeBuffer
-- Intializes the buffer with header information.
-- Arguments
--		rootNode		: The name of the root node in the file.
--		comment			: One or more comment strings to be added to the file header - more than one string requires a table.
function InitializeBuffer(rootNode, comments)
	assert(not(gpg.StringIsNilOrEmpty(rootNode)), "Root node name is empty and should not be.")
	rootNodeName = rootNode
	
	buffer = nil		-- Make sure the buffer is cleared and prepared for use.
	buffer = {}
	bufferFinalized = false
	
	if type(comments) == "table" then
		for k, v in pairs(comments) do
			if not(gpg.StringIsNilOrEmpty(v)) then
				table.insert(buffer, string.format("// %s", v))
			end
		end
	else
		if not(gpg.StringIsNilOrEmpty(comments)) then
			table.insert(buffer, string.format("// %s", comments))
		end
	end
	
	table.insert(buffer, string.format("// %s --START--", rootNodeName))
end	-- InitializeBuffer

-------------------------------------------------------------------------------
-- AddNamedFormat
-- Adds a node format to a format collection.
-- Arguments
--		formatName		: Name of the format.
--		formatSpec		: Format specification.
function AddNamedFormat(formatName, formatSpec)
	assert((not(gpg.StringIsNilOrEmpty(formatName)) and not(gpg.StringIsNilOrEmpty(formatSpec))), "Format name and specification cannot be empty.")
	namedNodeFormats[formatName] = formatSpec
end	-- AddNamedFormat

-------------------------------------------------------------------------------
-- FinalizeBuffer
-- Completes the XML closure and returns the data buffer.
function FinalizeBuffer()
	assert(not(gpg.StringIsNilOrEmpty(rootNodeName)), "Root node name is empty and should not be.")
	table.insert(buffer, string.format("// %s --END--", rootNodeName))
	bufferFinalized = true
	return buffer
end	-- FinalizeBuffer

-------------------------------------------------------------------------------
-- AddNamedNode
-- Adds a node from a provided table of data using a named format.
-- Arguments
--		formatName		: The name of the node format to use - must be in the namedNodeFormats collection.
--		variable data elements - these must be in the same order as the node format.
function AddNamedNode(formatName, ...)
	nodeFormat = namedNodeFormats[formatName]
	assert(not(gpg.StringIsNilOrEmpty(nodeFormat)), "There is no format for the node you are attempting to add.")

	AddNode(...)
	nodeFormat = nil	-- clear the node format for the next pass - prevents accidental reuse.

	end	-- AddNamedNode

-------------------------------------------------------------------------------
-- AddNode
-- Adds a node from a provided table of data.
-- Arguments
--		variable data elements - these must be in the same order as the node format.
function AddNode(...)
	assert(not(gpg.StringIsNilOrEmpty(nodeFormat)), "Node format is empty and should not be.")
	assert(not(bufferFinalized), "The buffer has been finalized and further nodes cannot be added.")
	
	local data -- = {...}
	if (type(...) == "table") then data = ... else data = {...} end

	assert(type(data) == "table", "Cannot create a table from the provided variable arguments.")
	assert(gpg.WordCount(nodeFormat, "%s") <= #data, "There are more formatting specifications in the node format then provided data fields.")
	
	table.insert(buffer, string.format(nodeFormat, unpack(data)))
end	-- AddNode

-------------------------------------------------------------------------------
-- AddPreparedNode
-- Adds a preformatted node to the buffer.
-- Arguments
--		str: the node string
function AddPreparedNode(str)
	if (gpg.StringIsNilOrEmpty(str)) then return end
	table.insert(buffer, str)
end	-- AddPreparedNode

-------------------------------------------------------------------------------
-- AddError
-- Adds an error node to the buffer.
-- Arguments
--		message	: The error message to populate the node.
function AddError(message)
	if (gpg.StringIsNilOrEmpty(message)) then return end
	table.insert(buffer, string.format("// ERROR: %s", message))
end	-- AddError

