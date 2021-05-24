---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/1585
---------------------------------------------------------------------------------------------------
-- Description: HMI responds with UNSUPPORTED_RESOURCE resultCode to Navigation.AlertManeuver component
--
-- Preconditions:
-- 1) Clean environment
-- 2) SDL, HMI, Mobile session are started
-- 3) App is registered
-- 4) App is activated
--
-- Steps:
-- 1) Send AlertManeuver mobile RPC from app with parameter imageType = "STATIC"
-- 2) HMI responds with UNSUPPORTED_RESOURCE to Navigation.AlertManeuver request
--
-- SDL does:
-- 1) Respond with 'AlertManeuver'(success = true, resultCode = "UNSUPPORTED_RESOURCE") to App
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local params = {
  ttsChunks = {
    {
      type = "TEXT",
      text = "Text to Speak"
    }
  },
  softButtons = {
    {
      systemAction = "DEFAULT_ACTION",
      isHighlighted = true,
      softButtonID = 5517,
      type = "BOTH",
      image = {
        value = "icon.png",
        imageType = "STATIC"
      },
      text = "Close"
    }
  }
}

--[[ Local Functions ]]
local function sendAlertManeuver()
  local mobileSession = common.mobile.getSession()
  local hmi = common.hmi.getConnection()
  local dataToHMI = {
    softButtons = params["softButtons"],
    appID = common.app.getHMIId()
  }

  local cid = mobileSession:SendRPC("AlertManeuver", params)
  hmi:ExpectRequest("Navigation.AlertManeuver", dataToHMI)
  :Do(function(_, data)
      hmi:SendError(data.id, data.method, "UNSUPPORTED_RESOURCE", "Error message")
    end)

  hmi:ExpectRequest("TTS.Speak", { speakType = "ALERT_MANEUVER" })
  :Do(function(_, data)
      hmi:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  mobileSession:ExpectResponse(cid, { success = true, resultCode = "UNSUPPORTED_RESOURCE" })
end

local function pTUpdateFunc(tbl)
  tbl.policy_table.app_policies[common.app.getParams().fullAppID].groups = { "Base-4", "Navigation-1" }
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { pTUpdateFunc })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("App sends AlertManeuver", sendAlertManeuver)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
