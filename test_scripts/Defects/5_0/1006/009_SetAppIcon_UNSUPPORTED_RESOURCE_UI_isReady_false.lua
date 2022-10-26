---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/1006
---------------------------------------------------------------------------------------------------
-- Description: SDL sends SetAppIcon response with UNSUPPORTED_RESOURCE, success:false for single UI-related RPC
--  in case HMI responds UI.IsReady with "available" = false
--
-- Precondition:
-- 1. SDL and HMI are started.
-- 2. HMI responds with 'available' = false on UI.IsReady request from SDL
-- 3. App is registered and activated
-- Steps:
-- 1. App requests SetAppIcon only with UI part to SDL
-- SDL does:
-- - not send UI.SetAppIcon request to HMI
-- - respond SetAppIcon(resultCode: UNSUPPORTED_RESOURCE, success: false) to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Defects/5_0/1006/common")

--[[ Local Variables ]]
local putFileParams = {
  requestParams = {
    syncFileName = 'action.png',
    fileType = "GRAPHIC_PNG",
    persistentFile = false,
    systemFile = false
  },
  filePath = "files/icon.png"
}

local rpcParams = {
  rpc = "SetAppIcon",
  requestParam = { syncFileName = "action.png" }
}

--[[ Local Functions ]]
local function putFile(pParams)
  local cid = common.getMobileSession():SendRPC("PutFile", pParams.requestParams, pParams.filePath)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Test ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)
common.Step("Upload icon file", putFile, { putFileParams })

common.Title("Test")
common.Step("App sends SetAppIcon", common.sendRPC, { rpcParams })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
