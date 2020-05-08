---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2379
--
-- Description:
-- 1) SDL does not respond ACK on second service.
-- Steps to reproduce:
-- 1) First service started as NOT Protected.
-- 2) Start video sreaming.
-- 3) Second service starting as  Protected.
-- Expected:
-- 1) SDL respond ACK on second service and will continuous stream through the encrypted channel.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Security/DTLS/common')
local runner = require('user_modules/script_runner')
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local functions ]]
local function appStartVideoStreamingNotProtected(pServiceId)
  common.getMobileSession():StartService(pServiceId)
  common.getHMIConnection():ExpectRequest("Navigation.StartStream")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      common.getMobileSession():StartStreaming(pServiceId, "files/SampleVideo_5mb.mp4")
      common.getHMIConnection():ExpectNotification("Navigation.OnVideoDataStreaming", { available = true })
  end)
  common.getMobileSession():ExpectNotification("OnHMIStatus")
  :Times(0)
end

local function startServiceProtectedSecond(pServiceId)
  common.getMobileSession():StartSecureService(pServiceId)
  common.getMobileSession():ExpectHandshakeMessage()
  :Times(1)
  common.getMobileSession():ExpectControlMessage(pServiceId, {
    frameInfo = common.frameInfo.START_SERVICE_ACK,
    encryption = true
  })
  common.getMobileSession():ExpectNotification("OnAppInterfaceUnregistered")
  :Times(0)
  utils.wait(10000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set DTLS protocol in SDL", common.setSDLIniParameter, { "Protocol", "DTLSv1.0" })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Policy Table Update Certificate", common.policyTableUpdate, { common.ptUpdate })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Start Service NOT protected and start Stream", appStartVideoStreamingNotProtected, { 11 })
runner.Step("Start Protected Service protected", startServiceProtectedSecond, { 11 })

runner.Title("Postconditions")
runner.Step("Stop SDL, restore SDL settings", common.postconditions)
