Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local config = require('config')



local hmi_connection = require('hmi_connection')
local websocket      = require('websocket_connection')
local module         = require('testbase')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')


local function OpenConnectionCreateSession(self)
	local tcpConnection = tcp.Connection(config.mobileHost, config.mobilePort)
	local fileConnection = file_connection.FileConnection("mobile.out", tcpConnection)
	self.mobileConnection = mobile.MobileConnection(fileConnection)
	self.mobileSession= mobile_session.MobileSession(
	self.expectations_list,
	self.mobileConnection)
	event_dispatcher:AddConnection(self.mobileConnection)
	self.mobileSession:ExpectEvent(events.connectedEvent, "Connection started")
	self.mobileConnection:Connect()
	self.mobileSession:StartService(7)
end

local theDeviceID = 1
local index = 0
local applicationID = 1
local pathToSDL = '/home/sdl/buildPasa/bin/'
local binaryName = 'smartDeviceLinkCore'
local pathToDB = "/home/sdl/buildPasa/bin/storage/policy.sqlite"

local CommonFunctions = require('CommonFunctions')

---------------------------------------------------------------------------------------------
----------------------------------------II TEST BLOCK----------------------------------------
-----------------------------------IVSU: SDL was updated-------------------------------------
---------------------------------------------------------------------------------------------

--CONTINUE


function Test:CheckDB()
	-- body
	CommonFunctions.checkPolicyDBTables(pathToDB)
	CommonFunctions.checkPolicyDBColumns(pathToDB)
end

function Test:CheckExtraColumn()
	-- body
	local query = "PRAGMA table_info(application)"
	local command = "sqlite3 " .. pathToDB .. " \"" .. queryColumn .. "\" | grep isFord | wc -l"
	local handle = io.popen(command)
	local commandResult = handle:read("*a")
	handle:close()
	if tonumber(commandResult) == 0 then
		return true
	elseif tonumber(commandResult) == 1 then
		return false
	else
		print("Unexpected result!")
		return false
	end
end
-- END TESTCASE IVSU.2.7

-- BEGIN TEST CASE IVSU.2.8
-- Description: SDL has started with different db_version_hash and with one extra table

-- Begin Precondition.1
-- Description: StopSDL
function Test:StopSDL()
	-- body
	CommonFunctions.stopSDL()
	CommonFunctions.sleep(5)
end
-- End Precondition.2

-- Begin Precondition.2
-- Description: Clean DB
function Test:PrecondExtraTable()
	-- body
	local queryNewTable = "CREATE TABLE extraTable (id int primary key, name Text, surname Text)"
	local queryFillTable = "INSERT INTO extraTable VALUES (1, \\\"Luxoft\\\", \\\"Global\\\")"
	local queryHash = "update _internal_data set db_version_hash = 12345"
	local command = "sqlite3 " .. pathToDB .. " \"" .. queryNewTable .. "\""
	local handle = os.execute(command)
	if handle == true then
		command = "sqlite3 " .. pathToDB .. " \"" .. queryFillTable .. "\""
		handle = os.execute(command)
	end

	if handle == true then
		command = "sqlite3 " .. pathToDB .. " \"" .. queryHash .. "\""
		handle = os.execute(command)
	end

	return handle
end
-- End Precondition.2

function Test:StartSDL()
	-- body
	CommonFunctions.startSDL(pathToSDL, binaryName, 11)
	CommonFunctions.sleep(4)
	if CommonFunctions.isSDLRunning() then
		return true
	else
		return false
	end
end
-- END TESTCASE IVSU.2.8