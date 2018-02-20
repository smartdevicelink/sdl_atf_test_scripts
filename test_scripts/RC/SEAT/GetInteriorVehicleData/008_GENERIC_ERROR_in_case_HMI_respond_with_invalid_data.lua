---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/2
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/current_module_status_data.md
-- Item: Use Case 1: Exceptions: 5.1
--
-- Requirement summary:
-- [SDL_RC] Current module status data GetInteriorVehicleData
--
-- Description:
-- In case:
-- 1) RC app sends GetInteriorVehicleData request with valid parameters
-- 2) and HMI responds with invalid data:
--    - invalid type of parameter
--    - missing mandatory parameter
-- SDL must:
-- 1) Respond to App with success:false, "GENERIC_ERROR"
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/SEAT/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function invalidParamType(pModuleType)
  local mobSession = commonRC.getMobileSession()
<<<<<<< 8ac10e1aed2095231a6cb629ea8cf692e92074a9
  local cid = mobSession:SendRPC("GetInteriorVehicleData", {
=======
  local cid = mobileSession1:SendRPC("GetInteriorVehicleData", {
>>>>>>> Changes were done to the rc_seat
    moduleType = pModuleType,
    subscribe = true
  })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {
    appID = commonRC.getHMIAppId(),
    moduleType = pModuleType,
    subscribe = true
  })
  :Do(function(_, data)
      commonRC.getHMIconnection():SendResponse(data.id, data.method, "SUCCESS", {
        moduleData = commonRC.getModuleControlData(pModuleType),
        isSubscribed = "yes" -- invalid type of parameter
      })
    end)

  mobSession:ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
end

local function missingMandatoryParam(pModuleType)
  local mobSession = commonRC.getMobileSession()
<<<<<<< 8ac10e1aed2095231a6cb629ea8cf692e92074a9
  local cid = mobSession:SendRPC("GetInteriorVehicleData", {
=======
  local cid = self.mobileSession1:SendRPC("GetInteriorVehicleData", {
>>>>>>> Changes were done to the rc_seat
    moduleType = pModuleType,
    subscribe = true
  })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {
    appID = commonRC.getHMIAppId(),
<<<<<<< 8ac10e1aed2095231a6cb629ea8cf692e92074a9
    moduleType = pModuleType,
=======
>>>>>>> Changes were done to the rc_seat
    subscribe = true
  })

  :Do(function(_, data)
      local moduleData = commonRC.getModuleControlData(pModuleType)
      moduleData.moduleType = nil -- missing mandatory parameter
      commonRC.getHMIconnection():SendResponse(data.id, data.method, "SUCCESS", {
        moduleData = moduleData,
        isSubscribed = true
      })
    end)

<<<<<<< 8ac10e1aed2095231a6cb629ea8cf692e92074a9
  mobSession:ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
=======
  mobileSession:ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
>>>>>>> Changes were done to the rc_seat
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Step("Activate App", commonRC.activate_app)

runner.Title("Test")
<<<<<<< 8ac10e1aed2095231a6cb629ea8cf692e92074a9
runner.Step("GetInteriorVehicleData SEAT Invalid response from HMI-Invalid type of parameter", invalidParamType,
  { "SEAT" })
runner.Step("GetInteriorVehicleData SEAT Invalid response from HMI-Missing mandatory parameter", missingMandatoryParam,
  { "SEAT" })
=======
  runner.Step("GetInteriorVehicleData SEAT Invalid response from HMI-Invalid type of parameter", invalidParamType, { SEAT })
  runner.Step("GetInteriorVehicleData SEAT Invalid response from HMI-Missing mandatory parameter", missingMandatoryParam, { SEAT })
end
>>>>>>> Changes were done to the rc_seat

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
