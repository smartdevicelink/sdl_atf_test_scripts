---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2446
--
-- Description:
-- In smartDeviceLink.ini file: set ApplicationResumingTimeout = 5000
-- Steps to reproduce:
-- 1) Register Non-Media app
-- 2) Activate app
-- 3) Ignition Off
-- 4) Ignition On
-- 5) Register APP (in step 1) and set Deactivate_HMI=true
-- 6) Wait more than 5 seconds and set Deactivate_HMI = false
-- Expected:
-- 1) App is resumed to HMI level FULL
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local utils = require("user_modules/utils")
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local test = require("user_modules/dummy_connecttest")

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }
config.application1.registerAppInterfaceParams.isMediaApplication = false

-- [[ Local Functions ]]
local function updateSDLfile()
  commonFunctions:write_parameter_to_smart_device_link_ini("ApplicationResumingTimeout", 5000)
end

local function cleanSessions()
  for i = 1, common.getAppsCount() do
    test.mobileSession[i] = nil
  end
  utils.wait()
end

local function ignitionOff()
  common.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
    common.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "IGNITION_OFF" })
    common.getMobileSession():ExpectNotification("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
    common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
    common.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose")
    :Do(function()
      StopSDL()
    end)
  end)
end

local function registerAppWithDeactivatedHMI(pAppId)
  if not pAppId then pAppId = 1 end
  common.getMobileSession(pAppId):StartService(7)
  :Do(function()
    local corId = common.getMobileSession(pAppId):SendRPC("RegisterAppInterface", common.getConfigAppParams(pAppId))
    common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
      { application = { appName = common.getConfigAppParams(pAppId).appName } })
      :Do(function(_, d1)
        common.setHMIAppId(d1.params.application.appID, pAppId)
      end)
      common.getMobileSession(pAppId):ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
    :Do(function()
      common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
        { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
        common.getMobileSession(pAppId):ExpectNotification("OnPermissionsChange")
      :Times(AnyNumber())
    end)
  end)
utils.wait(6000)
end

local function hmiDeactivation()
  common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged", { eventName = "DEACTIVATE_HMI", isActive = true })
end

local function checkResumingActivationApp()
  common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged", { eventName = "DEACTIVATE_HMI", isActive = false })
  common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp", {})
  :Do(function(_,data)
    common.getHMIConnection():SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
  end)
  common.getMobileSession():ExpectNotification("OnHMIStatus", { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })

end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Replase parameter in smartDeviceLink.ini file", updateSDLfile)
runner.Step("Start SDL, init HMI, connect Mobile", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("ShutDown IGNITION_OFF", ignitionOff)
runner.Step("Clean sessions", cleanSessions)
runner.Step("Start SDL, init HMI, connect Mobile", common.start)

-- [[ Test ]]
runner.Title("Test")
runner.Step("Deactivate HMI", hmiDeactivation)
runner.Step("Reregister App", registerAppWithDeactivatedHMI)
runner.Step("Activate HMI and check resuming activate App", checkResumingActivationApp)

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
