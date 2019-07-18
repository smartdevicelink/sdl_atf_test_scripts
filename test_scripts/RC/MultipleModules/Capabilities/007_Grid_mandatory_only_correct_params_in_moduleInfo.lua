---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  SDL received AUDIO module capabilities where "moduleInfo" includes "location" and "serviceArea" parameters with
--  only mandatory parameters. SDL should resend these capabilities in "GetSystemCapability" response to mobile adding
--  non-mandatory parameter.
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) HMI sent AUDIO module capabilities to SDL
-- 3) Mobile is connected to SDL
-- 4) App is registered and activated
--
-- Steps:
-- 1) App sends "GetSystemCapability" request ("REMOTE_CONTROL")
--   Check:
--    SDL sends "GetSystemCapability" response with AUDIO module capabilities containing "moduleInfo" with "location"
--    and "serviceArea" having mandatory parameters and all optional parameters added to mobile
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local customAudioCapabilities = {
  {
    moduleName = "Audio Driver Seat",
    moduleInfo = {
      moduleId = "0876b4be-f1ce-4f5c-86e9-5ca821683a1b",
      location = { col = 0, row = 0 },
      serviceArea = { col = 0, row = 0 }
    }
  },
  {
    moduleName = "Audio Front Passenger Seat",
    moduleInfo = {
      moduleId = "d77a4bd2-5bd2-4c5a-991a-7ec5f14911ca",
      location = { col = 2, row = 0 },
      serviceArea = { col = 2, row = 0 }
    }
  },
  {
    moduleName = "Audio 2nd Raw Left Seat",
    moduleInfo = {
      moduleId = "c64f6c90-6fcb-4543-ae65-c401b3ca08b2",
      location = { col = 0, row = 1 },
      serviceArea = { col = 0, row = 1 }
    }
  },
  {
    moduleName = "Audio 2nd Raw Middle Seat",
    moduleInfo = {
      moduleId = "bd0452a1-34a2-4432-af60-6e0e9c3902e2",
      location = { col = 1, row = 1 },
      serviceArea = { col = 1, row = 1 }
    }
  }
}
local nonMandatoryParams = { level = 0, colspan = 1, rowspan = 1, levelspan = 1 }

local expectedParameters = (function()
  local checkCapabilityParams = common.cloneTable(customAudioCapabilities)
  for _, moduleCap in pairs(checkCapabilityParams) do
    moduleCap.moduleInfo.allowMultipleAccess = true
    local location = moduleCap.moduleInfo.location
    local serviceArea = moduleCap.moduleInfo.serviceArea
    for param, value in pairs(nonMandatoryParams) do
        location[param] = value
        serviceArea[param] = value
    end
  end
  local out = { remoteControlCapability = { audioControlCapabilities = checkCapabilityParams } }
  return out
end)()

local capabilityParams = { AUDIO = customAudioCapabilities }

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { capabilityParams })
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("GetSystemCapability Mandatory only Grid parameters",
  common.sendGetSystemCapability, { 1, "REMOTE_CONTROL", expectedParameters })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
