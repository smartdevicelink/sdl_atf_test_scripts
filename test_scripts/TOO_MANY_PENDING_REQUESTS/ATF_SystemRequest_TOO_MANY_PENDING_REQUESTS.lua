Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------

require('user_modules/AppTypes')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
APIName = "SystemRequest" -- use for above required scripts.
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--Updated with Automated Preconditions for ini file 

--Backup smartDeviceLink.ini file
function Precondition_ArchivateINI()
    commonPreconditions:BackupFile("smartDeviceLink.ini")
end

function Precondition_PendingRequestsAmount()
    local SDLini = config.pathToSDL .. tostring("smartDeviceLink.ini")
    local StringToReplace = "PendingRequestsAmount = 3\n"
    f = assert(io.open(SDLini, "r"))
    if f then
        fileContent = f:read("*all")

        fileContentUpdated  =  string.gsub(fileContent, "%p?PendingRequestsAmount%s-=%s?[%w%d;]-\n", StringToReplace)

        if fileContentUpdated then
          f = assert(io.open(SDLini, "w"))
          f:write(fileContentUpdated)
        else 
          userPrint(31, "Finding of 'PendingRequestsAmount = value' is failed. Expect string finding and replacing of value to true")
        end
        f:close()
    end
end
Precondition_ArchivateINI()
Precondition_PendingRequestsAmount()

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
--Updated--

function DelayedExp()
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, 2000)
end

function RegisterApplication(self)
		-- body
		local corrID = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
		:Do(function (_, data)
			-- body
			applicationID = data.params.application.appID
		end)

		EXPECT_RESPONSE(corrID, {success = true})

		-- delay - bug of ATF - it is not wait for UpdateAppList and later
		-- line appID = self.applications["Test Application"]} will not assign appID
		DelayedExp(1000)
	end

function Test:StopSDLToBackUpPreloadedPt( ... )
		-- body
		StopSDL()
		DelayedExp(1000)
	end

	function Test:BackUpPreloadedPt()
		-- body
		os.execute('cp ' .. config.pathToSDL .. 'sdl_preloaded_pt.json' .. ' ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json')
		os.execute('rm ' .. config.pathToSDL .. 'policy.sqlite')
	end

	function Test:UpdatePreloadedJson(pathToFile)
		local src_preloaded_json = config.pathToSDL .."sdl_preloaded_pt.json"
    	local dest               = "files/PTU_ForSystemRequest.json"
    	local filecopy = "cp " .. src_preloaded_json .."  " .. dest
		
	end

local function StartSDLAfterChangePreloaded()
		-- body

		Test["Precondition_StartSDL"] = function(self)
			StartSDL(config.pathToSDL, config.ExitOnCrash)
			DelayedExp(1000)
		end

		Test["Precondition_InitHMI_1"] = function(self)
			self:initHMI()
		end

		Test["Precondition_InitHMI_onReady_1"] = function(self)
			self:initHMI_onReady()
		end

		Test["Precondition_ConnectMobile_1"] = function(self)
			self:connectMobile()
		end

		Test["Precondition_StartSession_1"] = function(self)
			self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
		end

	end

	StartSDLAfterChangePreloaded()

	function Test:RestorePreloadedPt()
		-- body
		os.execute('cp ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json' .. ' ' .. config.pathToSDL .. 'sdl_preloaded_pt.json')
		os.execute('rm ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json')
	end

	function Test:RegisterApp()
		-- body
		self.mobileSession:StartService(7)
		:Do(function (_, data)
			-- body
			RegisterApplication(self)
		end)
	end

		function Test:ActivationApp()
			--hmi side: sending SDL.ActivateApp request
			-- applicationID = self.applications[ config.application1.registerAppInterfaceParams.appName]
			self:activationApp(applicationID)
			
			--mobile side: expect notification
			EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"}) 
		end

		function Test:activationApp(appIDValue)
			--hmi side: sending SDL.ActivateApp request			
			local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = appIDValue})
			
			--hmi side: expect SDL.ActivateApp response
			EXPECT_HMIRESPONSE(RequestId)
				:Do(function(_,data)
					--In case when app is not allowed, it is needed to allow app
					if
						data.result.isSDLAllowed ~= true then

							--hmi side: sending SDL.GetUserFriendlyMessage request
							local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", 
												{language = "EN-US", messageCodes = {"DataConsent"}})

							--hmi side: expect SDL.GetUserFriendlyMessage response
							EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
								:Do(function(_,data)

									--hmi side: send request SDL.OnAllowSDLFunctionality
									self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", 
										{allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})

									--hmi side: expect BasicCommunication.ActivateApp request
									EXPECT_HMICALL("BasicCommunication.ActivateApp")
										:Do(function(_,data)

											--hmi side: sending BasicCommunication.ActivateApp response
											self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})

										end)
										:Times(2)

								end)

				end
			end)
		end	

--End Updated--	



--Update policy table
local PermissionLines_SystemRequest = 
[[					"SystemRequest": {
						"hmi_levels": [
						  "BACKGROUND",
						  "FULL",
						  "LIMITED",
						  "NONE"
						]
					  }]]
	

local PermissionLinesForBase4 = PermissionLines_SystemRequest .. ",\n"
local PermissionLinesForGroup1 = nil
local PermissionLinesForApplication = nil
--TODO: PT is blocked by ATF defect APPLINK-19188
--local PTName = testCasesForPolicyTable:createPolicyTableFile(PermissionLinesForBase4, PermissionLinesForGroup1, PermissionLinesForApplication, {"SystemRequest"})	
--testCasesForPolicyTable:updatePolicy(PTName)

	
-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK V----------------------------------------
-------------------------------------Checks All Result Codes-----------------------------------
-----------------------------------------------------------------------------------------------

--Begin Test case ResultCodeChecks
--Description: Check TOO_MANY_PENDING_REQUESTS resultCode

	--Requirement id in JAMA: APPLINK-19579

    --Verification criteria: TOO_MANY_PENDING_REQUESTS for the applications sending overlimit frames number
	
	
	function Test:SystemRequest_TOO_MANY_PENDING_REQUESTS()
	
		local numberOfRequest = 10
		for i = 1, numberOfRequest do
			--mobile side: send the request 	 	
			self.mobileSession:SendRPC(APIName, {fileName = "PolicyTableUpdate", requestType = "SETTINGS"}, "./files/PTU_ForSystemRequest.json")				
		end
		

		commonTestCases:verifyResultCode_TOO_MANY_PENDING_REQUESTS(numberOfRequest)
	end	

	
	
--End Test case ResultCodeChecks

function Test:Postcondition_RestoreINI()
    commonPreconditions:RestoreFile("smartDeviceLink.ini")
end

--Postcondition 
function Test:Postcondition_RestorePreloadedPt()
    local function RestorePreloadedPt ()
	end
end 











