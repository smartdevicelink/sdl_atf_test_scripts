---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0160-rc-radio-parameter-update.md
-- User story: TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- In case:
-- 1) RC.GetCapabilities received without siriusxmRadioAvailable from HMI
-- 2) Application is registered with REMOTE_CONTROL appHMIType
-- 3) and sends valid SetInteriorVehicleData RPC with band = XM
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
hmiValues.RC.GetCapabilities.params.remoteControlCapability.radioControlCapabilities[1].siriusxmRadioAvailable = nil

--[[ Local Functions ]]
local function rpcDenied(self)
  local requestParams = commonRC.getSettableModuleControlData(Module)
  requestParams.radioControlData.band = "XM"

  local cid = self.mobileSession1:SendRPC("SetInteriorVehicleData", {
	moduleData = requestParams
  })

  EXPECT_HMICALL("RC.SetInteriorVehicleData")
  :Times(0)

  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "UNSUPPORTED_RESOURCE" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start, { hmiValues })
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Step("Activate App", commonRC.activate_app)

runner.Title("Test")

runner.Step("SetInteriorVehicleData UNSUPPORTED_RESOURCE in case siriusxmRadioAvailable omitted", rpcDenied)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
