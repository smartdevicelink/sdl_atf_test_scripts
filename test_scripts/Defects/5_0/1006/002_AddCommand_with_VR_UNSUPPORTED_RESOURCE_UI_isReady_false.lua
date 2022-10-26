---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/1006
---------------------------------------------------------------------------------------------------
-- Description: SDL sends AddCommand response with UNSUPPORTED_RESOURCE, success:true for UI/VR-related RPC
--  in case HMI responds UI.IsReady with "available" = false
--
-- Precondition:
-- 1. SDL and HMI are started.
-- 2. HMI responds with 'available' = false on UI.IsReady request from SDL
-- 3. App is registered and activated
-- Steps:
-- 1. App requests AddCommand with UI and VR parts to SDL
-- SDL does:
-- - not send UI.AddCommand request to HMI
-- - send VR.AddCommand request to HMI
-- - respond AddCommand(resultCode: UNSUPPORTED_RESOURCE, success: true) to App
-- 2. App requests AddCommand with only VR part to SDL
-- SDL does:
-- - send VR.AddCommand request to HMI
-- - respond AddCommand(resultCode: SUCCESS, success: true) to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Defects/5_0/1006/common")

--[[ Local Variables ]]
local rpcAllParams = {
  requestParams = {
    cmdID = 11,
    menuParams = { position = 0, menuName = "menuName11" },
    vrCommands = { "vrCommands11" }
  },
  responseVrParams = {
    cmdID = 11,
    type = "Command",
    vrCommands = { "vrCommands11" }
  },
  responseParam = { success = true, resultCode = "UNSUPPORTED_RESOURCE", info = common.errorMessage }
}

local rpcVrOnlyParams = {
  requestParams = {
    cmdID = 12,
    vrCommands = { "vrCommands12" }
  },
  responseVrParams = {
    cmdID = 12,
    type = "Command",
    vrCommands = { "vrCommands12" }
  },
  responseParam = { success = true, resultCode = "SUCCESS" }
}

--[[ Local Functions ]]
local function sendAddCommand(pParams)
  local cid = common.getMobileSession():SendRPC("AddCommand", pParams.requestParams)
  common.getHMIConnection():ExpectRequest("UI.AddCommand")
  :Times(0)
  common.getHMIConnection():ExpectRequest("VR.AddCommand", pParams.responseVrParams)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  common.getMobileSession():ExpectResponse(cid, pParams.responseParam)
  common.getMobileSession():ExpectNotification("OnHashChange")
end

--[[ Test ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("App sends AddCommand with VR part", sendAddCommand, { rpcAllParams })
common.Step("App sends AddCommand with only VR part", sendAddCommand, { rpcVrOnlyParams })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
