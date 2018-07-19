---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0105-remote-control-seat.md
-- User story:
-- Use case:
-- Item:
--
-- Description: TRS: GetInteriorVehicleData, #12
-- In case:
-- 1) RC app is subscribed to "<moduleType_value>"
-- 2) and sends valid and allowed-by-policies GetInteriorVehicleData request
-- 3) with "subscribe:true" parameter for the same "<moduleType_value>"
-- SDL must:
-- 1) Forward request to HMI without "subscribe:true" parameter
-- 2) not change the subscription status of the app
-- 3) transfer HMI's response with added "isSubscribed: true" to the app
--
-- Description: TRS: GetInteriorVehicleData, #13
-- In case:
-- 1) RC app is not subscribed to "<moduleType_value>"
-- 2) and sends valid and allowed-by-policies GetInteriorVehicleData request
-- 3) with "subscribe:false" parameter for the same "<moduleType_value>"
-- SDL must:
-- 1) Forward request to HMI without "subscribe:false" parameter
-- 2) not change the subscription status of the app
-- 3) transfer HMI's response with added "isSubscribed: false" to the app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/SEAT/commonRC')
local initialCommon = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function subscriptionToModule(pModuleType, pSubscribe, pHMIrequest)
  local mobSession = commonRC.getMobileSession()
  local cid = mobSession:SendRPC("GetInteriorVehicleData", {
    moduleType = pModuleType,
    subscribe = pSubscribe
  })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {
    moduleType = pModuleType
  })
  :Do(function(_, data)
      commonRC.getHMIconnection():SendResponse(data.id, data.method, "SUCCESS", {
        moduleData = initialCommon.actualInteriorDataStateOnHMI[pModuleType],
        isSubscribed = pSubscribe
      })
    end)
  :ValidIf(function(_, data)
      if data.params.subscribe == nil then
        return true
      end
      return false, 'Parameter "subscribe" is transfered to HMI with value: ' .. tostring(data.params.subscribe)
    end)
  :Times(pHMIrequest)
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS",
    moduleData = initialCommon.actualInteriorDataStateOnHMI[pModuleType],
    isSubscribed = pSubscribe
  })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Step("Activate App", commonRC.activate_app)

runner.Title("Test")
-- app has not subscribed yet
runner.Step("Unsubscribe app to SEAT", subscriptionToModule, { "SEAT", false, 1 })
runner.Step("Send notification OnInteriorVehicleData SEAT. App is not subscribed", commonRC.isUnsubscribed, { "SEAT" })
-- subscribe to module 1st time
runner.Step("Subscribe app to SEAT", commonRC.subscribeToModule, { "SEAT", 1 })
runner.Step("Send notification OnInteriorVehicleData SEAT. App is subscribed", commonRC.isSubscribed, { "SEAT" })
-- subscribe to module 2nd time
runner.Step("Subscribe 2nd time app to SEAT", subscriptionToModule, { "SEAT", true, 0 })
runner.Step("Send notification OnInteriorVehicleData SEAT. App is subscribed", commonRC.isSubscribed, { "SEAT" })
-- unsubscribe to module 1st time
runner.Step("Unsubscribe app to SEAT", commonRC.unSubscribeToModule, { "SEAT", 1 })
runner.Step("Send notification OnInteriorVehicleData SEAT. App is not subscribed", commonRC.isUnsubscribed, { "SEAT" })
-- unsubscribe to module 2nd time
runner.Step("Unsubscribe 2nd time app to SEAT", subscriptionToModule, { "SEAT", false, 1 })
runner.Step("Send notification OnInteriorVehicleData SEAT. App is not subscribed", commonRC.isUnsubscribed, { "SEAT" })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
