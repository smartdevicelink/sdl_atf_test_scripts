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
-- END TESTCASE IVSU.2.5

-- BEGIN TEST CASE IVSU.2.6
-- Description: SDL has started with different db_version_hash and witout changes to DB

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
function Test:PrecondChangeDbVersionHash()
	-- body
	local query = "update _internal_data set db_version_hash = 12345"
	local command = "sqlite3 " .. pathToDB .. " \"" .. query .. "\""
	local handle = os.execute(command)
	return handle
end
-- End Precondition.2

-- Begin Precondition.3
-- Description: Start SDL
function Test:StartSDL()
	-- body
	CommonFunctions.startSDL(pathToSDL, binaryName, 9)
	CommonFunctions.sleep(4)
	if CommonFunctions.isSDLRunning() then
		return true
	else
		return false
	end
end
-- End Precondition.3
-- END TESTCASE IVSU.2.6