---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  Mobile App receives all capabilities in response to "GetSystemCapability", {systemCapabilityType = "REMOTE_CONTROL"}
--  request
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) HMI sent all modules capabilities to SDL
-- 3) Mobile is connected to SDL
-- 4) App is registered and activated
--
-- Steps:
-- 1) App sends "GetSystemCapability" request ("REMOTE_CONTROL")
--   Check:
--    SDL sends "GetSystemCapability" response with all modules RC capabilities to mobile
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function initHmiRcCapabilities(pModuleIdModification)
  local capabilities = common.getRcCapabilities()
  for moduleType, modules in pairs(capabilities) do
    if moduleType == "LIGHT" or moduleType == "HMI_SETTINGS" then
      modules.moduleInfo.moduleId = modules.moduleInfo.moduleId .. pModuleIdModification
    else
      for _, moduleValue in ipairs(modules) do
        moduleValue.moduleInfo.moduleId = moduleValue.moduleInfo.moduleId .. pModuleIdModification
      end
    end
  end
  return capabilities
end

local rcCapabilities = initHmiRcCapabilities("_Test")
local expectedParameters = {
  remoteControlCapability = {
    climateControlCapabilities = rcCapabilities.CLIMATE,
    radioControlCapabilities = rcCapabilities.RADIO,
    audioControlCapabilities = rcCapabilities.AUDIO,
    seatControlCapabilities = rcCapabilities.SEAT,
    hmiSettingsControlCapabilities = rcCapabilities.HMI_SETTINGS,
    lightControlCapabilities = rcCapabilities.LIGHT,
    buttonCapabilities =  rcCapabilities.BUTTONS
  }
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { rcCapabilities })
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("GetSystemCapability Positive Case with all capabilities",
  common.sendGetSystemCapability, { 1, "REMOTE_CONTROL", expectedParameters })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
