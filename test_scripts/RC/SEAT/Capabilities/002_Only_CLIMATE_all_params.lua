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
-- 1) SDL does not get RC capabilities for SEAT module through RC.GetCapabilities
-- SDL must:
-- 1) Response with success = false and resultCode = UNSUPPORTED_RESOURCE on all valid RPC with module SEAT
-- 2) Does not send RPC request to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/SEAT/commonRC')

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Backup HMI capabilities file", commonRC.backupHMICapabilities)
runner.Step("Update HMI capabilities file", commonRC.updateDefaultCapabilities, { { "SEAT" } }) --Changed
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI (HMI has all SEAT RC capabilities), connect Mobile, start Session", commonRC.start,
	{commonRC.buildHmiRcCapabilities(commonRC.DEFAULT, commonRC.DEFAULT, nil, commonRC.DEFAULT)})
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Step("Activate App1", commonRC.activate_app)

runner.Title("Test")

-- SEAT PRC is unsupported
runner.Step("GetInteriorVehicleData SEAT", commonRC.rpcDenied, { "SEAT", 1, "GetInteriorVehicleData", "UNSUPPORTED_RESOURCE" })
runner.Step("SetInteriorVehicleData SEAT", commonRC.rpcDenied, { "SEAT", 1, "SetInteriorVehicleData", "UNSUPPORTED_RESOURCE" })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
runner.Step("Restore HMI capabilities file", commonRC.restoreHMICapabilities)
