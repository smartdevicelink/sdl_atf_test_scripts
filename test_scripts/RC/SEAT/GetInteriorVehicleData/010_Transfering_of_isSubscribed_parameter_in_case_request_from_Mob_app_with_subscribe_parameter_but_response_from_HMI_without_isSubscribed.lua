---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0105-remote-control-seat.md
-- User story:
-- Use case:
-- Item:
--
-- Description: TRS: GetInteriorVehicleData, #1
-- In case:
-- 1) RC app sends valid and allowed by policies GetInteriorvehicleData_request with "subscribe" parameter
-- 2) and SDL received GetInteriorVehicledata_response with resultCode: <"any_not_erroneous_result">
-- 3) and without "isSubscribed" parameter from HMI
-- SDL must:
-- 1) transfer GetInteriorVehicleData_response with resultCode:<"any_not_erroneous_result">
-- and with added isSubscribed: <"current_subscription_status"> to the related app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/SEAT/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function getDataForModule(pModuleType, isSubscriptionActive, pSubscribe)
  local mobSession = commonRC.getMobileSession()
  local cid = mobSession:SendRPC("GetInteriorVehicleData", {
    moduleType = pModuleType,
    subscribe = pSubscribe
  })

  local pSubscribeHMI = pSubscribe
  if isSubscriptionActive == pSubscribe then
    pSubscribeHMI = nil
  end

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {
    appID = commonRC.getHMIAppId(),
    moduleType = pModuleType
  })
  :Do(function(_, data)
       commonRC.getHMIconnection():SendResponse(data.id, data.method, "SUCCESS", {
        moduleData = commonRC.getModuleControlData(pModuleType),
        -- no isSubscribed parameter
      })
    end)
  :ValidIf(function(_, data)
      if data.params.subscribe == pSubscribeHMI then
        return true
      end
      return false, 'Parameter "subscribe" is transfered to HMI with value: ' .. tostring(data.params.subscribe)
    end)

  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS",
    isSubscribed = isSubscriptionActive, -- return current value of subscription
    moduleData = commonRC.getModuleControlData(pModuleType)
  })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Step("Activate App", commonRC.activate_app)

runner.Title("Test")
runner.Step("GetInteriorVehicleData SEAT NoSubscription_subscribe", getDataForModule, { "SEAT", false, true })
runner.Step("GetInteriorVehicleData SEAT NoSubscription_unsubscribe", getDataForModule, { "SEAT", false, false })

runner.Step("Subscribe app to SEAT", commonRC.subscribeToModule, { "SEAT" })
runner.Step("GetInteriorVehicleData SEAT ActiveSubscription_subscribe", getDataForModule, { "SEAT", true, true })
runner.Step("GetInteriorVehicleData SEAT ActiveSubscription_unsubscribe", getDataForModule, { "SEAT", true, false })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
