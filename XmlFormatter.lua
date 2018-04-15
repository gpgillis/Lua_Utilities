-------------------------------------------------------------------------------
-- XML Formatter 
-- A helper utility to assist in formatting data into XML.
-- This utility will generate simple XML nodes based on a provide node format and
-- a set of data strings. The compiled data can then be retrieved as a table of strings
-- which then can be saved as a file or manipulated further.
--
-- GPG 20110615
--
-- Meta information
-- _DESCRIPTION = "A utility to assist in XML formatting of data."
-- _VERSION = modname .. " 1.0.0"
-------------------------------------------------------------------------------
--
-- Example:
--
-- local formatter = require "XMLFormatter"
--
-- local nodeFormat = [[
--		<Location_Data>
--			<location_code>%s</location_code>
--			<tax_type>%s</tax_type>
--			<zipcode>%s</zipcode>
--			<description>%s, %s</description>
--		</Location_Data>]]
--
--		formatter.SetNodeFormat(nodeFormat)
--		local comments = {"This is the first comment", "This is the second comment", string.format("Created by %s on %s", arg[0], os.date("%c")) }
--		formatter.InitializeBuffer("RootNode", comments)
--		formatter.AddNode("00-000-0000", "Federal", "48130", "Dexter", "Michigan")
--		formatter.AddNode("26-128-624624", "State", "48130", "Dexter", "Michigan")
--		local buffer = formatter.FinalizeBuffer()
--		for k,v in pairs(buffer) do print(v) end
--
--	Generates:
-- C:\tfs\Symmetry_Tools\lua-code>lua testme.lua
-- <?xml version="1.0" encoding="us-ascii"?>
-- <!--This is the first comment-->
-- <!--This is the second comment-->
-- <!--Created by testme.lua on 06/15/11 10:51:47-->
-- <RootNode>
        -- <Location_Data>
                -- <location_code>00-000-0000</location_code>
                -- <tax_type>Federal</tax_type>
                -- <zipcode>48130</zipcode>
                -- <description>Dexter, Michigan</description>
        -- </Location_Data>
        -- <Location_Data>
                -- <location_code>26-128-624624</location_code>
                -- <tax_type>State</tax_type>
                -- <zipcode>48130</zipcode>
                -- <description>Dexter, Michigan</description>
        -- </Location_Data>
-- </RootNode>
-------------------------------------------------------------------------------

local modname = ... 

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
--		fmt		:	The node format string
--		show	: If true - the node format is displayed to stdio.
--
function SetNodeFormat(fmt, show)
	if (show) then print ("Setting node format with :\n" .. fmt) end
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
	
	table.insert(buffer, "<?xml version=\"1.0\" encoding=\"us-ascii\"?>")
	if type(comments) == "table" then
		for k, v in pairs(comments) do
			if not(gpg.StringIsNilOrEmpty(v)) then
				table.insert(buffer, string.format("<!--%s-->", v))
			end
		end
	else
		if not(gpg.StringIsNilOrEmpty(comments)) then
			table.insert(buffer, string.format("<!--%s-->", comments))
		end
	end
	
	table.insert(buffer, string.format("<%s>", rootNodeName))
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
	table.insert(buffer, string.format("</%s>", rootNodeName))
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
	table.insert(buffer, string.format("<ERROR>%s</ERROR>", message))
end	-- AddError

-------------------------------------------------------------------------------
-- AddComment
-- Adds a comment node to the buffer.
-- Arguments
--		message	: The comment message to populate the node.
function AddComment(message)
	if (gpg.StringIsNilOrEmpty(message)) then return end
	table.insert(buffer, string.format("<!-- %s -->", message))
end	-- AddComment


