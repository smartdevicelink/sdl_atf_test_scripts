---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/1
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/detailed_info_GetSystemCapability.md
-- Item: Use Case 1: Main Flow
--
-- Requirement summary:
-- [SDL_RC] Capabilities
--
-- Description:
-- In case:
-- 1) SDL gets all RC capabilities for RADIO and CLIMATE modules through RC.GetCapabilities
-- SDL must:
-- 1) Send RPC request to HMI and resend HMI answer to Mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Local Variables ]]
local modules = { "CLIMATE", "RADIO" }

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Backup HMI capabilities file", commonRC.backupHMICapabilities)
runner.Step("Update HMI capabilities file", commonRC.updateDefaultCapabilities, { { "CLIMATE", "RADIO" } })
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI (HMI has all posible RC capabilities), connect Mobile, start Session", commonRC.start,
	{commonRC.buildHmiRcCapabilities(commonRC.DEFAULT, commonRC.DEFAULT, commonRC.DEFAULT)})
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Step("Activate App1", commonRC.activate_app)

runner.Title("Test")

for _, mod in pairs(modules) do
  runner.Step("GetInteriorVehicleData " .. mod, commonRC.subscribeToModule, { mod, 1 })
  runner.Step("SetInteriorVehicleData " .. mod, commonRC.rpcAllowed, { mod, 1, "SetInteriorVehicleData" })
  runner.Step("ButtonPress " .. mod, commonRC.rpcAllowed, { mod, 1, "ButtonPress" })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
runner.Step("Restore HMI capabilities file", commonRC.restoreHMICapabilities)
