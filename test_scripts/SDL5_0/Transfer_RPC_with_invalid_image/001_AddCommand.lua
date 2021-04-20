---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0042-transfer-invalid-image-rpc.md
--
-- Requirement summary:TBD
--
-- Description:
-- In case:
-- 1. Mobile app requests AddCommand with image that is absent on file system
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
  menuParams = {
    position = 0,
    menuName ="Commandpositive"
  },
  cmdIcon = {
    value = "missed_icon.png",
    imageType = "DYNAMIC"
  }
}

local requestUiParams = {
  cmdID = requestParams.cmdID,
  cmdIcon = requestParams.cmdIcon,
  menuParams = requestParams.menuParams
}

local requestVrParams = {
  cmdID = requestParams.cmdID,
  type = "Command",
  vrCommands = requestParams.vrCommands
}

local allParams = {
  requestParams = requestParams,
  responseUiParams = requestUiParams,
  responseVrParams = requestVrParams
}

--[[ Local Functions ]]
local function addCommand(pId, pParams)
  pParams.requestParams.cmdID = pId
  pParams.requestParams.menuParams.menuName = requestParams.menuParams.menuName .. pId
  pParams.responseUiParams.cmdIcon.value = common.getPathToFileInStorage("missed_icon.png")
  pParams.responseUiParams.appID = common.getHMIAppId()

  local cid = common.getMobileSession():SendRPC("AddCommand", pParams.requestParams)

  EXPECT_HMICALL("UI.AddCommand", pParams.responseUiParams)
  :Do(function(_,data)
      common.getHMIConnection():SendError(data.id, data.method, "WARNINGS", "Requested image(s) not found")
    end)

  common.getMobileSession():ExpectResponse(cid,
    { success = true, resultCode = "WARNINGS", info = "Requested image(s) not found" })

  common.getMobileSession():ExpectNotification("OnHashChange")
end

local function addCommandVR(pId, pParams)
  pParams.requestParams.cmdID = pId
  pParams.requestParams.menuParams.menuName = requestParams.menuParams.menuName .. pId
  pParams.responseUiParams.cmdIcon.value = common.getPathToFileInStorage("missed_icon.png")
  pParams.responseUiParams.appID = common.getHMIAppId()
  pParams.requestParams.vrCommands = {
    "VRCommandonepositive",
    "VRCommandonepositivedouble"
  }
  pParams.responseVrParams.appID = common.getHMIAppId()

  EXPECT_HMICALL("VR.AddCommand", pParams.responseVrParams)
  :Do(function(_,data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  :ValidIf(function(_,data)
      if data.params.grammarID ~= nil then
        return true
      else
        return false, "grammarID should not be empty"
      end
    end)


  local cid = common.getMobileSession():SendRPC("AddCommand", pParams.requestParams)

  EXPECT_HMICALL("UI.AddCommand", pParams.responseUiParams)
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
runner.Step("AddCommand with invalid image only UI interface", addCommand, { 1, allParams })
runner.Step("AddCommand with invalid image with VR interface", addCommandVR, { 2, allParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
