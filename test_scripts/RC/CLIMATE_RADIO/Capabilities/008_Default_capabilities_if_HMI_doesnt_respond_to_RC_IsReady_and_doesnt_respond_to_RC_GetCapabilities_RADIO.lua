---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/1
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/detailed_info_GetSystemCapability.md
-- Item: Use Case 1: Exception 2.1
--
-- Requirement summary:
-- [SDL_RC] Capabilities
--
-- Description:
-- In case:
-- HMI didn't respond on RC.IsReady request from SDL
-- and HMI didn't respond on capabilities request from SDL
--
-- SDL must:
-- Use default capabiltites during ignition cycle stored in HMI_capabilities.json file
-- Process RC-related RPCs
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local disabledModule = "CLIMATE"
local enabledModule = "RADIO"

--[[ Local Functions ]]
local function getHMIParams()
  local params = commonRC.getDefaultHMITable()
  params.RC.IsReady = nil
  params.RC.GetCapabilities = nil
  return params
end

local function start(pHMIParams)
  commonRC.start(pHMIParams)
  commonRC.wait(12000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Backup HMI capabilities file", commonRC.backupHMICapabilities)
runner.Step("Update HMI capabilities file", commonRC.updateDefaultCapabilities, { { disabledModule } })
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", start, { getHMIParams() })
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
