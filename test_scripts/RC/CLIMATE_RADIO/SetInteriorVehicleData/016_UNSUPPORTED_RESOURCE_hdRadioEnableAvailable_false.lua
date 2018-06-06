---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0160-rc-radio-parameter-update.md
-- User story: TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- In case:
-- 1) RC.GetCapabilities received with hdRadioEnableAvailable = false from HMI
-- 2) Application is registered with REMOTE_CONTROL appHMIType
-- 3) and sends valid SetInteriorVehicleData RPC with hdRadioEnable
-- SDL must:
-- 1) Respond with UNSUPPORTED_RESOURCE result code, success = false to mobile application
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')
local hmi_values = require("user_modules/hmi_values")

--[[ Local Variables ]]
local Module = "RADIO"
local hmiValues = hmi_values.getDefaultHMITable()
hmiValues.RC.GetCapabilities.params.remoteControlCapability.radioControlCapabilities[1].hdRadioEnableAvailable = false

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start, { hmiValues })
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Step("Activate App", commonRC.activate_app)

runner.Title("Test")

runner.Step("SetInteriorVehicleData UNSUPPORTED_RESOURCE in case hdRadioEnableAvailable false", commonRC.rpcDenied,
	{Module, 1, "SetInteriorVehicleData", "UNSUPPORTED_RESOURCE"})

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
