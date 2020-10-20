---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/2
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/current_module_status_data.md
-- Item: Use Case 1: Main Flow
--
-- Requirement summary:
-- [SDL_RC] Current module status data GetInteriorVehicleData
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
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function getDataForModule(pModuleType, isSubscriptionActive, pSubscribe, pHMIRequest, pResultCode)
  local cid = commonRC.getMobileSession():SendRPC("GetInteriorVehicleData", {
    moduleType = pModuleType,
    subscribe = pSubscribe
  })

  local pSubscribeHMI = pSubscribe
  if isSubscriptionActive == pSubscribe then
    pSubscribeHMI = nil
  end

  commonRC.getHMIConnection():ExpectRequest("RC.GetInteriorVehicleData", {
    moduleType = pModuleType
  })
  :Do(function(_, data)
      commonRC.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {
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
  :Times(pHMIRequest)

  local resultCode = pResultCode or "SUCCESS"
  commonRC.getMobileSession():ExpectResponse(cid, { success = true, resultCode = resultCode,
    isSubscribed = isSubscriptionActive, -- return current value of subscription
    moduleData = commonRC.getModuleControlData(pModuleType)
  })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate App", commonRC.activateApp)

runner.Title("Test")

for _, mod in pairs(commonRC.modules) do
  runner.Step("GetInteriorVehicleData " .. mod .. " NoSubscription_subscribe", getDataForModule, { mod, false, true, 1 })
  runner.Step("GetInteriorVehicleData " .. mod .. " NoSubscription_unsubscribe", getDataForModule, { mod, false, false, 1 })
end

for _, mod in pairs(commonRC.modules)  do
  runner.Step("Subscribe app to " .. mod, commonRC.subscribeToModule, { mod })
  runner.Step("GetInteriorVehicleData " .. mod .. " ActiveSubscription_subscribe", getDataForModule, { mod, true, true, 0 , "WARNINGS"})
  runner.Step("GetInteriorVehicleData " .. mod .. " ActiveSubscription_unsubscribe", getDataForModule, { mod, true, false, 1 })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
