---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0190-resumption-data-error-handling.md
--
-- Description:
-- Check vehicle data resumption is failed in case if HMI responds with any <erroneous> result code to request from SDL
-- for at least one particular VD parameter
--
-- In case:
-- 1. App is subscribed to Vehicle Data: data_1 and data_2
-- 2. Unexpected disconnect and reconnect are performed
-- 3. App re-registers with actual HashId
-- SDL does:
--  - start resumption process
--  - send VI.SubscribeVehicleData request to HMI
-- 4. HMI responds with <erroneous> internal resultCode for data_1 and <successful> resultCode for data_2
--    to VI.SubscribeVehicleData request
-- SDL does:
--  - process response from HMI
--  - not restore subscriptions for app (data_1, data_2)
--  - send VI.UnsubscribeVehicleData(data_2) request to HMI
--  - respond RegisterAppInterfaceResponse(success=true,result_code=RESUME_FAILED) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Resumption/Handling_errors_from_HMI/commonResumptionErrorHandling')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local resultCodes = {
  "TRUNCATED_DATA",
  "DISALLOWED",
  "USER_DISALLOWED",
  "INVALID_ID",
  "VEHICLE_DATA_NOT_AVAILABLE",
  "DATA_ALREADY_SUBSCRIBED",
  "DATA_NOT_SUBSCRIBED",
  "IGNORED"
}

local vehicleDataSpeed = {
  requestParams = { speed = true },
  responseParams = { speed = { resultCode = "SUCCESS", dataType = "VEHICLEDATA_SPEED"} }
}

--[[ Local Functions ]]
local function reRegisterApp(pAppId, pErrorCode)
  local mobSession = common.getMobileSession(pAppId)
  mobSession:StartService(7)
  :Do(function()
      local params = common.cloneTable(common.getConfigAppParams(pAppId))
      params.hashID = common.hashId[pAppId]
      local corId = mobSession:SendRPC("RegisterAppInterface", params)
      common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered", {
          application = { appName = common.getConfigAppParams(pAppId).appName }
        })
      mobSession:ExpectResponse(corId, { success = true, resultCode = "RESUME_FAILED" })
      :Do(function()
          mobSession:ExpectNotification("OnPermissionsChange")
        end)
    end)
  common.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData", { gps = true, speed = true })
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {
        gps = { dataType = "VEHICLEDATA_GPS", resultCode = pErrorCode },
        speed = { dataType = "VEHICLEDATA_SPEED", resultCode = "SUCCESS" }
      })
    end)

  common.getHMIConnection():ExpectRequest("VehicleInfo.UnsubscribeVehicleData", vehicleDataSpeed.requestParams)
  :Do(function(_,data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {
        speed = { dataType = "VEHICLEDATA_SPEED" , resultCode = "SUCCESS" }
      })
    end)

  common.resumptionFullHMILevel(pAppId)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
for _, code in common.pairs(resultCodes) do
  runner.Step("Register app", common.registerAppWOPTU)
  runner.Step("Activate app", common.activateApp)
  runner.Step("Add subscribeVehicleData gps", common.subscribeVehicleData)
  runner.Step("Add subscribeVehicleData speed", common.subscribeVehicleData, { 1, vehicleDataSpeed })
  runner.Step("Unexpected disconnect", common.unexpectedDisconnect)
  runner.Step("Connect mobile", common.connectMobile)
  runner.Step("Reregister App resumption with error code " .. code, reRegisterApp, { 1, code })
  runner.Step("Unregister App", common.unregisterAppInterface)
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
