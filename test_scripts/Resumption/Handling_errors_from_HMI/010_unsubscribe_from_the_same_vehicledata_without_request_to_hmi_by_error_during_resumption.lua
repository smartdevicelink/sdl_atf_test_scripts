---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0190-resumption-data-error-handling.md
--
-- Requirement summary:TBD
--
-- Description:
-- In case:
-- 1. SubscribeVehicleData_1, SubscribeVehicleData_2 are added by app1
-- 2. SubscribeVehicleData_2, SubscribeVehicleData_3 are added by app2
-- 3. Unexpected disconnect and reconnect are performed
-- 4. App1 and app2 reregister with actual HashId
-- 5. VehicleInfo.SubscribeVehicleData_2 requests for app2 and app1 are processed successful
-- 6. VehicleInfo.SubscribeVehicleData_3 related to app1 is sent from SDL to HMI during resumption
-- 7. HMI responds with error resultCode VehicleInfo.SubscribeVehicleData_3 request
-- 8. HMI responds with success to remaining requests
-- SDL does:
-- 1. process unsuccess response from HMI
-- 2. remove already restored data from app1, but does not send VehicleInfo.UnsubscribeVehicleData_2 to HMI
-- 3. respond RegisterAppInterfaceResponse(success=true,result_code=RESUME_FAILED) to mobile application app1
-- 4. restore all data for app2 and respond RegisterAppInterfaceResponse(success=true,result_code=SUCCESS)to mobile application app2
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Resumption/Handling_errors_from_HMI/commonResumptionErrorHandling')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local Variables ]]
local vehicleDataSpeed = {
  requestParams = { speed = true },
  responseParams = { speed = { resultCode = "SUCCESS", dataType = "VEHICLEDATA_SPEED"} }
}

local vehicleDataRpm = {
  requestParams = { rpm = true },
  responseParams = { rpm = { resultCode = "SUCCESS", dataType = "VEHICLEDATA_RPM"} }
}

-- [[ Local Function ]]
local function checkResumptionData()
  common.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData")
  :Do(function(_, data)
      if data.params.speed then
        local function sendResponse()
          common.getHMIConnection():SendError(data.id, data.method, "GENERIC_ERROR", "info message")
        end
        RUN_AFTER(sendResponse, 300)
      else
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      end
    end)
  :Times(4)

  common.getHMIConnection():ExpectRequest("VehicleInfo.UnsubscribeVehicleData")
  :Times(0)
end

local function onVehicleData()
  local notificationParams = {
    gps = {
      longitudeDegrees = 10,
      latitudeDegrees = 10
    }
  }
  common.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", notificationParams)
  common.getMobileSession(1):ExpectNotification("OnVehicleData")
  :Times(0)
  common.getMobileSession(2):ExpectNotification("OnVehicleData", notificationParams)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("Register app1", common.registerAppWOPTU)
runner.Step("Register app2", common.registerAppWOPTU, { 2 })
runner.Step("Activate app1", common.activateApp)
runner.Step("Activate app2", common.activateApp, { 2 })
runner.Step("Add for app1 subscribeVehicleData gps", common.subscribeVehicleData)
runner.Step("Add for app1 subscribeVehicleData speed", common.subscribeVehicleData, { 1, vehicleDataSpeed })
runner.Step("Add for app2 subscribeVehicleData gps", common.subscribeVehicleData, { 2, nil, 0 })
runner.Step("Add for app2 subscribeVehicleData fuelLevel", common.subscribeVehicleData, { 2, vehicleDataRpm })
runner.Step("Unexpected disconnect", common.unexpectedDisconnect)
runner.Step("Connect mobile", common.connectMobile)
runner.Step("openRPCserviceForApp1", common.openRPCservice, { 1 })
runner.Step("openRPCserviceForApp2", common.openRPCservice, { 2 })
runner.Step("Reregister Apps resumption", common.reRegisterApps, { checkResumptionData })
runner.Step("Check subscriptions for gps", onVehicleData)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
