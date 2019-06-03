---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0190-resumption-data-error-handling.md
--
-- Requirement summary:TBD
--
-- Description:
-- In case:
-- 1. App1 is subscribed to data_1, data_2, data_4
-- 2. App2 is subscribed to data_1, data_3
-- 3. Unexpected disconnect and reconnect are performed
-- 4. App1 and app2 reregister with actual HashId
-- 5. SubscribeVehicleData_2 gets successful result code for app2 and app1
-- 6. Subscription for data_1, data_2, data_3 related to app1 are requested on HMI during resumption
-- 7. HMI responds with erroneous internal resultCode for data_1 and with successful resultCode for data_2,data_4 for app1
-- 8. HMI responds with success to data_2, data_3 for app2
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

local vehicleDatafuelRange = {
  requestParams = { fuelRange = true },
  responseParams = { fuelRange = { resultCode = "SUCCESS", dataType = "VEHICLEDATA_FUELRANGE"} }
}

local onVehicleDataGps = {
  gps = {
    longitudeDegrees = 10,
    latitudeDegrees = 10
  }
}

local onVehicleDataFuelRange = {
  fuelRange = 10
}

-- [[ Local Function ]]
local function checkResumptionData()
  common.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData")
  :Do(function(_, data)
      if data.params.speed then
        local function sendResponse()
          common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {
            gps = { dataType = "VEHICLEDATA_GPS" , resultCode = "SUCCESS" },
            speed = { dataType = "VEHICLEDATA_SPEED", resultCode = "VEHICLE_DATA_NOT_AVAILABLE" },
            fuelRange = { dataType = "VEHICLEDATA_FUELRANGE" , resultCode = "SUCCESS" }
          })
        end
        RUN_AFTER(sendResponse, 300)
      else
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {
          gps = { dataType = "VEHICLEDATA_GPS" , resultCode = "SUCCESS" },
          rpm = vehicleDataRpm.responseParams.rpm
        })
      end
    end)
  :Times(2)

  common.getHMIConnection():ExpectRequest("VehicleInfo.UnsubscribeVehicleData", { fuelRange = true })
  :Do(function(_,data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
end

local function onVehicleData(pParams, pTimesForApp2)
  common.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", pParams)
  common.getMobileSession(1):ExpectNotification("OnVehicleData")
  :Times(0)
  common.getMobileSession(2):ExpectNotification("OnVehicleData", pParams)
  :Times(pTimesForApp2)
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
runner.Step("Add for app1 subscribeVehicleData fuelRange", common.subscribeVehicleData, { 1, vehicleDatafuelRange })
runner.Step("Add for app2 subscribeVehicleData gps", common.subscribeVehicleData, { 2, nil, 0 })
runner.Step("Add for app2 subscribeVehicleData rpm", common.subscribeVehicleData, { 2, vehicleDataRpm })
runner.Step("Unexpected disconnect", common.unexpectedDisconnect)
runner.Step("Connect mobile", common.connectMobile)
runner.Step("openRPCserviceForApp1", common.openRPCservice, { 1 })
runner.Step("openRPCserviceForApp2", common.openRPCservice, { 2 })
runner.Step("Reregister Apps resumption", common.reRegisterApps, { checkResumptionData })
runner.Step("Check subscriptions for gps", onVehicleData, { onVehicleDataGps, 1 })
runner.Step("Check subscriptions for fuelRange", onVehicleData, { onVehicleDataFuelRange, 0 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
