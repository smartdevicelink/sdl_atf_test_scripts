---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0190-resumption-data-error-handling.md
--
-- Description:
-- Check vehicle data resumption succeeded for 2nd app after fail for the 1st app in case of shared data
-- (<erroneous> result code for the whole request scenario)
--
-- In case:
-- 1. App1 is subscribed to data_1, data_2 and data_3
-- 2. App2 is subscribed to data_3 and data_4
-- 3. Unexpected disconnect and reconnect are performed
-- 4. App1 and app2 re-register with actual HashId
-- SDL does:
--  - start resumption process for both apps
--  - send VI.SubscribeVehicleData(data_1, data_2, data_3) request related to app1 to HMI
--  - not send VI.SubscribeVehicleData(data_3, data_4) request related to app2 to HMI
-- 5. HMI responds with <erroneous> resultCode to VI.SubscribeVehicleData(data_1, data_2, data_3) request
-- SDL does:
--  - process response from HMI
--  - not restore subscriptions for app1 (data_1, data_2, data_3)
--  - respond RegisterAppInterfaceResponse(success=true,result_code=RESUME_FAILED) to mobile application app1
--  - not send VI.UnsubscribeVehicleData(data_1, data_2, data_3) request related to app1 to HMI
--  - send VI.SubscribeVehicleData(data_3, data_4) request related to app2 to HMI
-- 6. HMI responds with <successful> resultCode to VI.SubscribeVehicleData(data_3, data_4) request
-- SDL does:
--  - process response from HMI
--  - restore subscriptions for app2 (data_3, data_4)
--  - respond RegisterAppInterfaceResponse(success=true,result_code=SUCCESS)to mobile application app2
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Resumption/Handling_errors_from_HMI/commonResumptionErrorHandling')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local Variables ]]
local vehicleDataSpeed = {
  requestParams = { speed = true },
  responseParams = { speed = { resultCode = "SUCCESS", dataType = "VEHICLEDATA_SPEED" } }
}

local vehicleDataRpm = {
  requestParams = { rpm = true },
  responseParams = { rpm = { resultCode = "SUCCESS", dataType = "VEHICLEDATA_RPM" } }
}

local vehicleDatafuelRange = {
  requestParams = { fuelRange = true },
  responseParams = { fuelRange = { resultCode = "SUCCESS", dataType = "VEHICLEDATA_FUELRANGE" } }
}

-- [[ Local Function ]]
local function checkResumptionData()
  common.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData",
    { fuelRange = true, gps = true, speed = true }, { gps = true, rpm = true })
  :Do(function(_, data)
      common.log(data.method)
      if data.params.speed then
        local function sendResponse()
          common.log(data.method .. ": GENERIC_ERROR")
          common.getHMIConnection():SendError(data.id, data.method, "GENERIC_ERROR", "info message")
        end
        RUN_AFTER(sendResponse, 1000)
      else
        common.log(data.method .. ": SUCCESS")
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {
          gps = { resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS" },
          rpm = { resultCode = "SUCCESS", dataType = "VEHICLEDATA_RPM" }
        })
      end
    end)
  :Times(2)

  common.getHMIConnection():ExpectRequest("VehicleInfo.UnsubscribeVehicleData")
  :Do(function(_, data) common.log(data.method) end)
  :Times(0)
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
runner.Step("Reregister Apps resumption", common.reRegisterAppsWithError, { checkResumptionData })
runner.Step("Check subscriptions for speed", common.sendOnVehicleData, { "speed", false, false })
runner.Step("Check subscriptions for fuelRange", common.sendOnVehicleData, { "fuelRange", false, false })
runner.Step("Check subscriptions for gps", common.sendOnVehicleData, { "gps", false, true })
runner.Step("Check subscriptions for rpm", common.sendOnVehicleData, { "rpm", false, true })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
