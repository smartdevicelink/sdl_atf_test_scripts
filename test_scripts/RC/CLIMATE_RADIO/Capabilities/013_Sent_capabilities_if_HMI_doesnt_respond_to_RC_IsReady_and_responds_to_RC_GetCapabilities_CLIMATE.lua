---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/1
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/detailed_info_GetSystemCapability.md
-- Item: Use Case 1: Alternative flow 2
--
-- Requirement summary:
-- [SDL_RC] Capabilities
--
-- Description:
-- In case:
-- HMI didn't respond on RC.IsReady request from SDL
-- and SDL send RC.GetCapabilities request to HMI
-- and HMI respond on this request with capabilities
--
-- SDL must:
-- Use these capabiltites during ignition cycle
-- Process RC-related RPCs accordingly
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local disabledModule = "RADIO"
local enabledModule = "CLIMATE"

--[[ Local Functions ]]
local function getHMIParams()
  local function getHMICapsParams()
    if enabledModule == "CLIMATE" then
      local capParams = {}
      capParams.CLIMATE = commonRC.DEFAULT
      capParams.RADIO = nil
      capParams.BUTTONS = commonRC.DEFAULT
      return capParams
    elseif enabledModule == "RADIO" then
      local capParams = {}
      capParams.CLIMATE = nil
      capParams.RADIO = commonRC.DEFAULT
      capParams.BUTTONS = commonRC.DEFAULT
      return capParams
    end
  end
  local hmiCaps = commonRC.buildHmiRcCapabilities(getHMICapsParams())
  hmiCaps.RC.IsReady = nil
  local buttonCaps = hmiCaps.RC.GetCapabilities.params.remoteControlCapability.buttonCapabilities
  local buttonId = commonRC.getButtonIdByName(buttonCaps, commonRC.getButtonNameByModule(disabledModule))
  table.remove(buttonCaps, buttonId)
  return hmiCaps
end

local function start()
  commonRC.start(getHMIParams())
  :Timeout(20000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Backup HMI capabilities file", commonRC.backupHMICapabilities)
runner.Step("Update HMI capabilities file", commonRC.updateDefaultCapabilities, { { enabledModule }, true })
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", start)
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate App", commonRC.activateApp)

runner.Title("Test - Module enabled: " .. enabledModule .. ", disabled: " .. disabledModule)

runner.Step("GetInteriorVehicleData_UNSUPPORTED_RESOURCE", commonRC.rpcDenied,
  { disabledModule, 1, "GetInteriorVehicleData", "UNSUPPORTED_RESOURCE" })
runner.Step("SetInteriorVehicleData_UNSUPPORTED_RESOURCE", commonRC.rpcDenied,
  { disabledModule, 1, "SetInteriorVehicleData", "UNSUPPORTED_RESOURCE" })
runner.Step("ButtonPress_UNSUPPORTED_RESOURCE", commonRC.rpcDenied,
  { disabledModule, 1, "ButtonPress", "UNSUPPORTED_RESOURCE" })

runner.Step("GetInteriorVehicleData_SUCCESS", commonRC.rpcAllowed, { enabledModule, 1, "GetInteriorVehicleData" })
runner.Step("SetInteriorVehicleData_SUCCESS", commonRC.rpcAllowed, { enabledModule, 1, "SetInteriorVehicleData" })
runner.Step("ButtonPress_SUCCESS", commonRC.rpcAllowed, { enabledModule, 1, "ButtonPress" })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
runner.Step("Restore HMI capabilities file", commonRC.restoreHMICapabilities)
