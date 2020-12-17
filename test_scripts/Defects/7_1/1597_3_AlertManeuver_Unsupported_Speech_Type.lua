---------------------------------------------------------------------------------------------------
-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/1597
--
-- Description:
-- HMI responds with UNSUPPORTED_RESOURCE to Speak component of AlertManeuver
--
-- Preconditions:
-- 1) Clean environment
-- 2) SDL, HMI, Mobile session started
-- 3) Registered app
-- 4) Activated app
--
-- Steps: 
-- 1) Send AlertManeuver mobile RPC from app with ttsChunks, HMI responds with UNSUPPORTED_RESOURCE to 
--    Speak request
--
-- Expected:
-- 1) App receives AlertManeuver response with info from Speak response, WARNINGS result code, 
--    and success=true
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function pTUpdateFunc(tbl)
  local newGroup = {
    rpcs = {
      AlertManeuver = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED", "NONE"}
      }
    }
  }
  tbl.policy_table.functional_groupings["NewTestCaseGroup"] = newGroup
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].groups = {"Base-4", "NewTestCaseGroup"}
end

local function sendOnSystemContext(ctx, pWindowId, pAppId)
  if not pWindowId then pWindowId = 0 end
  if not pAppId then pAppId = 1 end
  common.getHMIConnection():SendNotification("UI.OnSystemContext",
  {
    appID = common.getHMIAppId(pAppId),
    systemContext = ctx,
    windowID = pWindowId
  })
end

local function sendAlertManeuver()
  local cid = common.getMobileSession():SendRPC("AlertManeuver", {
    ttsChunks = { 
      { type = "LHPLUS_PHONEMES", text = "phoneme" }
    }
  })
  common.getHMIConnection():ExpectRequest("Navigation.AlertManeuver")
  :Do(function(_, data)
      common.run.runAfter(function()
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      end, 2000)
    end)
  common.getHMIConnection():ExpectRequest("TTS.Speak")
  :Do(function(_, data)
      common.run.runAfter(function()
        common.getHMIConnection():SendError(data.id, data.method, "UNSUPPORTED_RESOURCE", "Error message from HMI")
      end, 1000)
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "WARNINGS", info = "Error message from HMI" })
end

--[[ Scenario ]]
runner.Title("Precondition")
runner.Step("Clean environment and Back-up/update PPT", common.preconditions)
runner.Step("Start SDL, HMI", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("RAI, PTU", common.policyTableUpdate, { pTUpdateFunc })
runner.Step("App activation", common.activateApp)

runner.Title("Test")
runner.Step("Alert Maneuver", sendAlertManeuver)

runner.Title("Postconditions")
runner.Step("Stop SDL, restore SDL settings and PPT", common.postconditions)
