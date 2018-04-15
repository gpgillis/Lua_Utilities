-------------------------------------------------------------------------------
--
-- gpg STE Config : A base configuration for use with gpg STE processing utilities.
--
-------------------------------------------------------------------------------

gpgSTEConfig = {}

-- Meta information
-- _DESCRIPTION = "A base configuration for gpg STE processing scripts"
-- _VERSION = "gpgSTEConfig 1.0.0"


STE_CURRENT_VERSION = "ste-Win32-1.3.05-2015-R10"
STE_PREVIOUS_VERSION = "ste-Win32-1.3.04-2015-R9"

STE_HOME = "c:/" .. STE_CURRENT_VERSION .. "/ste-root/"

STE_BASE = "c:/ste_base/"
--STE_HOME = string.gsub(STE_HOME, "\\", "/")	-- convert to unix style directory paths

gpg_STE_TOOLS_HOME = "c:/tfs/symmetry_tools/utilities/"
gpg_STE_DATA_HOME = "c:/tfs/symmetry_data/"
gpg_STE_DBDUMP = gpg_STE_DATA_HOME

-- Locations for STE release analysis results files.
CURRENT_PACKAGE_LOCATION = gpg_STE_DBDUMP .. "stedbdump_" .. STE_CURRENT_VERSION .. "/"
PREVIOUS_PACKAGE_LOCATION = gpg_STE_DBDUMP .. "stedbdump_" .. STE_PREVIOUS_VERSION .. "/"
TAX_STORAGE_BASE_NAME = "ste_taxes.db"					-- base database file name for storing current STE tax information.

-- Location for JAVA installation - used for decompiler.
JAVA_INSTALLATION_PATH = "c:/Program Files (x86)/java/jre7/bin/java.exe"

-- STE database settings
STE_DB_TYPE = "Sqlite"
STE_DB_PATH = STE_HOME .. "ste.db" -- Sqlite only
STE_LOCATION_DB_PATH = STE_HOME .. "location.db" -- Sqlite only
STE_DB_NAME = "ste"
STE_DB_BASE64 = true

-- Lua script locations for the current STE installation.
STE_BASE_SCRIPT = "ste-base.lua"
LUA_SCRIPTS_PATH = STE_HOME .. "/lua/scripts/"
LUA_PATH =	STE_HOME .. "/lua/?.lua;" .. LUA_SCRIPTS_PATH .. "?.lua;" .. LUA_SCRIPTS_PATH .. "logging/?.lua;?.lua"
LUA_CPATH =	STE_HOME .. "/lua/?.dll;" .. STE_HOME .. "/lua/libs/?.dll;?.dll"

-- Location for the log file
STE_LOG_FILE_DIRECTORY = gpg_STE_TOOLS_HOME .. "log/"
STE_LOGGING_LEVEL = "DEBUG"
gpg_USE_SIMPLE_LOGFILES = true

-- Base location of all gpg GNIS data files - source files and database.
gpg_GNIS_HOME = "C:/tfs/Symmetry_Tools/gnis_data/"
-- gpg_GNIS_HOME = string.gsub(gpg_GNIS_HOME, "\\", "/")		-- convert to unix style directory paths
GNIS_DB_PATH = gpg_GNIS_HOME .. "gnis_data.db"					-- database location
GNIS_DATA_PATH = gpg_GNIS_HOME .. "GNIS_RAW_DATA/"			-- Source data location

