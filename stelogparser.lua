--------------------------------------------------------------------------------
-- STE Log File Parser
-- Processes a STE log to remove all entries except for DUMPVAR entries.
-- assists with calculation diagnosis
--

local csi = require "csiutilities"


-------------------------------------------------------
-- ProcessArguments
-- Handles calling argument processing for script initialization.
-- sourceFileName will be set to NIL if there is a failure to process arguments
-- Returns
--		results			: true if arguments were properly processed; false otherwise.
--		logfile			: FQN name of log file to process.
--		results			:	FQN name of results file.
function ProcessArguments()

	local flags, strings = csi.ParseFlags(arg)

	local count = 0
	for _,k in pairs(flags) do
		count = count + 1
	end

	if count == 0 or table.containsKey(flags, "?") or table.containsValue(strings, "help") then
		print("Usage: stelogparser.lua [--l=logfile_name] [--r=results_file_name] [--t=target_string_fragment]")
		print("Example: stelogparser.lua --l=mylogfile.log --r=mylogfile_munged.log --t=dumpvars:")
		print("NOTE:")
		print("If the --r flag is not set, the result file will be named after the source log file with '_parsed' appended.")
		print("if the --t flag is not set, the default target becomes 'dumpvars:'.")
		return false, nil, nil
	end
	
	local logfile = nil
	local results = nil
	
	if table.containsKey(flags, "l") then logfile = flags["l"] end
	if table.containsKey(flags, "r") then results = flags["r"] end
	if table.containsKey(flags, "t") then target = flags["t"] end
	
	-- The argument flags with no equation argument may return a 'true' - protect against this.
	if (csi.SafeString(logfile) == "true" or logfile == "") then logfile = nil end
	if (csi.SafeString(results) == "true" or results == "") then results = nil end 
	if (csi.SafeString(target) == "true" or target == "") then target = nil end
	

	if (results == nil and csi.SafeString(logfile) ~= "") then 
		results = csi.CreateOutputFileName(logfile, false, "parsed") 
	end
	
	if (csi.SafeString(target) == "") then 
	target = "dumpvars:"	-- Default log parsing to the dumpvars lines.
	end
	
	return logfile ~= nil, logfile, results, target
end	-- ProcessArguments


----------------------------------------------------------------
-- MAIN SCRIPT
----------------------------------------------------------------


print("DUMPVAR Log Parser - processes STE logs for specific log entries.")
print("GPG - FEB 2015")
print("\n")

local ok, filename, resultsName, target = ProcessArguments()
if (not(ok)) then return end

print("Source file : " .. filename)
print("Result file : " .. resultsName)
print("Parse target: " .. target)
io.write("Processing  : ")

local source = csi.DumpFileToBuffer(filename, false, nil, 0)
assert(source, "No buffer was loaded from the specified file.")
local buffer = csi.SelfFlushingOutputBuffer(100, resultsName, false, true)

local spinner = csi.DisplayHack()

for _,l in pairs(source) do
	spinner()
	if (string.find(l, target)) then buffer(l) end
end

buffer()

io.write("\b Parsing completed.")

