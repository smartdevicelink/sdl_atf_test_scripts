---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  SDL received capabilities where "moduleId" of one of CLIMATE modules has the same value as one of AUDIO modules.
--  SDL should transfer these capabilities in response to the "GetSystemCapability" request from a mobile App.
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) HMI sent only CLIMATE and AUDIO modules capabilities to SDL
-- 3) Mobile is connected to SDL
-- 4) App is registered and activated
--
-- Steps:
-- 1) App sends "GetSystemCapability"(systemCapabilityType = "REMOTE_CONTROL") request to the SDL
--   Check:
--    SDL sends "GetSystemCapability" response
--    (systemCapabilityType = "REMOTE_CONTROL", resultCode = "SUCCESS", remoteControlCapability = <custom_capabilities>)
--    with CLIMATE and AUDIO capabilities to the mobile App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local capabilityParams = {
  CLIMATE = {
    {
      moduleName = "Climate Driver Seat",
      moduleInfo = {
        moduleId = "2df6518c-ca8a-4e7c-840a-0eba5c028351",
        location    = { col = 0, row = 0 },
        serviceArea = { col = 0, row = 0 }
      }
    },
    {
      moduleName = "Climate Front Passenger Seat",
      moduleInfo = {
        moduleId = "4c133291-3cc2-4174-b722-6284953af345",
        location    = { col = 2, row = 0 },
      }
    }
  },
  AUDIO = {
    {
      moduleName = "Audio Driver Seat",
      moduleInfo = {
        moduleId = "0876b4be-f1ce-4f5c-86e9-5ca821683a1b",
        location    = { col = 0, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1 },
        serviceArea = { col = 0, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1 },
        allowMultipleAccess = true
      }
    },
    {
      moduleName = "Audio Front Passenger Seat",
      moduleInfo = {
        moduleId = "4c133291-3cc2-4174-b722-6284953af345",                                                        -- same "moduleId" as in CLIMATE module
        location    = { col = 2, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1 },
        serviceArea = { col = 2, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1 },
        allowMultipleAccess = true
      }
    }
  }
}

local responseParams = {
  remoteControlCapability = {
    climateControlCapabilities = capabilityParams.CLIMATE,
    audioControlCapabilities = capabilityParams.AUDIO
  }
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { capabilityParams })
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("GetSystemCapability same moduleId in some AUDIO and SEAT modules",
  common.sendGetSystemCapability, { 1, "REMOTE_CONTROL", responseParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
