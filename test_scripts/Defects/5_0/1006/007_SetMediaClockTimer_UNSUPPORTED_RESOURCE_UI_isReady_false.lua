---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/1006
---------------------------------------------------------------------------------------------------
-- Description: SDL sends SetMediaClockTimer response with UNSUPPORTED_RESOURCE, success:false for single UI-related RPC
--  in case HMI responds UI.IsReady with "available" = false
--
-- Precondition:
-- 1. SDL and HMI are started.
-- 2. HMI responds with 'available' = false on UI.IsReady request from SDL
-- 3. App is registered and activated
-- Steps:
-- 1. App requests SetMediaClockTimer only with UI part to SDL
-- SDL does:
-- - not send UI.Show request to HMI
-- - respond SetMediaClockTimer(resultCode: UNSUPPORTED_RESOURCE, success: false) to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Defects/5_0/1006/common")

--[[ Local Variables ]]
local rpcParams = {
  rpc = "SetMediaClockTimer",
  requestParam = {
    startTime = { hours = 0, minutes = 1, seconds = 33 },
    endTime = { hours = 0, minutes = 1, seconds = 35 },
    updateMode = "COUNTUP"
  }
}

--[[ Test ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("App sends SetMediaClockTimer", common.sendRPC, { rpcParams })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
