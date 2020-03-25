---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that SDL does create capability cache file in AppStorageFolder in case
-- HMICapabilitiesCacheFile parameter has different value in smartDeviceLink.ini
--
-- Preconditions:
-- 1) Check that file with capability file doesn't exist on file system
-- 2) Update HMICapabilitiesCacheFile parameter value in smartDeviceLink.ini file
-- 3) SDL and HMI are started
-- Steps:
-- 1) HMI sends "BasicCommunication.OnReady" notification
-- SDL does:
-- - a) request all capability from HMI
-- Steps:
-- 2) HMI sends all capability to SDL
-- SDL does:
-- - a) created file for capability with different names
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Local Variables ]]
local cacheFileNames = { "12345.json", "a.json", "a_1.json" }

--[[ Scenario ]]
for _, k in pairs(cacheFileNames) do
  common.Title("Preconditions")
  common.Step("Clean environment check HMICapabilitiesCacheFile", common.precondition)
  common.Step("BackUp Ini File And Set file name-" .. k, common.backUpIniFileAndSetHBValue, { k })

  common.Title("Test")
  common.Step("Start SDL, HMI", common.start)
  common.Step("Check that SDL does create capability file with name-" .. k, common.checkIfExistCapabilityFile, { k })

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions)
  common.Step("RestoreIniFile", common.restoreIniFile)
end
