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

function Test:CheckExtraTable()
	-- body
	local query = ".tables"
	local command = "sqlite3 " .. pathToDB .. " \"" .. query .. "\" | grep extraTable | wc -l"
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
-- END TESTCASE IVSU.2.8

-- Begin PostCondition
-- Description: StopSDL
function Test:StopSDL()
	-- body
	CommonFunctions.stopSDL()
	CommonFunctions.sleep(5)
	while true do
		if CommonFunctions.isSDLRunning() then
		else
			break
		end
	end
end
-- End Postondition.2