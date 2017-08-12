---------------------------------------------------------------------------------------------------
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
local commonRC = require('test_scripts/RC/commonRC')

--[[ Local Variables ]]
local modules = { "CLIMATE", "RADIO" }

--[[ Local Functions ]]
local function subscriptionToModule(pModuleType, pSubscribe, self)
  local cid = self.mobileSession:SendRPC("GetInteriorVehicleData", {
    moduleType = pModuleType,
    subscribe = pSubscribe
  })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {
    appID = self.applications["Test Application"],
    moduleType = pModuleType
  })
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
        moduleData = commonRC.getModuleControlData(pModuleType),
        isSubscribed = pSubscribe
      })
    end)
  :ValidIf(function(_, data)
      if data.params.subscribe == nil then
        return true
      end
      return false, 'Parameter "subscribe" is transfered to HMI with value: ' .. tostring(data.params.subscribe)
    end)

  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS",
    moduleData = commonRC.getModuleControlData(pModuleType),
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

for _, mod in pairs(modules) do
  -- app has not subscribed yet
  runner.Step("Unsubscribe app to " .. mod, subscriptionToModule, { mod, false })
  runner.Step("Send notification OnInteriorVehicleData " .. mod .. ". App is not subscribed", commonRC.isUnsubscribed, { mod })

  -- subscribe to module 1st time
  runner.Step("Subscribe app to " .. mod, commonRC.subscribeToModule, { mod })
  runner.Step("Send notification OnInteriorVehicleData " .. mod .. ". App is subscribed", commonRC.isSubscribed, { mod })

  -- subscribe to module 2nd time
  runner.Step("Subscribe 2nd time app to " .. mod, subscriptionToModule, { mod, true })
  runner.Step("Send notification OnInteriorVehicleData " .. mod .. ". App is subscribed", commonRC.isSubscribed, { mod })

  -- unsubscribe to module 1st time
  runner.Step("Unsubscribe app to " .. mod, commonRC.unSubscribeToModule, { mod })
  runner.Step("Send notification OnInteriorVehicleData " .. mod .. ". App is not subscribed", commonRC.isUnsubscribed, { mod })

  -- unsubscribe to module 2nd time
  runner.Step("Unsubscribe 2nd time app to " .. mod, subscriptionToModule, { mod, false })
  runner.Step("Send notification OnInteriorVehicleData " .. mod .. ". App is not subscribed", commonRC.isUnsubscribed, { mod })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
