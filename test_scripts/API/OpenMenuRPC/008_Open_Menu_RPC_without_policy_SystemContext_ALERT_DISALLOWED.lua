---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0116-open-menu.md
-- Description:
-- In case:
-- 1) Mobile application is set to appropriate HMI level and System Context ALERT
-- 2) ShowAppMenu RPC is not allowed by policy
-- 3) Mobile sends ShowAppMenu request without menuID parameter to SDL
-- SDL does:
-- 1) not send ShowAppMenu request to HMI
-- 2) send ShowAppMenu response with resultCode = DISALLOWED to mobile
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/OpenMenuRPC/commonOpenMenuRPC')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.appHMIType = { "PROJECTION" }

--[[ Local Variables ]]
local resultCode = "DISALLOWED"

--[[ Local Function ]]
local function pTUpdateFunc(pTbl)
  pTbl.policy_table.functional_groupings["Base-4"].rpcs.ShowAppMenu = nil
  pTbl.policy_table.functional_groupings["Base-4"].rpcs["Alert"].hmi_levels = {
    "FULL",
    "BACKGROUND",
    "LIMITED"
  }
end

local function sendAlertSuccess()
  common.getMobileSession():SendRPC("Alert", {
    alertText1 = "a",
    alertText2 = "1",
    alertText3 = "_",
    ttsChunks = {
      {
        text = "TTSChunk",
        type = "TEXT"
      }
    },
    duration = 6000
  })
  local AlertId
  common.getHMIConnection():ExpectRequest("UI.Alert", {
    alertStrings = {
      {fieldName = "alertText1", fieldText = "a"},
      {fieldName = "alertText2", fieldText = "1"},
      {fieldName = "alertText3", fieldText = "_"}
    }
  })
  :Do(function(_,data)
    common.showAppMenuUnsuccess(nil, resultCode)
    AlertId = data.id
  end)
  common.getHMIConnection():SendResponse(AlertId, "UI.Alert", "SUCCESS", { })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { pTUpdateFunc })
runner.Step("App activate", common.activateApp)

runner.Title("Test")
runner.Step("Send show App menu, SystemContext ALERT", sendAlertSuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
