---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that SDL doesn't create "hmi_capabilities_cache.json" file in AppStorageFolder in case
-- HMICapabilitiesCacheFile parameter has incorrect value in smartDeviceLink.ini
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
-- - a) not created file for capability with incorrect name
-- - b) not stored capability to file in AppStorageFolder
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Local Variables ]]
local HMICacheFile_pathToFile = config.pathToSDL .. "storage/"
local cacheFileNames = {
  empty = "",
  empty_space = " ",
  null = "null",
  path_to_file = "/storage/hmi_capabilities_cache",
  wrong_file_extension = "hmi_capabilities_cache.js",
  integer = 5
}

--[[ Local Functions ]]
local function checkSDLNotStoredCapability(pFileName)
  common.isFileExist(HMICacheFile_pathToFile .. pFileName)
  common.run.fail("HMICapabilitiesCacheFile file does exist")
end

--[[ Scenario ]]
for d, k in pairs(cacheFileNames) do
  common.Title("Preconditions")
  common.Step("Clean environment check HMICapabilitiesCacheFile", common.precondition)
  common.Step("BackUp Ini File And Set file name-" .. d, common.backUpIniFileAndSetHBValue, { k })

  common.Title("Test")
  common.Step("Start SDL, HMI", common.start)
  common.Step("Check that SDL doesn't store capability with name-" .. k, checkSDLNotStoredCapability, { k })

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions)
  common.Step("RestoreIniFile", common.restoreIniFile)
end
