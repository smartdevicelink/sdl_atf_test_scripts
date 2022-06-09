---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/3906
---------------------------------------------------------------------------------------------------
-- Description: SDL does not apply PTU provided via PutFile from mobile app during start PTU
--
-- Preconditions:
-- 1. SDL and HMI are started
-- 2. Mobile app is registered and activated
-- SDL does:
--  - start PTU and sends SDL.OnStatusUpdate(UPDATE_NEEDED, UPDATING) to HMI
-- Steps:
-- 1. App sends PutFile request with updated policy table includes "HapticGroup" functional group
-- SDL does:
-- - not send SDL.OnStatusUpdate notification to HMI
-- - not send SDL.OnPermissionsChange notification to HMI
-- - not send SDL.OnAppPermissionChanged notification to HMI
-- - send BasicCommunication.OnPutFile notification to HMI
-- - respond PutFile(success = true, resultCode = "SUCCESS") to app
-- 2. App sends SendHapticData request
-- SDL does:
-- - respond SendHapticData(success = false, resultCode = "DISALLOWED") to app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Defects/8_2/3906/common_3906")

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("App sends PutFile with updated policy table", common.putFile, { common.ptuFuncHapticGroup })
common.Step("App sends SendHapticData DISALLOWED", common.sendHapticDataDisallowed)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
