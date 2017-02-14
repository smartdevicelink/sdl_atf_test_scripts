---------------------------------------------------------------------------------------------
-- Description: 
--     1. Preconditions: App is registered
--     2. Steps: Activate App, send SDL.OnAllowSDLFunctionality with 'allowed=true' and with 'device' to HMI
-- Requirement summary: 
--     [Policy] "EXTERNAL_PROPRIETARY" flow: Related HMI API
--     [Policies]: OnAllowSDLFunctionality with 'allowed=true' and with 'device' param from HMI
--
-- Expected result:
--     In case PoliciesManager receives _SDL.OnAllowSDLFunctionality_ with *'allowed=true'* and with *'device'* param from HMI, PoliciesManager must 
--     record the named device ('device' param) as consented in Local PT ("device_data"  section <device_id> subsection "user_consent_records"->"device" sub-section).
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
  config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
  local commonSteps = require('user_modules/shared_testcases/commonSteps')
require('cardinalities')
--[[ Local Functions ]]
local function get_id_value() 
  local sql_select = "sqlite3 " .. tostring(SDLStoragePath) .. "policy.sqlite \"SELECT id FROM functional_group WHERE name = \"BaseBeforeDataConsent\"\""
    local aHandle = assert( io.popen( sql_select , 'r'))
    sql_output = aHandle:read( '*l' )   
    local retvalue = tonumber(sql_output)    
    if (retvalue == nil) then
       self:FailTestCase("device id can't be read")
    else 
      return retvalue
    end
end
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
Test["TestStep_ActivateApp_AllowedFalse_deviceOmitted"] = function(self)
  -- HMI -> SDL: SDL.ActivateApp
  RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = applicationID})
  -- SDL -> HMI: SDL.ActivateApp {isSDLAllowed: false, device is omitted}
  EXPECT_HMIRESPONSE(RequestId,{isSDLAllowed = false, method = "SDL.ActivateApp"})
    -- HMI -> SDL: SDL.GetUserFriendlymessage {messageCodes: DataConsent}
    local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", 
      {language = "EN-US", messageCodes = {"DataConsent"}})
    -- SDL -> HMI: SDL.GetUserFriendlymessage {messages}
    EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
      -- HMI -> SDL: SDL.OnAllowSDLFunctionality {allowed: true, device, source}
      self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", 
      {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
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

Test["TestStep_CheckValueOfDeviceID"] = function(self)
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