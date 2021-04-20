-- Known issues --
-- ATF - APPLINK-14546 (ATF sometimes doesn't send HMI request. - last Test will fails die to this issue)
-- SDL - APPLINK-14550 (SDL rejects SystemRequest if specified file was uploaded before as system file.) - 
-- APPLINK-14550 is not applicable because of APPLINK-11677.
-- Known issues --


-------------------------------------------------------------------------------------------------
-------------------------------------------Updates of files -------------------------------------
-------------------------------------------------------------------------------------------------
local commonSteps   = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

  
function DeleteLog_app_info_dat_policy()
    commonSteps:CheckSDLPath()
    local SDLStoragePath = config.pathToSDL .. "storage/"

    --Delete app_info.dat and log files and storage
    if commonSteps:file_exists(config.pathToSDL .. "app_info.dat") == true then
      os.remove(config.pathToSDL .. "app_info.dat")
    end

    if commonSteps:file_exists(config.pathToSDL .. "SmartDeviceLinkCore.log") == true then
      os.remove(config.pathToSDL .. "SmartDeviceLinkCore.log")
    end

    if commonSteps:file_exists(SDLStoragePath .. "policy.sqlite") == true then
      os.remove(SDLStoragePath .. "policy.sqlite")
    end

    if commonSteps:file_exists(config.pathToSDL .. "policy.sqlite") == true then
      os.remove(config.pathToSDL .. "policy.sqlite")
    end

    os.execute("rm -r " ..config.pathToSDL .. "storage")
end

-- Function will delete all needed files and folders => SDL will start very first ignition cycle.
DeleteLog_app_info_dat_policy()


----------------------------------------------------------------------------------------------
-- make reserve copy of file (FileName) in specified folder
local function BackupSpecificFile(FileFolder , FileName)
    os.execute(" cp " .. FileFolder .. FileName .. " " .. FileFolder .. FileName .. "_origin" )
end

-- restore origin of file (FileName) in specified folder
local function RestoreSpecificFile(FileFolder, FileName)
  	os.execute(" cp " .. FileFolder .. FileName .. "_origin " .. FileFolder .. FileName )
    os.execute( " rm -f " .. FileFolder .. FileName .. "_origin" )
end

function UpdatePolicy()
    commonPreconditions:BackupFile("sdl_preloaded_pt.json")

    local src_preloaded_json = config.pathToSDL .."sdl_preloaded_pt.json"
    local dest               = "files/OnAppregistered/sdl_preloaded_pt.json"
    
    local filecopy = "cp " .. dest .."  " .. src_preloaded_json

    os.execute(filecopy)
end

UpdatePolicy()


-------------------------------------------------------------------------------------------------
-------------------------------------------END Updates of files ---------------------------------
-------------------------------------------------------------------------------------------------

Test = require('connecttest')	
require('cardinalities')
local events = require('events')	
local mobile_session = require('mobile_session')

config.deviceMAC      = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
config.SDLStoragePath = config.pathToSDL .."storage/"
--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2

config.application1 =
{
  	registerAppInterfaceParams =
  	{
    	syncMsgVersion =
    	{
      		majorVersion = 3,
      		minorVersion = 0
    	},
    	appName = "Test Application",
    	isMediaApplication = true,
    	languageDesired = 'EN-US',
    	hmiDisplayLanguageDesired = 'EN-US',
    	appHMIType = { "NAVIGATION" },
    	appID = "123456",
    	deviceInfo =
    	{
      		os = "Android",
      		carrier = "Megafon",
      		firmwareRev = "Name: Linux, Version: 3.4.0-perf",
      		osVersion = "4.4.2",
      	maxNumberRFCOMMPorts = 1
    }
  }
}

local storagePath = config.SDLStoragePath..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"	
local applicationID
local registerAppInterfaceParams = {syncMsgVersion = 
										{ 
											majorVersion = 2,
											minorVersion = 2,
										}, 
										appName ="SyncProxyTester",
										isMediaApplication = true,
										languageDesired ="EN-US",
										hmiDisplayLanguageDesired ="EN-US",
										appID ="123456"}

function DelayedExp(timeToWait)
	timeToWait = timeToWait or 2000
	local event = events.Event()
	event.matches = function(self, e) return self == e end
	EXPECT_EVENT(event, "Delayed event")
	RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, timeToWait)
end

---------------------------------------------------------------------------------------------
-- Functions used in test cases
---------------------------------------------------------------------------------------------

--UPDATED: Added new function
local function DelayedExp(time)

 	local event = events.Event()
   	event.matches = function(self, e) return self == e end
   	
   	EXPECT_EVENT(event, "Delayed event")
   	:Timeout(time+1000)
   	
   	RUN_AFTER(function()
         RAISE_EVENT(event, event)
     		  end, time)
end


-- Function for precondition tests
local function UnregisterApplication(self, hmi_app_id)
	--mobile side: UnregisterAppInterface request 
	local CorIdUAI = self.mobileSession:SendRPC("UnregisterAppInterface",{}) 

	--hmi side: expect OnAppUnregistered notification 
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = hmi_app_id, unexpectedDisconnect = false})
 

	--mobile side: UnregisterAppInterface response 
	EXPECT_RESPONSE(CorIdUAI, { success = true, resultCode = "SUCCESS"})
	:Timeout(2000) 
end

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
	--Begin Precondition.1
	--Description: Activation App by sending SDL.ActivateApp	
		function Test:ActivationApp()
			--hmi side: sending SDL.ActivateApp request
			applicationID = self.applications["Test Application"]
			local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = applicationID})
			
			--hmi side: expect SDL.ActivateApp response
			EXPECT_HMIRESPONSE(RequestId)
				:Do(function(_,data)
					--In case when app is not allowed, it is needed to allow app
					if data.result.isSDLAllowed ~= true then

						--hmi side: sending SDL.GetUserFriendlyMessage request
						local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", 
											{language = "EN-US", messageCodes = {"DataConsent"}})

						--hmi side: expect SDL.GetUserFriendlyMessage response
						EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
							:Do(function(_,data)

								--hmi side: send request SDL.OnAllowSDLFunctionality
								self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", 
									{allowed = true, source = "GUI", device = {id = 1, name = "127.0.0.1"}})

							end)
						--hmi side: expect SDL.OnAppPermissionChanged notification from SDL about new request type for the App
						EXPECT_HMINOTIFICATION("SDL.OnAppPermissionChanged", 
									{appID = applicationID, requestType = {"PROPRIETARY", "HTTP", "QUERY_APPS"}})
						:ValidIf(function (self, data)
							-- body
							if #data.params.requestType == 3 then
								return true
							else
								return false
							end
						end)

						--hmi side: expect BasicCommunication.ActivateApp request
						EXPECT_HMICALL("BasicCommunication.ActivateApp")
						:Times(AnyNumber())
						:Do(function(_,data)

							--hmi side: sending BasicCommunication.ActivateApp response
							self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})

						end)
						-- :Times(2)
					end
			end)
			
			--mobile side: expect notification
			EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL"}) 
		end
	--End Precondition.1

	
---------------------------------------------------------------------------------------------
-----------------------------------------I TEST BLOCK----------------------------------------
--CommonRequestCheck: Check of mandatory/conditional request's parameters (mobile protocol)--
---------------------------------------------------------------------------------------------
--Begin Test suit PositiveRequestCheck

--Description: TC's checks processing 
	-- request type is sent in OnAppRegistered
	-- request type is sent in OnAppRegistered between ignition cycles
	-- SDL notifies HMI about changes of requestType with SDL.OnAppPermissionChanged notification


--Begin Test case CommonRequestCheck.1
--Description:This test is intended to check positive cases and when all parameters are in boundary conditions

--Requirement id in JAMA: 
		-- SDLAQ-CRS-3073
		-- SDLAQ-CRS-3074	
		-- SDLAQ-CRS-2757

--Verification criteria: 
	--SDL->HMI: BC.OnAppRegistered (params: aplications with 'requestType')

--Begin Precondition.1
--Description: The application should be unregistered before next test.

function Test:UnregisterAppInterface_Success() 

	UnregisterApplication(self, applicationID)

end

--End Precondition.1


--Begin Test case CommonRequestCheck.1.1
--Description: Check processing request with app parameters
function Test:RTypeTheSameBetweenRegistrations()
	-- body

	local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface", registerAppInterfaceParams)

	-- hmi side: SDL notifies HMI about registered App
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {
																	application = {
																					appName = "SyncProxyTester",
																					requestType = {"PROPRIETARY", "HTTP", "QUERY_APPS"}
																				   }
                      											 })
	:ValidIf(function (self, data)
    			-- body
    			if #data.params.application.requestType == 3 then
    				return true
    			else
    				return false
    			end
    		end)

	self.mobileSession:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
		:Timeout(2000)
	
end

--ToDo: Shall be removed when APPLINK-24902: Genivi: Unexpected unregistering application at resumption after closing session.
function Test:RegisterAppAgain()
	-- body

	local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface", registerAppInterfaceParams)

	-- hmi side: SDL notifies HMI about registered App
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {
																	application = {
																					appName = "SyncProxyTester",
																					requestType = {"PROPRIETARY", "HTTP", "QUERY_APPS"}
																				   }
                      											 })
	
	:ValidIf(function (self, data)
    			-- body
    			if #data.params.application.requestType == 3 then
    				return true
    			else
    				return false
    			end
    		end)

	self.mobileSession:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
		:Timeout(2000)
	
end
--ToDo: Shall be removed when APPLINK-24902: Genivi: Unexpected unregistering application at resumption after closing session.
function Test:ActivateAppAgain()	
	applicationID = self.applications["SyncProxyTester"]	
	local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = applicationID})	
	DelayedExp(10000)
end

--End Test case CommonRequestCheck.1.1
---------------------------------------------------------------------------------------------

--Begin Test case CommonRequestCheck.1.2
--Description: Check that SDL resend RequestType parameter in SystemRequest to the App
function Test:RTypeIsPresentInSystemRequest()
	applicationID = self.applications["SyncProxyTester"]
	--mobile side: sending SystemRequest request
 	local cid = self.mobileSession:SendRPC("SystemRequest",
                    {requestType = "HTTP",
                     fileName = "IVSU"},
                     "files/file.json")
  	-- hmi side: SDL resend SystemRequest to HMI
 	EXPECT_HMICALL("BasicCommunication.SystemRequest",
 					{
 						requestType = "HTTP",
 						-- fileName = "IVSU",
 						-- appID = applicationID
 					})
 	:Do(function (_,data)
 		-- body
 		--print("We are Here!!!")
 		--print(data.id)
 		self.hmiConnection:SendResponse(data.id, "BasicCommunication.SystemRequest", "SUCCESS", {})
 	end)

 	self.mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
 	:Timeout(2000)

end
--End Test case CommonRequestCheck.1.2

---------------------------------------------------------------------------------------------

--Begin Test case CommonRequestCheck.1.3
--Description: Check that SDL resend RequestType parameter in SystemRequest without binary data, uploaded before as usual file

--Begin Precondition.1
	--Description: The application should be unregistered before next test.

	function Test:PreCondUploadUsualBinaryData() 

		local cid = self.mobileSession:SendRPC("PutFile",
							{
		    					syncFileName = "ptu1",
		    					fileType = "JSON",
		    					systemFile = false
		  					}, "files/file.json")
		EXPECT_RESPONSE(cid, { success = true })
		
	end

--End Precondition.1

function Test:RTypeInSystemRequestWOBinaryData()
	--mobile side: sending SystemRequest request
 	local cid = self.mobileSession:SendRPC("SystemRequest",
                    {requestType = "PROPRIETARY",
                     fileName = "ptu1"})

  	-- hmi side: SDL resend SystemRequest to HMI
 	EXPECT_HMICALL("BasicCommunication.SystemRequest",
 					{
 						requestType = "PROPRIETARY",
 						-- fileName = "IVSU",
 						-- appID = applicationID
 					})
 	:Do(function (_,data)
 		-- body
 		self.hmiConnection:SendResponse(data.id, "BasicCommunication.SystemRequest", "SUCCESS", {})
 	end)

 	self.mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})

 	

end
--End Test case CommonRequestCheck.1.3

---------------------------------------------------------------------------------------------

--Begin Test case CommonRequestCheck.1.4
--Description: Check that SDL resend RequestType parameter in SystemRequest without binary data, uploaded before as system file

--Begin Precondition.1
	--Description: The application should be unregistered before next test.

	function Test:PreCondUploadSystemBinaryData() 

		local cid = self.mobileSession:SendRPC("PutFile",
							{
		    					syncFileName = "ptu2",
		    					fileType = "JSON",
		    					systemFile = true
		  					}, "files/file.json")
		EXPECT_RESPONSE(cid, { success = true })
		
		

	end

--End Precondition.1

--UPDATED according to APPLINK-11677
function Test:RTypeInSystemRequestWOBinaryData()
	--mobile side: sending SystemRequest request
 	local cid = self.mobileSession:SendRPC("SystemRequest",
                    {requestType = "PROPRIETARY",
                     fileName = "ptu2"})

	EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile", {syncFileName = "/tmp/fs/mp/images/ivsu_cache/ptu2"})
 	--:Timeout(20000)
  	-- hmi side: SDL resend SystemRequest to HMI
 	
 	-- EXPECT_HMICALL("BasicCommunication.SystemRequest",
 	-- 	 				{
 	-- 						requestType = "PROPRIETARY",
 	-- 						-- fileName = "IVSU",
 	-- 						-- appID = applicationID
 	-- 					})
 	-- :Do(function (_,data)
 	-- 	-- body
 	-- 	self.hmiConnection:SendResponse(data.id, "BasicCommunication.SystemRequest", "SUCCESS", {})
 	-- end)

 	-- self.mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
	
	EXPECT_HMICALL("BasicCommunication.SystemRequest",{}):
	Times(0)

end
--End Test case CommonRequestCheck.1.4

---------------------------------------------------------------------------------------------

--Begin Test case CommonRequestCheck.1.5
--Description: Check that SDL reject SystemRequest without binary data, if specified file was not uploaded before and absent in request

function Test:SystemRequestWODataRejected()
	--mobile side: sending SystemRequest request
 	local cid = self.mobileSession:SendRPC("SystemRequest",
                    {requestType = "PROPRIETARY",
                     fileName = "ptu3"})

 	self.mobileSession:ExpectResponse(cid, { success = false, resultCode = "REJECTED"})
 	:Timeout(2000)

end

--End Test case CommonRequestCheck.1.5

---------------------------------------------------------------------------------------------

--Begin Test case CommonRequestCheck.1.6
--Description: Check that SDL notify HMI with OnAppPermssionChange if App receive new Request Type after PTU.

--Begin Precondition.2
	--Description: Policy update for RegisterAppInterface API
	function Test:PolicyUpdateGetUrls()
		--hmi side: sending SDL.GetURLS request
		local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
		
		--hmi side: expect SDL.GetURLS response from HMI
		--ToDo: Shall be uncommented when APPLINK-16052 "ATF: TC is failed in case receiving message with nested struct" is fixed
		-- EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetURLS", urls = {
		-- 																							{
		-- 																								appID =  self.applications["Test Application"],
		-- 	                                                                                      		url = "http://policies.telematics.ford.com/api/policies"
		-- 																						  }
		-- 																						}}})
	end

	function Test:PolicyUpdateOnSystemRequest()
		-- body
		self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
			{
				requestType = "PROPRIETARY",
				fileName = "PolicyTableUpdate"
			}
		)

		--ToDo: Shall be uncommented when APPLINK-24972 is resolved
		--mobile side: expect OnSystemRequest notification 
		--EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
		--:Timeout(2000)
	end

	function Test:PolicyUpdateSystemRequest()

		local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
				{
					fileName = "PolicyTableUpdate",
					requestType = "PROPRIETARY"
				},
			"files/ptu.json")

		local systemRequestId
		--hmi side: expect SystemRequest request
		EXPECT_HMICALL("BasicCommunication.SystemRequest")
		:Do(function(_,data)
				systemRequestId = data.id
				print("BasicCommunication.SystemRequest is received")
				print(systemRequestId)
					--hmi side: sending SystemRequest response
				self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
		end)

		EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})				
		:Timeout(5000)
	end

	function Test:PtuSuccess()
		-- body
		-- hmi side: sending BasicCommunication.OnSystemRequest request to SDL
		self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
			{
				policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
			})

		--hmi side: expect SDL.OnStatusUpdate
		EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status =  "UP_TO_DATE"})
		:Do(function(_,data)
			print("SDL.OnStatusUpdate is received")			               
		end)
		:Timeout(2000)

		EXPECT_HMINOTIFICATION("SDL.OnAppPermissionChanged", 
				--{appID = self.applications["Test Application"], requestType = {"TRAFFIC_MESSAGE_CHANNEL", "PROPRIETARY", "HTTP", "QUERY_APPS"}})
				{appID = self.applications["SyncProxyTester"], requestType = {"TRAFFIC_MESSAGE_CHANNEL", "PROPRIETARY", "HTTP", "QUERY_APPS"}})
		:ValidIf(function (self, data)
			-- body
			if #data.params.requestType == 4 then
				return true
			else
				return false
			end
		end)
		:Timeout(2000)
	end
		
--End Test case CommonRequestCheck.1.6

---------------------------------------------------------------------------------------------

--Begin Test case CommonRequestCheck.1.7
--Description: Check that SDL resend requestType in OnSystemRequest

function Test:RTInOnSystemRequest()
	-- body
	self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", {
		requestType = "HTTP",
		fileName = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
		})
	-- mobile side: SDL should resend to mobile OnSystemRequest
	EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "HTTP" })
	:Timeout(2000)
end

--End Test case CommonRequestCheck.1.7


---------------------------------------------------------------------------------------------
-------------------------------------------Postconditions-------------------------------------
---------------------------------------------------------------------------------------------

function Test:PostconditionsRestoreFile()

    commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end

return Test
