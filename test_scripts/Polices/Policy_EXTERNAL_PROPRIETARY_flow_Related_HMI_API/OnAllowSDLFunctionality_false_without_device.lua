---------------------------------------------------------------------------------------------
-- Description: 
--     1. Preconditions: App is registered
--     2. Steps: Activate App, send SDL.OnAllowSDLFunctionality with 'allowed=false' and without 'device' to HMI
-- Requirement summary: 
--     [Policy] "EXTERNAL_PROPRIETARY" flow: Related HMI API
--     [Policies]: OnAllowSDLFunctionality with 'allowed=false' and without 'device' param from HMI
--
-- Expected result:
--     In case PoliciesManager receives SDL.OnAllowSDLFunctionality with 'allowed=false' and without 'device' param from HMI, PoliciesManager must record 
--     all of currently registered devices as NOT consented in Local PT ("device_data" - > "<device_id_1>", "<device_id_2>", etc. - >"user_consent_records"- > "device" sub-section).
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
  config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
  local commonSteps = require('user_modules/shared_testcases/commonSteps')
--[[ General Precondition before ATF start ]]
  commonSteps:DeleteLogsFileAndPolicyTable()
--[[ Required Shared libraries ]]
  local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
--[[ General Settings for configuration ]]
  Test = require('connecttest') 
--[[ Preconditions ]]
-- commonFunctions:newTestCasesGroup("Preconditions")

--[[ Test ]]
--commonFunctions:newTestCasesGroup("Test")
Test["TestStep_RegisterApp_AllowedFalse_deviceOmitted"] = function(self)
   -- HMI -> SDL: SDL.ActivateApp
  RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = applicationID})
  -- SDL -> HMI: SDL.ActivateApp {isSDLAllowed: false, device is omitted}
  EXPECT_HMIRESPONSE(RequestId,{isSDLAllowed = false, method = "SDL.ActivateApp"})
    -- HMI -> SDL: SDL.GetUserFriendlymessage {messageCodes: DataConsent}
    local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", 
      {language = "EN-US", messageCodes = {"DataConsent"}})
    -- SDL -> HMI: SDL.GetUserFriendlymessage {messages}
    EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
      -- HMI -> SDL: SDL.OnAllowSDLFunctionality {allowed: false, device is omitted, source}
      self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", 
      {allowed = false, source = "GUI"})
      -- SDL -> MOB: OnPermissionChange
      self.mobileSession:ExpectNotification("OnPermissionsChange", {})
      -- SDL -> HMI: BC.ActivateApp {level:<"default_hmi" from "pre_DataConsent" section>, params}
      EXPECT_HMICALL("BasicCommunication.ActivateApp")
        :Do(function(_,data)
          --hmi side: sending BasicCommunication.ActivateApp response
          self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
        end)
  -- SDL -> MOB: OnHMIStatus {HMILevel:<"defaultHMI" from "pre_DataConsent" section>, params}
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", systemContext = "MAIN"}) 
end
--function checks if device_id was updated in local PT
Test["TestStep_CheckValueOfDeviseID"] = function(self)
device_id = get_id_value(self)
  print (device_id)  
  if (device_id == 0) then
    self:FailTestCase("device_id in database was not updated")
  end
end

--[[ Postconditions ]]
Test["Postcondition_ForceStipSDL"] = function(self)
   commonFunctions:SDLForceStop()
end

return Test 