---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0160-rc-radio-parameter-update.md
-- User story: TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- In case:
-- 1) RC.GetCapabilities received without hdRadioEnableAvailable from HMI
-- 2) Application is registered with REMOTE_CONTROL appHMIType
-- 3) and sends valid SetInteriorVehicleData RPC with hdRadioEnable
-- SDL must:
-- 1) Respond with UNSUPPORTED_RESOURCE result code, success = false to mobile application
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local Module = "RADIO"
local hmiValues = commonRC.getDefaultHMITable()
hmiValues.RC.GetCapabilities.params.remoteControlCapability.radioControlCapabilities[1].hdRadioEnableAvailable = nil

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start, { hmiValues })
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate App", commonRC.activateApp)

runner.Title("Test")

runner.Step("SetInteriorVehicleData UNSUPPORTED_RESOURCE in case hdRadioEnableAvailable omitted", commonRC.rpcDenied,
	{Module, 1, "SetInteriorVehicleData", "UNSUPPORTED_RESOURCE"})

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
