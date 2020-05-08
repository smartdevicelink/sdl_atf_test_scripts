---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  SDL received capabilities, where one of SEAT modules contains in its "moduleInfo" the same "location" and
--  "serviceArea" data as one of AUDIO modules.
--  SDL should transfer these capabilities in response to the "GetSystemCapability" request from a mobile App.
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) HMI sent only AUDIO and SEAT modules capabilities to SDL
-- 3) Mobile is connected to SDL
-- 4) App is registered and activated
--
-- Steps:
-- 1) App sends "GetSystemCapability"(systemCapabilityType = "REMOTE_CONTROL") request to the SDL
--   Check:
--    SDL sends "GetSystemCapability" response
--    (systemCapabilityType = "REMOTE_CONTROL", resultCode = "SUCCESS", remoteControlCapability = <custom_capabilities>)
--    with AUDIO and SEAT capabilities to the mobile App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local capabilityParams = {
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
        moduleId = "d77a4bd2-5bd2-4c5a-991a-7ec5f14911ca",
        location    = { col = 2, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1 },
        serviceArea = { col = 2, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1 },
        allowMultipleAccess = true
      }
    }
  },
  SEAT = {
    {
      moduleName = "Seat of Driver",
      moduleInfo = {
        moduleId = "a42bf1e0-e02e-4462-912a-7d4230815f73",
        location    = { col = 0, row = 0, level = 0 },
        serviceArea = { col = 0, row = 0, level = 0 },
      }
    },
    {
      moduleName = "Seat Front Passenger Seat",
      moduleInfo = {
        moduleId = "650765bb-2f89-4d68-a665-6267c80e6c62",
        location    = { col = 2, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1 },
        serviceArea = { col = 2, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1 },
        allowMultipleAccess = true
      }
    }
  }
}

local responseParams = {
  remoteControlCapability = {
    audioControlCapabilities = capabilityParams.AUDIO,
    seatControlCapabilities  = capabilityParams.SEAT
  }
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { capabilityParams })
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("GetSystemCapability same data in location and serviceArea in AUDIO and SEAT modules",
  common.sendGetSystemCapability, { 1, "REMOTE_CONTROL", responseParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
