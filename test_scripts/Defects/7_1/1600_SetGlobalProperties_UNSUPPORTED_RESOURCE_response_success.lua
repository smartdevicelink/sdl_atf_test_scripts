---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/1600
---------------------------------------------------------------------------------------------------
-- Description: HMI responds with UNSUPPORTED_RESOURCE resultCode to SetGlobalProperties component
--
-- Preconditions:
-- 1) Clean environment
-- 2) SDL, HMI, Mobile session are started
-- 3) App is registered
-- 4) App is activated
--
-- Steps:
-- 1) Send SetGlobalProperties mobile RPC from app
-- 2) SDL sends to HMI UI.SetGlobalProperties() and TTS.SetGlobalProperties()
-- 3) HMI responds with SUCCESS to UI.SetGlobalProperties() request and responds
--    with UNSUPPORTED_RESOURCE + info("Error message") to TTS.SetGlobalProperties request
--
-- SDL does:
-- 1) Respond with 'SetGlobalProperties' (success = true, resultCode = "WARNINGS") to App
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local params = {
  helpPrompt = {
    {
      type = "SAPI_PHONEMES",
      text = "Text to Speak"
    }
  },
  menuTitle = "Hello, driver!"
}

--[[ Local Functions ]]
local function sendSetGlobalProperties()
  local mobileSession = common.mobile.getSession()
  local hmi = common.hmi.getConnection()

  local cid = mobileSession:SendRPC("SetGlobalProperties", params)
  hmi:ExpectRequest("UI.SetGlobalProperties")
  :Do(function(_, data)
      hmi:SendResponse(data.id, data.method, "SUCCESS", {})
    end)

  hmi:ExpectRequest("TTS.SetGlobalProperties")
  :Do(function(_, data)
      hmi:SendError(data.id, data.method, "UNSUPPORTED_RESOURCE", "Error message")
    end)

  mobileSession:ExpectResponse(cid, { success = true, resultCode = "WARNINGS"})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("App send SetGlobalProperties", sendSetGlobalProperties)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
