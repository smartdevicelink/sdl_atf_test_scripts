---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: AddSubMenu
-- Item: Happy path
--
-- Requirement summary:
-- [AddSubMenu] SUCCESS: getting SUCCESS:UI.AddSubMenu()
--
-- Description:
-- Mobile application sends valid AddSubMenu request and gets UI.AddSubMenu "SUCCESS" response from HMI

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level

-- Steps:
-- appID requests AddSubMenu with valid parameters

-- Expected:
-- SDL validates parameters of the request
-- SDL checks if UI interface is available on HMI
-- SDL checks if AddSubMenu is allowed by Policies
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
local requestParams = {
  menuID = 1000,
  position = 500,
  menuName ="SubMenupositive"
}

local responseUiParams = {
  menuID = requestParams.menuID,
  menuParams = {
    position = requestParams.position,
    menuName = requestParams.menuName
  }
}

local allParams = {
  requestParams = requestParams,
  responseUiParams = responseUiParams
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

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("AddSubMenu Positive Case", addSubMenu, { allParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
