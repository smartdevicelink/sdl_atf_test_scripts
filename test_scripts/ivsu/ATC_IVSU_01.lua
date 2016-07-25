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
-----------------------------------------I TEST BLOCK----------------------------------------
--------------------------------------IVSU: common checks------------------------------------
---------------------------------------------------------------------------------------------

	--Begin Test suit IVSU
	--Description:
		-- existance of Policy DB
		-- value of ‘db_version_hash’ field in existing database
		-- existence of updated PreloadedPT
		-- ‘db_version_hash’ from existing database is different from value of ‘db_version_hash’ from SDL code
		-- ‘db_version_hash’ from existing database is equal the value of ‘db_version_hash’ from SDL code
		-- ‘db_version_hash’ from existing database is empty

		
		--Begin Test case CommonRequestCheck.1
			--Description: Check processing request with or without conditional parameters

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-3, SDLAQ-CRS-1316,SDLAQ-CRS-1317,SDLAQ-CRS-2753, SDLAQ-CRS-197

			--Verification criteria: The request for registering was sent and executed successfully. The response code SUCCESS is returned.
			--When the app is registered with RegisterAppInterface, the corresponding request, response and notification are sent to mobile side in the following order: RegisterAppInterface request, RegisterAppInterface response, OnHMIStatus and OnPermissionsChnage notifications (the order of these two notifications is may vary, but they come AFTER RegisterAppInterface(response)).

			--Begin Test case CommonRequestCheck.1.1
			--Description: Check processing request with app parameters


---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
--Begin Precondition.1
--Description:Activation app

function Test:ActivationApp()

	--hmi side: sending SDL.ActivateApp request
	applicationID = self.applications["Test Application"]
  	local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = applicationID})

  	--hmi side: expect SDL.ActivateApp response
	EXPECT_HMIRESPONSE(RequestId)
		:Do(function(_,data)
			--In case when app is not allowed, it is needed to allow app
	    	if
	        	data.result.isSDLAllowed ~= true then
	        		theDeviceID = data.result.device.id

	        		--hmi side: sending SDL.GetUserFriendlyMessage request
	            	local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", 
								        {language = "EN-US", messageCodes = {"DataConsent"}})

	            	--hmi side: expect SDL.GetUserFriendlyMessage response
    			  	EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
		              	:Do(function(_,data)

		    			    --hmi side: send request SDL.OnAllowSDLFunctionality
		    			    self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", 
		    			    	{allowed = true, source = "GUI", device = {id = theDeviceID, name = "127.0.0.1"}})

		              	end)

		            --hmi side: expect BasicCommunication.ActivateApp request
		            EXPECT_HMICALL("BasicCommunication.ActivateApp")
		            	:Do(function(_,data)

		            		--hmi side: sending BasicCommunication.ActivateApp response
				          	self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})

				        end)
			end
	      end)

	--mobile side: expect OnHMIStatus notification
  	EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL"})	

end

--End Precondition.1

-- BEGIN TEST CASE IVSU.1.1
-- Description: Happy path
function Test:IVSU_1_1_Positive()
	CommonFunctions.ivsu(self, index)
	index = index +1
end	
-- END TESTCASE IVSU.1.1

-- BEGIN TEST CASE IVSU.1.2
-- Description: Happy path with pauses from HMI 10 seconds
function Test:IVSU_1_2_WithPauses( )
	-- body
	CommonFunctions.ivsu(self, index, 1)
	index = index +1
end
-- END TESTCASE IVSU.1.2

-- BEGIN TEST CASE IVSU.1.3
-- Description: 1st SystemRequest in IVSU flow contain binary data
function Test:IVSU_1_3_FirstSystemRequestWithBinary()
	-- body
	CommonFunctions.ivsu(self, index, 0, true)
	index = index +1
end
-- END TESTCASE IVSU.1.3

---------------------------------------------------------------------------------------------
--------------------------------------END: I TEST BLOCK--------------------------------------
---------------------------------------------------------------------------------------------



---------------------------------------------------------------------------------------------
----------------------------------------II TEST BLOCK----------------------------------------
-----------------------------------IVSU: SDL was updated-------------------------------------
---------------------------------------------------------------------------------------------

	--Begin Test suit IVSU
	--Description:
		-- existance of Policy DB
		-- value of ‘db_version_hash’ field in existing database
		-- existence of updated PreloadedPT
		-- ‘db_version_hash’ from existing database is different from value of ‘db_version_hash’ from SDL code
		-- ‘db_version_hash’ from existing database is equal the value of ‘db_version_hash’ from SDL code
		-- ‘db_version_hash’ from existing database is empty

		
		--Begin Test case CommonRequestCheck.1
			--Description: Check processing request with or without conditional parameters

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-3, SDLAQ-CRS-1316,SDLAQ-CRS-1317,SDLAQ-CRS-2753, SDLAQ-CRS-197

			--Verification criteria: The request for registering was sent and executed successfully. The response code SUCCESS is returned.
			--When the app is registered with RegisterAppInterface, the corresponding request, response and notification are sent to mobile side in the following order: RegisterAppInterface request, RegisterAppInterface response, OnHMIStatus and OnPermissionsChnage notifications (the order of these two notifications is may vary, but they come AFTER RegisterAppInterface(response)).

			--Begin Test case CommonRequestCheck.1.1
			--Description: Check processing request with app parameters

-- BEGIN TEST CASE IVSU.2.1
-- Description: DB exist and

-- Begin Precondition.1
-- Description: IVSU before ignition off
function Test:IVSU()
	-- body
	CommonFunctions.ivsu(self, index)
	index = index +1
end
-- End Precondition.1

--Begin Precondition.2
--Description: The application should be unregistered before SDL stopped.

	function Test:UnregisterAppInterface_Success() 
		CommonFunctions.UnregisterApplicationSessionOne(self)
	end

--End Precondition.2

--Begin Precondition.3
-- Description: StopSDL
function Test:StopSDL()
	-- body
	CommonFunctions.stopSDL()
	CommonFunctions.sleep(10)
end
-- End Precondition.3

-- Begin Precondition.4
-- Description: Start SDL
function Test:StartSDL()
	-- body
	CommonFunctions.startSDL(pathToSDL, binaryName, 2)
	CommonFunctions.sleep(4)
end
-- End Precondition.4
-- END TESTCASE IVSU.2.1
