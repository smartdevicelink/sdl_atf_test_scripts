--------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/1619
---------------------------------------------------------------------------------------------------
-- Description: HMI responds with valid AlertManeuver response (empty parameter "info")
-- to the request RPC AlertManeuer with empty softbuttons
--
-- Preconditions:
-- 1) Clean environment
-- 2) SDL, HMI, Mobile session are started
-- 3) App is registered
-- 4) PTU has been performed
-- 5) App is activated
--
-- Steps:
-- 1) Send AlertManeuver mobile RPC from app with parameter softButtons = []
-- 2) HMI responds with SUCCESS to Navigation.AlertManeuver request
--
-- SDL does:
-- 1) respond with AlertManeuver(success = true, resultCode = "SUCCESS")
--    and missing parameter "info" to App
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local params = {
  softButtons = common.json.EMPTY_ARRAY
}

--[[ Local Functions ]]
local function sendAlertManeuver()
  local mobileSession = common.mobile.getSession()
  local hmi = common.hmi.getConnection()
  local dataToHMI = {
    softButtons = nil,
    appID = common.app.getHMIId()
  }

  local cid = mobileSession:SendRPC("AlertManeuver", params)
  hmi:ExpectRequest("Navigation.AlertManeuver", dataToHMI)
  :Do(function(_, data)
      hmi:SendResponse(data.id, data.method, "SUCCESS", {})
    end)

  mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :ValidIf(function(_,data)
    if data.payload.info then
      return false, "Mobile response contains not expected info param"
    end
    return true
  end)
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
