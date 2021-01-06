---------------------------------------------------------------------------------------------------
-- Proposal: SDL 0180 Broaden Choice Uniqueness
-- 
-- Description:
--   Mobile shall be able to send two AddCommand RPCs with identical menuName values.
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local menuParams = {
  position = 0,
  menuName = "menuName"
}

local requestParams1 = {
  cmdID = 499,
  menuParams = menuParams
}

local requestParams2 = {
  cmdID = 500,
  menuParams = menuParams
}

--[[ Local Functions ]]
local function addCommand(pParams)
  local cid = common.getMobileSession():SendRPC("AddCommand", pParams)

  local hmiRequestParams = { 
    cmdID = pParams.cmdID,
    menuParams = pParams.menuParams,
    appID = common.getHMIAppId()
  }
  common.getHMIConnection():ExpectRequest("UI.AddCommand", hmiRequestParams)
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getMobileSession():ExpectNotification("OnHashChange")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("AddCommand Positive Case", addCommand, { requestParams1 })
runner.Step("AddCommand With Same Menu Name", addCommand, { requestParams2 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
