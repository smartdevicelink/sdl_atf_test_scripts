---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0190-resumption-data-error-handling.md
--
-- Requirement summary:TBD
--
-- Description:
-- In case:
-- 1. App1 is subscribed to data_1
-- 2. App2 is subscribed to data_1
-- 3. Transport disconnect and reconnect are performed
-- 4. Apps reregister with actual HashId
-- 5. VehicleInfo.SubscribeVD(data_1) is sent from SDL to HMI during resumption for app1
-- 6. SDL starts resume subscription for app2, does not send VehicleInfo.SubscribeVD and waits response to already sent VehicleInfo.SubscribeVD request
-- 7. HMI responds with error resultCode to VehicleInfo.SubscribeVD(data_1) request
-- 8. VehicleInfo.SubscribeVD(data_1) is sent from SDL to HMI during resumption for app2
-- 9. HMI responds with successw resultCode to VehicleInfo.SubscribeVD(data_1) request for app2
-- SDL does:
-- 1. process unsuccess response from HMI
-- 2. remove restored data for app1
-- 3. respond RegisterAppInterfaceResponse(success=true,result_code=RESUME_FAILED) to app1
-- 4. respond RegisterAppInterfaceResponse(success=true,result_code=SUCCESS) to app2
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
  local isResponseSent = false
  common.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData")
  :Do(function(exp, data)
      if exp.occurences == 1 and data.params.gps then
        local function sendResponse()
          common.getHMIConnection():SendError(data.id, data.method, "GENERIC_ERROR", "info message")
          isResponseSent = true
        end
        RUN_AFTER(sendResponse, 1000)
      else
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {
          gps = { dataType = "VEHICLEDATA_GPS" , resultCode = "SUCCESS" },
          rpm = vehicleDataRpm.responseParams.rpm
        })
      end
    end)
  :ValidIf(function(exp)
    if exp.occurences == 2 and isResponseSent == false then
      return false, "VehicleInfo.SubscribeVehicleData request for app2 is received earlier then response for app1 is sent"
    end
    return true
  end)
  :Times(2)

  common.getHMIConnection():ExpectRequest("VehicleInfo.UnsubscribeVehicleData", vehicleDataSpeed.requestParams)
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
runner.Step("Add for app2 subscribeVehicleData rpm", common.subscribeVehicleData, { 2, vehicleDataRpm })
runner.Step("Unexpected disconnect", common.unexpectedDisconnect)
runner.Step("Connect mobile", common.connectMobile)
runner.Step("openRPCserviceForApp1", common.openRPCservice, { 1 })
runner.Step("openRPCserviceForApp2", common.openRPCservice, { 2 })
runner.Step("Reregister Apps resumption ", common.reRegisterApps, { checkResumptionData })
runner.Step("Check subscriptions for gps", onVehicleData)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
