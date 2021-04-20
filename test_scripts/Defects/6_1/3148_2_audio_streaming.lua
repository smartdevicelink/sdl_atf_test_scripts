---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3148

-- In case:
-- 1. Navigation app is registered and activated
-- 2. Audio streaming is started
-- 3. Wait some time
-- 4. Audio streaming is restarted
-- SDL does:
--   a) send Navigation.OnAudioDataStreaming(available=false) by streaming finish
--   b) send Navigation.OnAudioDataStreaming(available=true) by streaming start
-- 5. Mobile app adds AddSubMenu
-- SDL does:
--   a) send UI.AddSubMenu request to HMI
--   b) resend UI.AddSubMenu response from HMI to mobile app
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Apps Configuration ]]
common.app.getParams(1).appHMIType = { "NAVIGATION" }

--[[ Local Variables ]]
local timeToWait = 30 -- in sec.
local audioStreamServiceId = 10
local audioDataStoppedTimeout = 500

--[[ Local Functions ]]
local function startStreaming(pServiceId)
  local msg = {
    frameInfo = 0,
    frameType = 1,
    serviceType = pServiceId,
    binaryData = "123"
  }
  local function sendStreamData()
    common.getMobileSession():Send(msg)
  end
  sendStreamData()
  common.getHMIConnection():ExpectNotification("Navigation.OnAudioDataStreaming")
  :Do(function(_, data)
      if data.params.available == false then
        sendStreamData()
        RUN_AFTER(sendStreamData, audioDataStoppedTimeout)
      end
    end)
  :Times(AnyNumber())
  utils.cprint(35, "Wait " .. timeToWait .. " seconds...")
  utils.wait(timeToWait * 1000 + 1000)
end

local function startService(pServiceId)
  common.getMobileSession():StartService(pServiceId)
  common.getHMIConnection():ExpectRequest("Navigation.StartAudioStream")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      startStreaming(pServiceId)
  end)
end

local function sendAddSubMenu()
  local requestParams = {
    menuID = 1000,
    position = 500,
    menuName ="SubMenupositive"
  }
  local corId = common.getMobileSession():SendRPC("AddSubMenu", requestParams)
  common.getHMIConnection():ExpectRequest("UI.AddSubMenu")
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  common.getMobileSession():ExpectResponse(corId, { success = true, resultCode = "SUCCESS"})
  common.getMobileSession():ExpectNotification("OnHashChange")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set AudioDataStoppedTimeout=500 in ini file", common.setSDLIniParameter,
  { "AudioDataStoppedTimeout", audioDataStoppedTimeout })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Policy Table Update", common.policyTableUpdate)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Start audio service", startService, { audioStreamServiceId })
runner.Step("AddSubMenu", sendAddSubMenu)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
