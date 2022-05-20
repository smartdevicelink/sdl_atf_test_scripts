---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/3906
---------------------------------------------------------------------------------------------------
-- Description:
-- SDL does not apply PTU provided via PutFile with different <putFile_params> from mobile app during start PTU
--
-- Preconditions:
-- 1. SDL and HMI are started
-- 2. Mobile app is registered and activated
-- SDL does:
--  - start PTU and sends SDL.OnStatusUpdate(UPDATE_NEEDED, UPDATING) to HMI
-- Steps:
-- 1. App sends PutFile request with updated policy table includes "HapticGroup" functional group and <putFile_params>:
-- - only mandatory parameters
-- - persistentFile = true;
-- - systemFile = true;
-- - persistentFile = true, systemFile = true;
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

--[[ Local Variables ]]
local putFileParams = {
  [1] = { syncFileName = 'ptu.json', fileType = "JSON" },
  [2] = { syncFileName = 'ptu.json', fileType = "JSON", persistentFile = true },
  [3] = { syncFileName = 'ptu.json', fileType = "JSON", systemFile = true },
  [4] = { syncFileName = 'ptu.json', fileType = "JSON", persistentFile = true, systemFile = true }
}

--[[ Scenario ]]
for tc, params in ipairs(putFileParams) do
  common.Title("Test case [" .. string.format("%02d", tc) .. "]")
  common.Title("Preconditions")
  common.Step("Clean environment", common.preconditions)
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  common.Step("Register App", common.registerApp)
  common.Step("Activate App", common.activateApp)

  common.Title("Test")
  common.Step("App sends PutFile with updated policy table", common.putFile, { common.ptuFuncHapticGroup, params })
  common.Step("App sends SendHapticData DISALLOWED", common.sendHapticDataDisallowed)

  common.Title("Postconditions")
  common.Step("Clean sessions", common.cleanSessions)
  common.Step("Stop SDL", common.postconditions)
end
