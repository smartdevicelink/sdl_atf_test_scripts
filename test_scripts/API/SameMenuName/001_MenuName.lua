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

local requestParams3 = {
  menuID = 699,
  menuName = "menuName"
}

local requestParams4 = {
  menuID = 700,
  menuName = "menuName"
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

local function addSubMenu(pParams)
  local cid = common.getMobileSession():SendRPC("AddSubMenu", pParams)

  local hmiRequestParams = {
    menuID = pParams.menuID,
    appID = common.getHMIAppId()
  }
  common.getHMIConnection():ExpectRequest("UI.AddSubMenu", hmiRequestParams)
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
runner.Step("AddSubMenu With Same Menu Name", addSubMenu, { requestParams3 })
runner.Step("AddSubMenu Again With Same Menu Name", addSubMenu, { requestParams4 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
