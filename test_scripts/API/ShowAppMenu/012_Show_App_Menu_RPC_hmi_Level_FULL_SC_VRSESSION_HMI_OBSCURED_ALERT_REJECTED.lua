---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0116-open-menu.md
-- Description:
-- In case:
-- 1) Mobile application is set to appropriate HMI level and System Context (FULL: VRSESSION, HMI_OBSCURED, ALERT)
-- 2)Mobile sends ShowAppMenu request without menuID parameter to SDL
-- SDL does:
-- 1) not send ShowAppMenu request to HMI
-- 2) send ShowAppMenu response with resultCode = REJECTED to mobile
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/ShowAppMenu/commonShowAppMenu')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.appHMIType = { "PROJECTION" }

--[[ Local Variables ]]
local resultCode = "REJECTED"

--[[ Local Function ]]
local function sendAlertSuccess()
  local cid = common.getMobileSession():SendRPC("Alert", {
    alertText1 = "a",
    alertText2 = "1",
    alertText3 = "_",
    duration = 6000
  })
  common.getHMIConnection():ExpectRequest("UI.Alert", {
    alertStrings = {
      {fieldName = "alertText1", fieldText = "a"},
      {fieldName = "alertText2", fieldText = "1"},
      {fieldName = "alertText3", fieldText = "_"}
    }
  })
  :Do(function(_,data)
    common.showAppMenuUnsuccess(nil, resultCode)
    local function alertResponse()
      common.getHMIConnection():SendResponse(data.id, "UI.Alert", "SUCCESS", { })
    end
    RUN_AFTER(alertResponse, 2000)
  end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("App activate, HMI SystemContext MAIN", common.activateApp)

runner.Title("Test")
runner.Step("Set HMI SystemContext to VRSESSION" , common.changeHMISystemContext, { "VRSESSION" })
runner.Step("Send show app menu", common.showAppMenuUnsuccess, { nil, resultCode })

runner.Step("Set HMI SystemContext to HMI_OBSCURED" , common.changeHMISystemContext, { "HMI_OBSCURED" })
runner.Step("Send show app menu", common.showAppMenuUnsuccess, { nil, resultCode })

runner.Step("Send show App menu, SystemContext ALERT", sendAlertSuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
