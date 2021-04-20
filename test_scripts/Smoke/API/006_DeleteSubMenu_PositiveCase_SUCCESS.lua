---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: DeleteSubMenu
-- Item: Happy path
--
-- Requirement summary:
-- [DeleteSubMenu] SUCCESS: getting SUCCESS:UI.DeleteSubMenu() and all related UI or/and VR.DeleteCommand()
--
-- Description:
-- Mobile application sends valid DeleteSubMenu request and gets UI.DeleteSubMenu "SUCCESS" response from HMI

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level
-- d. SubMenu with related menuID was created

-- Steps:
-- appID requests DeleteSubMenu with valid parameters

-- Expected:
-- SDL validates parameters of the request
-- SDL checks if UI interface is available on HMI
-- SDL checks if DeleteSubMenu is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL transfers the UI part of request with allowed parameters to HMI
-- SDL receives UI part of response from HMI with "SUCCESS" result code
-- SDL responds with (resultCode: SUCCESS, success:true) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local addSubMenuRequestParams = {
  menuID = 1000,
  position = 500,
  menuName ="SubMenupositive"
}

local addSubMenuResponseUiParams = {
  menuID = addSubMenuRequestParams.menuID,
  menuParams = {
    position = addSubMenuRequestParams.position,
    menuName = addSubMenuRequestParams.menuName
  }
}

local addSubMenuAllParams = {
  requestParams = addSubMenuRequestParams,
  responseUiParams = addSubMenuResponseUiParams
}

local deleteSubMenuRequestParams = {
  menuID = addSubMenuRequestParams.menuID
}

--[[ Local Functions ]]
local function addSubMenu(pParams)
  local cid = common.getMobileSession():SendRPC("AddSubMenu", pParams.requestParams)

  pParams.responseUiParams.appID = common.getHMIAppId()
  common.getHMIConnection():ExpectRequest("UI.AddSubMenu", pParams.responseUiParams)
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getMobileSession():ExpectNotification("OnHashChange")
end

local function deleteSubMenu(pParams)
  local cid = common.getMobileSession():SendRPC("DeleteSubMenu", pParams)

  pParams.appID = common.getHMIAppId()
  common.getHMIConnection():ExpectRequest("UI.DeleteSubMenu", pParams)
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
runner.Step("AddSubMenu", addSubMenu, { addSubMenuAllParams })

runner.Title("Test")
runner.Step("DeleteSubMenu Positive Case", deleteSubMenu, { deleteSubMenuRequestParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
