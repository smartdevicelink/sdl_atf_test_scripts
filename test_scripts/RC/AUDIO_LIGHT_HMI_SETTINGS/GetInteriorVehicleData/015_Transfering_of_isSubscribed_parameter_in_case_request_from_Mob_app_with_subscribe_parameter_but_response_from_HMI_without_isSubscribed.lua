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
local common = require('test_scripts/RC/AUDIO_LIGHT_HMI_SETTINGS/commonRCmodules')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function getDataForModule(pModuleType, isSubscriptionActive, pSubscribe)
  local mobileSession = common.getMobileSession()
  local cid = mobileSession:SendRPC("GetInteriorVehicleData", {
      moduleType = pModuleType,
      subscribe = pSubscribe
    })

  local pSubscribeHMI = pSubscribe
  if isSubscriptionActive == pSubscribe then
    pSubscribeHMI = nil
  end

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {
      appID = common.getHMIAppId(),
      moduleType = pModuleType
    })
  :Do(function(_, data)
      common.getHMIconnection():SendResponse(data.id, data.method, "SUCCESS", {
          moduleData = common.getModuleControlData(pModuleType),
          -- no isSubscribed parameter
        })
    end)
  :ValidIf(function(_, data)
      if data.params.subscribe == pSubscribeHMI then
        return true
      end
      return false, 'Parameter "subscribe" is transfered to HMI with value: ' .. tostring(data.params.subscribe)
    end)

  mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS",
      isSubscribed = isSubscriptionActive, -- return current value of subscription
      moduleData = common.getModuleControlData(pModuleType)
    })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.rai_ptu_n)
runner.Step("Activate App", common.activate_app)

runner.Title("Test")

for _, mod in pairs(common.modules) do
  runner.Step("GetInteriorVehicleData " .. mod .. " NoSubscription_subscribe", getDataForModule,
    { mod, false, true })
  runner.Step("GetInteriorVehicleData " .. mod .. " NoSubscription_unsubscribe", getDataForModule,
    { mod, false, false })
end

for _, mod in pairs(common.modules) do
  runner.Step("Subscribe app to " .. mod, common.subscribeToModule, { mod })
  runner.Step("GetInteriorVehicleData " .. mod .. " ActiveSubscription_subscribe", getDataForModule,
    { mod, true, true })
  runner.Step("GetInteriorVehicleData " .. mod .. " ActiveSubscription_unsubscribe", getDataForModule,
    { mod, true, false })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
