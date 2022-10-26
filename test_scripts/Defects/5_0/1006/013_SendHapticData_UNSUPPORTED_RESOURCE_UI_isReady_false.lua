---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/1006
---------------------------------------------------------------------------------------------------
-- Description: SDL sends SendHapticData response with UNSUPPORTED_RESOURCE, success:false for single UI-related RPC
--  in case HMI responds UI.IsReady with "available" = false
--
-- Precondition:
-- 1. SDL and HMI are started.
-- 2. HMI responds with 'available' = false on UI.IsReady request from SDL
-- 3. App is registered and activated
-- 4. Policy Table Update is performed and "HapticGroup" functional group is assigned for the app
-- Steps:
-- 1. App requests SendHapticData only with UI part to SDL
-- SDL does:
-- - not send UI.SendHapticData request to HMI
-- - respond SendHapticData(resultCode: UNSUPPORTED_RESOURCE, success: false) to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Defects/5_0/1006/common")

--[[ Local Variables ]]
local rpcParams = {
  rpc = "SendHapticData",
  requestParam = { hapticRectData = {{ id = 1, rect = { x = 1, y = 1.5, width = 1, height = 1.5 }}}}
}

--[[ Local Functions ]]
local function ptuFunc(tbl)
  tbl.policy_table.app_policies[common.getParams().fullAppID].groups = { "Base-4", "HapticGroup" }
end

--[[ Test ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)
common.Step("Policy Table Update", common.policyTableUpdate, { ptuFunc })

common.Title("Test")
common.Step("App sends SendHapticData",  common.sendRPC, { rpcParams })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
