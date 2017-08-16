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
-- 1) SDL receive only one parameter in GetCapabilites response for CLIMATE module
-- SDL must:
-- 1) Transfer to HMI remote control RPCs only with supported parameter and
-- 2) Reject any request for CLIMATE with unsupported parameters with UNSUPPORTED_RESOURCE result code, success: false
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')
local common_functions = require('user_modules/shared_testcases/commonTestCases')

--[[ Local Variables ]]
local climate_capabilities = {{moduleName = "Climate", fanSpeedAvailable = true}}
local rc_capabilities = commonRC.buildHmiRcCapabilities(climate_capabilities, commonRC.DEFAULT, commonRC.DEFAULT)
local available_params = {moduleType = "CLIMATE", climateControlData = {fanSpeed = 30}}
local absent_params = {moduleType = "CLIMATE", climateControlData = {acMaxEnable = true}}

--[[ Local Functions ]]
local function setVehicleData(params, self)
	local cid = self.mobileSession:SendRPC("SetInteriorVehicleData", {moduleData = params})

	if params.climateControlData.fanSpeed then
		EXPECT_HMICALL("RC.SetInteriorVehicleData",	{
			appID = commonRC.getHMIAppId(1),
			moduleData = params})
		:Do(function(_, data)
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
					moduleData = params})
			end)
		self.mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
	else
		EXPECT_HMICALL("RC.SetInteriorVehicleData"):Times(0)
		self.mobileSession:ExpectResponse(cid, { success = false, resultCode = "UNSUPPORTED_RESOURCE" })
		common_functions:DelayedExp(commonRC.timeout)
	end
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
--SDL process only supported by HMI parameter
runner.Step("SetInteriorVehicleData processed with supported fanSpeed", setVehicleData, { available_params })
runner.Step("SetInteriorVehicleData rejected with unsupported acMaxEnable", setVehicleData, { absent_params })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
