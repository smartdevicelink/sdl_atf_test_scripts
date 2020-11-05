---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/2
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/current_module_status_data.md
-- Item: Use Case 1: Main Flow
--
-- Requirement summary:
-- [SDL_RC] Current module status data GetInteriorVehicleData
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
local common = require("test_scripts/RC/commonRC")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function subscriptionToModule(pModuleType, pSubscribe, pHMIReqTimes, pResultCode)
  local mobileSession = common.getMobileSession()
  local cid = mobileSession:SendRPC("GetInteriorVehicleData", {
      moduleType = pModuleType,
      subscribe = pSubscribe
    })

  common.getHMIConnection():ExpectRequest("RC.GetInteriorVehicleData", {
      moduleType = pModuleType
    })
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {
          moduleData = common.getModuleControlDataForResponse(pModuleType),
          isSubscribed = pSubscribe
        })
    end)
  :ValidIf(function(_, data)
      if data.params.subscribe == nil then
        return true
      end
      return false, 'Parameter "subscribe" is transfered to HMI with value: ' .. tostring(data.params.subscribe)
    end)
  :Times(pHMIReqTimes)

  local resultCode = pResultCode or "SUCCESS"
  mobileSession:ExpectResponse(cid, { success = true, resultCode = resultCode,
      moduleData = common.getModuleControlDataForResponse(pModuleType),
      isSubscribed = pSubscribe
    })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")

for _, mod in pairs(common.modulesWithoutSeat) do
  -- app has not subscribed yet
  runner.Step("Unsubscribe app to " .. mod, subscriptionToModule, { mod, false, 1 })
  runner.Step("Send notification OnInteriorVehicleData " .. mod .. ". App is not subscribed", common.isUnsubscribed,
    { mod })

  -- subscribe to module 1st time
  runner.Step("Subscribe app to " .. mod, common.subscribeToModule, { mod })
  runner.Step("Send notification OnInteriorVehicleData " .. mod .. ". App is subscribed", common.isSubscribed,
    { mod })

  -- subscribe to module 2nd time
  runner.Step("Subscribe 2nd time app to " .. mod, subscriptionToModule, { mod, true, 0, "WARNINGS" })
  runner.Step("Send notification OnInteriorVehicleData " .. mod .. ". App is subscribed", common.isSubscribed,
    { mod })

  -- unsubscribe to module 1st time
  runner.Step("Unsubscribe app to " .. mod, common.unSubscribeToModule, { mod })
  runner.Step("Send notification OnInteriorVehicleData " .. mod .. ". App is not subscribed", common.isUnsubscribed,
    { mod })

  -- unsubscribe to module 2nd time
  runner.Step("Unsubscribe 2nd time app to " .. mod, subscriptionToModule, { mod, false, 1 })
  runner.Step("Send notification OnInteriorVehicleData " .. mod .. ". App is not subscribed", common.isUnsubscribed,
    { mod })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
