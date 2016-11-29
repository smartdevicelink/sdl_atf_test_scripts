---------------------------------------------------------------------------------------------
-- Description: 
--     PTU for app comes with empty "RequestType" array
--     1. Used preconditions:	
--			Unregister default application
-- 			Register application 
--			Activate application
--
--     2. Performed steps
--		    Perform PTU with new permissions that require User consent
--
-- Requirement summary: 
--    	[Policies] PTU "RequestType" array is empty
--
-- Expected result:
--  	Policies Manager must notify HMI about 'user-consent-required' via SDL.OnAppPermissionChanged{appID, appPermissionsConsentNeeded:true, 
--		provide the list of permissions that require User`s consent upon request from HMI via GetListOfPermissions(appID);
-- 		PoliciesManager must respond with the list of <groupName>s that have the field "user_consent_prompt" in corresponding <functional grouping> and 
--		are assigned to the specified application (section "<appID>" -> "groups") 
---------------------------------------------------------------------------------------------
--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
local mobile_session = require('mobile_session')

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonSteps:DeleteLogsFileAndPolicyTable()

function Test:Unregister_default_app() 
	local CorIdUAI = self.mobileSession:SendRPC("UnregisterAppInterface",{}) 
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications["SyncProxyTester"], unexpectedDisconnect = false})
	EXPECT_RESPONSE(CorIdUAI, { success = true, resultCode = "SUCCESS"})
	:Timeout(2000) 
end

function Test:Register_app()
	commonTestCases:DelayedExp(3000)
	self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
	self.mobileSession:StartService(7)
	:Do(function()
		local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
		:Do(function(_,data)
			self.HMIAppID = data.params.application.appID
		end)
		self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })
		self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
	end)
end

function Test:Activate_app()
	local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.HMIAppID})
	EXPECT_HMIRESPONSE(RequestId)
		:Do(function(_,data)
			if data.result.isSDLAllowed ~= true then
				local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
				EXPECT_HMIRESPONSE(RequestId)
				:Do(function(_,data)
					self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
					EXPECT_HMICALL("BasicCommunication.ActivateApp")
					:Do(function(_,data)
						self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
					end)
					:Times(AnyNumber())
				end)
			end
		end)
	EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
commonFunctions:userPrint(34, "Test is intended to check that Policies Manager notifies HMI about user-consent-required with appPermissionsConsentNeeded:true")

function Test:PTU_appPermissionsConsentNeeded_true()
	local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
	EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetURLS", urls = {{url = "http://policies.telematics.ford.com/api/policies"}}}})
	:Do(function(_,data)
		self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
			{
				requestType = "PROPRIETARY",
				fileName = "filename"
			}
		)
		EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
		:Do(function(_,data)
			local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
				{
					fileName = "PolicyTableUpdate",
					requestType = "PROPRIETARY"
				}, "files/PTU_NewPermissionsForUserConsent.json")
			local systemRequestId
			EXPECT_HMICALL("BasicCommunication.SystemRequest")
			:Do(function(_,data)
				systemRequestId = data.id
				self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
				{
					policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
			})
			function to_run()
				self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
			end			
			RUN_AFTER(to_run, 500)
		end)
		EXPECT_HMINOTIFICATION("SDL.OnAppPermissionChanged", {appID = self.HMIAppID, appPermissionsConsentNeeded = true })
		:Do(function(_,data)
			local RequestIdListOfPermissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", { appID = self.HMIAppID })
			EXPECT_HMIRESPONSE(RequestIdListOfPermissions,{result = {code = 0, method = "SDL.GetListOfPermissions", allowedFunctions = {{name = "Location-1"}, {name = "DrivingCharacteristics-3"}}}})
			:Do(function(_,data)
				local ReqIDGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"allowedFunctions"}})
				EXPECT_HMIRESPONSE(ReqIDGetUserFriendlyMessage)
				:Do(function(_,data)
					print("SDL.GetUserFriendlyMessage is received")			
				end)
			end)
			self.mobileSession:ExpectResponse(CorIdSystemRequest, {success = true, resultCode = "SUCCESS"})
			end)
		end)
	end)
end

--[[ Postconditions ]]
commonFunctions:SDLForceStop()
