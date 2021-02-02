---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/2353
---------------------------------------------------------------------------------------------------
-- Description: Check SDL is able to proceed with response from HMI after cut off of fake parameters
-- Scenario: response that SDL should transfer to mobile app
--
-- Steps:
-- 1. App sends request to SDL
-- SDL does:
--  - transfer this request to HMI
-- 2. HMI responds with fake parameter
-- SDL does:
--  - cut off fake parameters
--  - check whether response is valid
--  - proceed with response in case if it's valid and transfer it to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function ptUpdate(pTbl)
  pTbl.policy_table.app_policies[common.app.getParams().fullAppID].groups = { "Base-4", "PropriataryData-1" }
end

local function sendReadDID()
  local params = {
    ecuName = 2000,
    didLocation = {
      56832
    }
  }
  local exp = {
    didResult = {
      {
        resultCode = "SUCCESS",
        didLocation = params.didLocation[1],
        data = "some_data"
      }
    }
  }
  local dataFromHMI = utils.cloneTable(exp)
  dataFromHMI.didResult[1].fakeParam = "123"
  local cid = common.getMobileSession():SendRPC("ReadDID", params)
  common.getHMIConnection():ExpectRequest("VehicleInfo.ReadDID")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", dataFromHMI)
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS", didResult = exp.didResult })
  :ValidIf(function(_, data)
      if data.payload.didResult[1].fakeParam then
        return false, "Unexpected 'fakeParam' is received"
      end
      return  true
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect regular mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { ptUpdate })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("App sends ReadDID", sendReadDID)

runner.Title("Postconditions")
runner.Step("Stop SDL, restore SDL settings and PPT", common.postconditions)
