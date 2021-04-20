---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  SDL received from HMI capabilities containing only mandatory parameters in "moduleInfo"
--  Check that after receiving "GetSystemCapability" request from mobile App, SDL will add omitted non-mandatory
--  "allowMultipleAccess" parameter to these capabilities and send them in the "GetSystemCapability" response
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) HMI sent all modules capabilities including only mandatory parameters to SDL
-- 3) Mobile is connected to SDL
-- 4) App is registered and activated
--
-- Steps:
-- 1) App sends "GetSystemCapability" request ("REMOTE_CONTROL")
--   Check:
--    SDL sends "GetSystemCapability" response with all modules RC capabilities to mobile
--    adding ("allowMultipleAccess" = true) to the capabilities
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function initHmiRcCapabilities(pModuleIdModification)
  local notMandatoryParameters = { "location", "serviceArea", "allowMultipleAccess" }
  local capabilities = common.getRcCapabilities()
  for moduleType, modules in pairs(capabilities) do
    local moduleInfo
    if moduleType == "LIGHT" or moduleType == "HMI_SETTINGS" then
      moduleInfo = modules.moduleInfo
      moduleInfo.moduleId = moduleInfo.moduleId .. pModuleIdModification
      for _, parameter in ipairs(notMandatoryParameters) do
        moduleInfo[parameter] = nil
      end
    else
      for _, moduleValue in ipairs(modules) do
        moduleInfo = moduleValue.moduleInfo
        moduleValue.moduleInfo.moduleId = moduleValue.moduleInfo.moduleId .. pModuleIdModification
        for _, parameter in ipairs(notMandatoryParameters) do
          moduleInfo[parameter] = nil
        end
      end
    end
  end
  return capabilities
end

local mandatoryOnlyParams = initHmiRcCapabilities("_MandatoryOnly")

local expectedParameters = (function()
  local checkCapabilityParams = common.cloneTable(mandatoryOnlyParams)
  for moduleType, params in pairs(checkCapabilityParams) do
    if moduleType ~= "LIGHT" and moduleType ~= "HMI_SETTINGS" then      -- these modules' capabilities are not an array
      for _, module in pairs(params) do
        module.moduleInfo.allowMultipleAccess = true
      end
    else params.moduleInfo.allowMultipleAccess = true end
  end
  local out = {
    remoteControlCapability = {
      climateControlCapabilities = checkCapabilityParams.CLIMATE,
      radioControlCapabilities = checkCapabilityParams.RADIO,
      audioControlCapabilities = checkCapabilityParams.AUDIO,
      seatControlCapabilities = checkCapabilityParams.SEAT,
      hmiSettingsControlCapabilities = checkCapabilityParams.HMI_SETTINGS,
      lightControlCapabilities = checkCapabilityParams.LIGHT
    }
  }
  return out
end)()

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { mandatoryOnlyParams })
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("GetSystemCapability with moduleInfo mandatory only parameters", common.sendGetSystemCapability,
  { 1, "REMOTE_CONTROL", expectedParameters })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
