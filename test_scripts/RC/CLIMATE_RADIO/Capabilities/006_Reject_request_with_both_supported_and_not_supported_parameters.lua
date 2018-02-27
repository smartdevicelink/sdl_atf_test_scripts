---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/1
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/detailed_info_GetSystemCapability.md
-- Item: Use Case 1:Exception 3.3
--
-- Requirement summary:
-- [SDL_RC] Set available control module settings SetInteriorVehicleData
--
-- Description:
-- In case:
-- 1) SDL receive several supported Radio parameters in GetCapabilites response and
-- 2) App sends RC RPC request with several supported by HMI parameters and some unssuported
-- SDL must:
-- 1) Reject such request with UNSUPPORTED_RESOURCE result code, success: false
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Local Variables ]]
local climate_capabilities = {{
  moduleName = "Climate",
  fanSpeedAvailable = true,
  acEnableAvailable = true,
  acMaxEnableAvailable = true
}}
local rc_capabilities = commonRC.buildHmiRcCapabilities(climate_capabilities, commonRC.DEFAULT, commonRC.DEFAULT)
local climate_params =
{
	moduleType = "CLIMATE",
	climateControlData =
  {
    fanSpeed = 30,
    acEnable = true,
    acMaxEnable = true,
    circulateAirEnable = true -- unsupported parameter
  }
}

--[[ Local Functions ]]
local function setVehicleData(params, self)
	local cid = self.mobileSession1:SendRPC("SetInteriorVehicleData", {moduleData = params})

		EXPECT_HMICALL("RC.SetInteriorVehicleData"):Times(0)
		self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "UNSUPPORTED_RESOURCE" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start, {rc_capabilities})
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Step("Activate_App", commonRC.activate_app)

runner.Title("Test")
for _, module_name in pairs({"CLIMATE", "RADIO"}) do
    runner.Step("GetInteriorVehicleData for " .. module_name, commonRC.subscribeToModule, {module_name, 1})
    runner.Step("ButtonPress for " .. module_name, commonRC.rpcAllowed, {module_name, 1, "ButtonPress"})
end
runner.Step("SetInteriorVehicleData rejected if at least one prameter unsuported", setVehicleData, { climate_params })
