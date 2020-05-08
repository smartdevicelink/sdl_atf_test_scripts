---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2379
--
-- Description:
-- 1. SDL does not respond NACK on second service.
-- Steps to reproduce:
-- 1 First service started as Protected.
-- 1 Start video sreaming.
-- 1 Second service starting as Protected.
-- Expected:
-- 1. SDL respond NACK on second service.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Security/DTLS/common')
local runner = require('user_modules/script_runner')
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }

-- [[ Local functions ]]
local function startServiceProtectedSecond(pServiceId)
  common.getMobileSession():StartSecureService(pServiceId)
  common.getMobileSession():ExpectHandshakeMessage()
  :Times(0)
  common.getMobileSession():ExpectControlMessage(pServiceId, {
    frameInfo = common.frameInfo.START_SERVICE_NACK,
    encryption = false
  })
  common.getMobileSession():ExpectNotification("OnAppInterfaceUnregistered")
  :Times(0)
  utils.wait(7000)
end

local function appStartVideoStreaming(pServiceId)
    common.getHMIConnection():ExpectRequest("Navigation.StartStream")
    :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
        common.getMobileSession():StartStreaming(pServiceId, "files/SampleVideo_5mb.mp4")
        common.getHMIConnection():ExpectNotification("Navigation.OnVideoDataStreaming", { available = true })
    end)
  common.getMobileSession():ExpectNotification("OnHMIStatus")
  :Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set DTLS protocol in SDL", common.setSDLIniParameter, { "Protocol", "DTLSv1.0" })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Policy Table Update Certificate", common.policyTableUpdate, { common.ptUpdate })
runner.Step("Activate App", common.activateApp)

-- [[ Test ]]
runner.Title("Test")
runner.Step("Start Protected Service", common.startServiceProtected, { 11 })
runner.Step("Start Stream", appStartVideoStreaming, { 11 })
runner.Step("Start second Protected Service", startServiceProtectedSecond, { 11 })

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL, restore SDL settings", common.postconditions)
