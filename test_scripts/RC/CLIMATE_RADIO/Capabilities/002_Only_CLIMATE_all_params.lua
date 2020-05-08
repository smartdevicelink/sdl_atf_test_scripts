---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/1
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/detailed_info_GetSystemCapability.md
-- Item: Use Case 1:Exception 3.1
--
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/3
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/SetInteriorVehicleData.md
-- Item: Use Case 1: Exceptions: 5.1
--
-- Requirement summary:
-- [SDL_RC] Capabilities
--
-- Description:
-- In case:
-- 1) SDL does not get RC capabilities for RADIO module through RC.GetCapabilities
-- SDL must:
-- 1) Response with success = false and resultCode = UNSUPPORTED_RESOURCE on all valid RPC with module RADIO
-- 2) Does not send RPC request to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local Variables ]]
local capParams = {}
capParams.CLIMATE = commonRC.DEFAULT
capParams.RADIO = nil
capParams.BUTTONS = commonRC.DEFAULT
local hmiRcCapabilities = commonRC.buildHmiRcCapabilities(capParams)

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Backup HMI capabilities file", commonRC.backupHMICapabilities)
runner.Step("Update HMI capabilities file", commonRC.updateDefaultCapabilities, { { "CLIMATE", "RADIO" }, true })
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI (HMI has all CLIMATE RC capabilities), connect Mobile, start Session", commonRC.start,
  {hmiRcCapabilities})
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate App1", commonRC.activateApp)

runner.Title("Test")

-- CLIMATE RPC is allowed
runner.Step("GetInteriorVehicleData CLIMATE", commonRC.subscribeToModule, { "CLIMATE", 1 })
runner.Step("SetInteriorVehicleData CLIMATE", commonRC.rpcAllowed, { "CLIMATE", 1, "SetInteriorVehicleData" })
-- RADIO PRC is unsupported
runner.Step("GetInteriorVehicleData RADIO", commonRC.rpcDenied, { "RADIO", 1, "GetInteriorVehicleData", "UNSUPPORTED_RESOURCE" })
runner.Step("SetInteriorVehicleData RADIO", commonRC.rpcDenied, { "RADIO", 1, "SetInteriorVehicleData", "UNSUPPORTED_RESOURCE" })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
runner.Step("Restore HMI capabilities file", commonRC.restoreHMICapabilities)
