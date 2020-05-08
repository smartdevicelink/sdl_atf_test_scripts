---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  SDL received from HMI capabilities only for CLIMATE module where "location" data is inconsistent with
--  "serviceArea" data.
--  SDL should transfer these capabilities in response to the "GetSystemCapability" request from a mobile App.
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) HMI sent only CLIMATE module capabilities to SDL
-- 3) Mobile is connected to SDL
-- 4) App is registered and activated
--
-- Steps:
-- 1) App sends "GetSystemCapability"(systemCapabilityType = "REMOTE_CONTROL") request to the SDL
--   Check:
--    SDL sends "GetSystemCapability" response
--    (systemCapabilityType = "REMOTE_CONTROL", resultCode = "SUCCESS", remoteControlCapability = <custom_capabilities>)
--    with CLIMATE capabilities to the mobile App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local customClimateCapabilities = {
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
      location    = { col = 2, row = 0 },                                   -- "location" is inconsistent
      serviceArea = { col = 0, row = 1 }                                    -- with "serviceArea"
    }
  }
}

local capabilityParams = { CLIMATE = customClimateCapabilities }
local responseParams = { remoteControlCapability = { climateControlCapabilities = customClimateCapabilities }}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { capabilityParams })
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("GetSystemCapability with inconsistent location and serviceArea for CLIMATE module",
  common.sendGetSystemCapability, { 1, "REMOTE_CONTROL", responseParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
