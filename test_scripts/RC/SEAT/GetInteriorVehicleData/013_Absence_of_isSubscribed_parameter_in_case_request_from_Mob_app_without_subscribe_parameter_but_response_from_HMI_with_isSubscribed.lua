---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/2
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/current_module_status_data.md
-- Item: Use Case 1: Main Flow
--
-- Requirement summary:
-- [SDL_RC] Current module status data GetInteriorVehicleData
--
-- Description: TRS: GetInteriorVehicleData, #2
-- In case:
-- 1) RC app sends valid and allowed-by-policies GetInteriorVehicleData_request without "subscribe" parameter
-- 2) and SDL gets GetInteriorVehicleData_response with resultCode: <"any-result">
-- 3) and with "isSubscribed" parameter from HMI
-- SDL must:
-- 1) transfer GetInteriorVehicleData_response with resultCode: <"any-result">
-- and without "isSubscribed" param to the related app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/SEAT/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function getDataForModule(pModuleType, isSubscriptionActive)
  local mobSession = commonRC.getMobileSession()
<<<<<<< 8ac10e1aed2095231a6cb629ea8cf692e92074a9
  local cid = mobSession:SendRPC("GetInteriorVehicleData", {
=======
  local cid = mobileSession:SendRPC("GetInteriorVehicleData", {
>>>>>>> Changes were done to the rc_seat
    moduleType = pModuleType
    -- no subscribe parameter
  })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {
    appID = commonRC.getHMIAppId(),
    moduleType = pModuleType
  })
  :Do(function(_, data)
      commonRC.getHMIconnection():SendResponse(data.id, data.method, "SUCCESS", {
        moduleData = commonRC.getModuleControlData(pModuleType),
        isSubscribed = isSubscriptionActive -- return current value of subscription
      })
    end)
  :ValidIf(function(_, data) -- no subscribe parameter
      if data.params.subscribe == nil then
        return true
      end
      return false, 'Parameter "subscribe" is transfered with to HMI value: ' .. tostring(data.params.subscribe)
    end)

  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS",
    moduleData = commonRC.getModuleControlData(pModuleType)
  })
  :ValidIf(function(_, data) -- no isSubscribed parameter
      if data.payload.isSubscribed == nil then
        return true
      end
      return false, 'Parameter "isSubscribed" is transfered to App with value: ' .. tostring(data.payload.isSubscribed)
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Step("Activate App", commonRC.activate_app)

runner.Title("Test")
runner.Step("GetInteriorVehicleData SEAT NoSubscription", getDataForModule, { "SEAT", false })
runner.Step("Subscribe app to SEAT", commonRC.subscribeToModule, { "SEAT" })
runner.Step("GetInteriorVehicleData SEAT ActiveSubscription_subscribe", getDataForModule, { "SEAT", true })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)