---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that SDL is created file, save capability to file and loading capability form file after ignition
-- OFF/ON cycle
--
-- Preconditions:
-- 1. hmi_capabilities_cache.json file doesn't exist on file system
-- 2. SDL and HMI are started
-- Sequence:
-- 1. HMI sends "BasicCommunication.OnReady" notification
--   a. request all capability from HMI
-- 2. HMI sends all capability to SDL
--   a. stored all capability to "hmi_capabilities_cache.json" file in AppStorageFolder
-- 3. Ignition OFF/ON cycle performed
--   a. check if hmi_capabilities_cache.json file present in AppStorageFolder
--   b. check that all mandatory capability preset
--   c. load capability from "hmi_capabilities_cache.json" file
--   d. not send requests for all capability to SDL
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)

common.Title("Test")
common.Step("Start SDL and HMI", common.start)
common.Step("Validate stored capability file", common.checkContentCapabilityCacheFile)
common.Step("Ignition off", common.ignitionOff)
common.Step("Ignition on, SDL doesn't send HMI capabilities requests",
  common.start, { common.noRequestsGetHMIParams() })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
