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
-- 1) SDL receive several supported Radio parameters in GetCapabilites response
-- SDL must:
-- 1) Transfer to HMI remote control RPCs only with supported parameters and
-- 2) Reject any request for RADIO with unsupported parameters with UNSUPPORTED_RESOURCE result code, success: false
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local moduleId = commonRC.getModuleId("RADIO")
local radio_capabilities = {
  {
    moduleName = "Radio",
    moduleInfo = {moduleId = moduleId},
    radioFrequencyAvailable = true,
    radioBandAvailable = true
  }
}
local capParams = {}
capParams.CLIMATE = commonRC.DEFAULT
capParams.RADIO = radio_capabilities
capParams.BUTTONS = commonRC.DEFAULT
local rc_capabilities = commonRC.buildHmiRcCapabilities(capParams)
local available_params =
{
    moduleType = "RADIO",
    moduleId = moduleId,
    radioControlData = {frequencyInteger = 1, frequencyFraction = 2, band = "AM"}
}
local absent_params = {
  moduleType = "RADIO",
  moduleId = moduleId,
  radioControlData = {frequencyInteger = 1, frequencyFraction = 2}
}

--[[ Local Functions ]]
local function setVehicleData(params)
  local cid = commonRC.getMobileSession():SendRPC("SetInteriorVehicleData", {moduleData = params})

  if params.radioControlData.frequencyInteger then
    EXPECT_HMICALL("RC.SetInteriorVehicleData", {
      appID = commonRC.getHMIAppId(1),
      moduleData = params})
    :Do(function(_, data)
        commonRC.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {
          moduleData = params})
      end)
    commonRC.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  else
    EXPECT_HMICALL("RC.SetInteriorVehicleData"):Times(0)
    commonRC.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "UNSUPPORTED_RESOURCE" })
    commonRC.wait(commonRC.timeout)
  end
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start, {rc_capabilities})
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate_App", commonRC.activateApp)

runner.Title("Test")
for _, module_name in pairs({"CLIMATE", "RADIO"}) do
    runner.Step("GetInteriorVehicleData for " .. module_name, commonRC.subscribeToModule, {module_name, 1})
    runner.Step("ButtonPress for " .. module_name, commonRC.rpcAllowed, {module_name, 1, "ButtonPress"})
end
runner.Step("SetInteriorVehicleData processed for several supported params", setVehicleData, { available_params })
runner.Step("SetInteriorVehicleData rejected with unsupported parameter", setVehicleData, { absent_params })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
