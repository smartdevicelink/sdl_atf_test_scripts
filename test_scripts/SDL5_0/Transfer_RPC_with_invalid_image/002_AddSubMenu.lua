---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0042-transfer-invalid-image-rpc.md
--
-- Requirement summary:TBD
--
-- Description:
-- In case:
-- 1. Mobile app requests AddSubMenu with image that is absent on file system
-- SDL must:
-- 1. transfer this RPC to HMI for processing
-- 2. transfer the received from HMI response (WARNINGS, message: “Requested image(s) not found”) to mobile app
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/SDL5_0/Transfer_RPC_with_invalid_image/common')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParams = {
  menuID = 1000,
  position = 500,
  menuName ="SubMenupositive",
  menuIcon = {
    value ="missed_icon.png",
    imageType ="DYNAMIC"
  }
}

local requestUiParams = {
  menuID = requestParams.menuID,
  menuParams = {
    position = requestParams.position,
    menuName = requestParams.menuName
  },
  menuIcon = requestParams.menuIcon
}

local allParams = {
  requestParams = requestParams,
  requestUiParams = requestUiParams
}

--[[ Local Functions ]]
local function addSubMenu(pParams)
  local cid = common.getMobileSession():SendRPC("AddSubMenu", pParams.requestParams)
  pParams.requestUiParams.menuIcon.value = common.getPathToFileInStorage(requestParams.menuIcon.value)
  pParams.requestUiParams.appID = common.getHMIAppId()
  EXPECT_HMICALL("UI.AddSubMenu", pParams.requestUiParams)
  :Do(function(_,data)
    common.getHMIConnection():SendError(data.id, data.method, "WARNINGS", "Requested image(s) not found")
  end)

  common.getMobileSession():ExpectResponse(cid,
    { success = true, resultCode = "WARNINGS", info = "Requested image(s) not found" })
  common.getMobileSession():ExpectNotification("OnHashChange")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("AddSubMenu with invalid image", addSubMenu, { allParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
