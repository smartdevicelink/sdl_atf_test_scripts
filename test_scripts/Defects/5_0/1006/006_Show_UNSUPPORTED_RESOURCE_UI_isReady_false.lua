---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/1006
---------------------------------------------------------------------------------------------------
-- Description: SDL sends Show response with UNSUPPORTED_RESOURCE, success:false for single UI-related RPC
--  in case HMI responds UI.IsReady with "available" = false
--
-- Precondition:
-- 1. SDL and HMI are started.
-- 2. HMI responds with 'available' = false on UI.IsReady request from SDL
-- 3. App is registered and activated
-- Steps:
-- 1. App requests Show only with UI part to SDL
-- SDL does:
-- - not send UI.Show request to HMI
-- - respond Show(resultCode: UNSUPPORTED_RESOURCE, success: false) to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Defects/5_0/1006/common")

--[[ Local Variables ]]
local rpcParams = {
  rpc = "Show",
  requestParam = { mainField1 = "mainField1_text" }
}

--[[ Test ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("App sends Show", common.sendRPC, { rpcParams })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
