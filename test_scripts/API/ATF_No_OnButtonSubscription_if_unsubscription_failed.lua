--Test = require('connecttest')
--require('cardinalities')
--local events = require('events')
--local mobile_session = require('mobile_session')
--local mobile  = require('mobile_connection')
--local tcp = require('tcp_connection')
--local file_connection  = require('file_connection')


--function Test:ActivationApp()
  --local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})

	--EXPECT_HMIRESPONSE(RequestId)
	--:Do(function(_,data)
    	--if
        	--data.result.isSDLAllowed ~= true then
            	--local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})

    			  --EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
	            --  :Do(function(_,data)
	    			    --hmi side: send request SDL.OnAllowSDLFunctionality
	    			  --  self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = 1, name = "127.0.0.1"}})
	            --  end)

          --  EXPECT_HMICALL("BasicCommunication.ActivateApp")
           -- :Do(function(_,data)
		 --         self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
		   --     end)
		--end
     -- end)

  	--EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL"})	

--end


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

DeleteLog_app_info_dat_policy()


--UPDATED
function UpdateHMICapabilities()
    commonPreconditions:BackupFile("hmi_capabilities.json")

    local src      = config.pathToSDL .."hmi_capabilities.json"
    local dest     = "files/hmi_capabilities_SearchButton.json"
    
    local filecopy = "cp " .. dest .."  " .. src

    os.execute(filecopy)
end

UpdateHMICapabilities()


--------------------------------------------------------------------------------
--Precondition: preparation connecttest_OnButton.lua
commonPreconditions:Connecttest_without_ExitBySDLDisconnect("connecttest_OnButton.lua")
commonPreconditions:Connecttest_OnButtonSubscription("connecttest_OnButton.lua")
--Precondition: preparation connecttest_OnButton.lua
	f = assert(io.open('./user_modules/connecttest_OnButton.lua', "r"))

	fileContent = f:read("*all")
	f:close()

	local pattern2 = "%{%s-capabilities%s-=%s-%{.-%}"
	local pattern2Result = fileContent:match(pattern2)

	if pattern2Result == nil then 
		print(" \27[31m capabilities array is not found in /user_modules/connecttest_OnButton.lua \27[0m ")
	else
		fileContent  =  string.gsub(fileContent, pattern2, '{capabilities = {button_capability("PRESET_0"),button_capability("PRESET_1"),button_capability("PRESET_2"),button_capability("PRESET_3"),button_capability("PRESET_4"),button_capability("PRESET_5"),button_capability("PRESET_6"),button_capability("PRESET_7"),button_capability("PRESET_8"),button_capability("PRESET_9"),button_capability("OK", true, false, true),button_capability("PLAY_PAUSE"),button_capability("SEEKLEFT"),button_capability("SEEKRIGHT"),button_capability("TUNEUP"),button_capability("TUNEDOWN"),button_capability("CUSTOM_BUTTON")}')
	end

	f = assert(io.open('./user_modules/connecttest_OnButton.lua', "w+"))
	f:write(fileContent)
	f:close()

Test = require('user_modules/connecttest_OnButton')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')

local iTimeout = 5000
local buttonName = {"OK","PLAY_PAUSE","SEEKLEFT","SEEKRIGHT","TUNEUP","TUNEDOWN", "PRESET_0","PRESET_1","PRESET_2","PRESET_3","PRESET_4","PRESET_5","PRESET_6","PRESET_7","PRESET_8"}
local buttonNameNonMediaApp = {"OK", "PRESET_0","PRESET_1","PRESET_2","PRESET_3","PRESET_4","PRESET_5","PRESET_6","PRESET_7","PRESET_8"}
local UnsupportButtonName = {"PRESET_9", "SEARCH"}

config.deviceMAC      = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2

local str1000Chars = 
	"10123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyza b c                                 aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	

local info = {nil, "unused"}
local OutBound = {"a", "nonexistButton", str1000Chars}
local OutBoundName = {"OneCharacter", "nonexistButton", "String1000Characters"}

local resultCode = {"SUCCESS", "INVALID_DATA", "OUT_OF_MEMORY", "TOO_MANY_PENDING_REQUESTS", "APPLICATION_NOT_REGISTERED", "REJECTED", "IGNORED", "GENERIC_ERROR", "UNSUPPORTED_RESOURCE", "DISALLOWED"}

local success = {true, false, false, false, false, false, false, false, false, false}

local appID0, appId1, appId2

-- Common functions

function ActivateApplication(self, strAppName)
	--HMI send ActivateApp request

	local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[strAppName]})
	EXPECT_HMIRESPONSE(RequestId)
	:Do(function(_,data)
		if data.result.isSDLAllowed ~= true then
			local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
			EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
			:Do(function(_,data)
				--hmi side: send request SDL.OnAllowSDLFunctionality
				self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})

				EXPECT_HMICALL("BasicCommunication.ActivateApp")
					:Do(function(_,data)
						self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
					end)
					:Times(2)
			end)
		end
	end)

	EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"}) 
	:Timeout(12000)

end

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
	--Begin Precondition.1
	-- Description: removing user_modules/connecttest_OnButton.lua
	function Test:Remove_user_connecttest()
	 	os.execute( "rm -f ./user_modules/connecttest_OnButton.lua" )
	end
	--End Precondition.1

	--Begin Precondition.2
	--Description: Activation App by sending SDL.ActivateApp

		function Test:Activate_Media_Application()
			--HMI send ActivateApp request			
			ActivateApplication(self, config.application1.registerAppInterfaceParams.appName)
		end

	--End Precondition.2

	-----------------------------------------------------------------------------------------


--UnsubscribeButton suit of tests is intended to check sending
--appropriate request with different conditions for parameter
--and receiving proper responses (CRQ APPLINK-11266)-->


-- Test suit 1 "Positive cases and in boundary conditions" 

-- This test is intended to check positive cases and when all parameters 
-- are in boundary conditions 

-- 1.1 Positive case and in boundary conditions 
function Test:UnsubscribeButton_INVALID_DATA()
	--request from mobile side
	local CorIdUnsubscribeButton = self.mobileSession:SendRPC("UnsubscribeButton",
		{
		  buttonName = "PRESET_15"
		})

	--hmi side: request, response
	EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription")
		:Timeout(1000)
		:Times(0)

	--response on mobile side
	EXPECT_RESPONSE(CorIdUnsubscribeButton, { success = false, resultCode = "INVALID_DATA"})
		:Timeout(1000)
end

function Test:UnsubscribeButton_UNSUPPORTED_RESOURCE()
	--request from mobile side
	local CorIdUnsubscribeButton = self.mobileSession:SendRPC("UnsubscribeButton",
		{
			buttonName = "SEARCH"
		  --buttonName = "PRESET_9"
		})

	--hmi side: request, response
	EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription")
		:Timeout(1000)
		:Times(0)

	--response on mobile side
	EXPECT_RESPONSE(CorIdUnsubscribeButton, { success = false, resultCode = "UNSUPPORTED_RESOURCE"})
		:Timeout(1000)
end

--UPDATED
function Test:PreconditionSubscribeButton_IGNORED()
	--request from mobile side
	local CorIdSubscribeButton = self.mobileSession:SendRPC("SubscribeButton",
		{
		  buttonName = "PRESET_1"
		})

	--hmi side: request, response
	EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription")
		:Timeout(1000)
		:Times(1)

	--response on mobile side
	EXPECT_RESPONSE(CorIdSubscribeButton, { success = true, resultCode = "SUCCESS"})
		:Timeout(1000)
end

--UPDATED
function Test:PreconditionUnsubscribeButton_IGNORED()
	--request from mobile side
	local CorIdUnsubscribeButton = self.mobileSession:SendRPC("UnsubscribeButton",
		{
		  buttonName = "PRESET_1"
		})

	--hmi side: request, response
	EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription")
		:Timeout(1000)
		:Times(1)

	--response on mobile side
	EXPECT_RESPONSE(CorIdUnsubscribeButton, { success = true, resultCode = "SUCCESS"})
		:Timeout(10000)
end
		
function Test:UnsubscribeButton_IGNORED()		
	--request from mobile side
	local CorIdUnsubscribeButton = self.mobileSession:SendRPC("UnsubscribeButton",
		{
		  buttonName = "PRESET_1"
		})

	--hmi side: request, response
	EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription")
		:Timeout(1000)
		:Times(0)

	--response on mobile side
	EXPECT_RESPONSE(CorIdUnsubscribeButton, { success = false, resultCode = "IGNORED"})
		:Timeout(1000)
end


---------------------------------------------------------------------------------------------
-------------------------------------------Postconditions-------------------------------------
---------------------------------------------------------------------------------------------

function Test:RemoveConfigurationFiles()
    commonPreconditions:RestoreFile("hmi_capabilities.json")
end
