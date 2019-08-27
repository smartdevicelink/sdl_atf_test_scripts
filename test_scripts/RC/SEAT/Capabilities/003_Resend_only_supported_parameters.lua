---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0105-remote-control-seat.md
-- User story:
-- Use case:
-- Item
--
-- Description:
-- In case:
-- 1) SDL receive several supported SEAT parameters in GetCapabilites response
-- SDL must:
-- 1) Transfer to HMI remote control RPCs only with supported parameters and
-- 2) Reject any request for SEAT with unsupported parameters with UNSUPPORTED_RESOURCE result code, success: false
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local moduleId = commonRC.getModuleId("SEAT")
local seat_capabilities = {
  {
    moduleName = "Seat",
    moduleInfo = {
      moduleId = moduleId
    },
    horizontalPositionAvailable = true,
    verticalPositionAvailable = false
  }
}
local capParams = {}
capParams.CLIMATE = commonRC.DEFAULT
capParams.RADIO = commonRC.DEFAULT
capParams.BUTTONS = commonRC.DEFAULT
capParams.SEAT = seat_capabilities
local rc_capabilities = commonRC.buildHmiRcCapabilities(capParams)
local available_params = {
  moduleType = "SEAT",
  moduleId= moduleId,
  seatControlData = {
    id = "DRIVER",
    horizontalPosition = 75
  }
}
local absent_params = {
  moduleType = "SEAT",
  moduleId = moduleId,
  seatControlData = {
    id = "DRIVER",
    frontVerticalPosition = 55
  }
}
local unavailable_params = {
  moduleType = "SEAT",
  moduleId = moduleId,
  seatControlData = {
    id = "DRIVER",
    verticalPosition = 65
  }
}

--[[ Local Functions ]]
local function setVehicleData(params)
  local mobSession = commonRC.getMobileSession()
  local cid = mobSession:SendRPC("SetInteriorVehicleData", {moduleData = params})

  if params.seatControlData.horizontalPosition then
    EXPECT_HMICALL("RC.SetInteriorVehicleData",	{
      appID = commonRC.getHMIAppId(1),
      moduleData = params})
    :Do(function(_, data)
        commonRC.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {
          moduleData = params})
      end)
    mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  else
    EXPECT_HMICALL("RC.SetInteriorVehicleData"):Times(0)
    mobSession:ExpectResponse(cid, { success = false, resultCode = "UNSUPPORTED_RESOURCE" })
  end
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start, {rc_capabilities})
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate_App", commonRC.activateApp)

runner.Title("Test")
runner.Step("SetInteriorVehicleData rejected with unavailable parameter", setVehicleData, { unavailable_params })
runner.Step("SetInteriorVehicleData processed with available parameters", setVehicleData, { available_params })
runner.Step("SetInteriorVehicleData rejected with absent parameter", setVehicleData, { absent_params })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
