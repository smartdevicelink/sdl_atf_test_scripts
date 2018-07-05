---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/5
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/unsubscribe_from_module_status_change_notification.md
-- Item: Use Case 1: Alternative flow 1
--
-- Requirement summary:
-- [SDL_RC] Unsubscribe from RC module change notifications
--
-- Description: TRS: GetInteriorVehicleData, #9
-- In case:
-- 1) RC app is subscribed to "<moduleType_value>"
-- 2) and RC app sends valid and allowed-by-policies GetInteriorVehicleData request with "subscribe:false" parameter
-- 3) and SDL received GetInteriorVehicleData response with "isSubscribed: true", "resultCode: SUCCESS" from HMI
-- 4) and then SDL received OnInteriorVehicleData notification
-- SDL must:
-- 1) Transfer GetInteriorVehicleData response with "isSubscribed: true", "resultCode: SUCCESS", "success:true" to the related app
-- 2) Re-send OnInteriorVehicleData notification to the app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/AUDIO_LIGHT_HMI_SETTINGS/commonRCmodules')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local modules = { "AUDIO", "LIGHT", "HMI_SETTINGS" }

--[[ Local Functions ]]
local function unSubscriptionToModule(pModuleType)
  local mobileSession = common.getMobileSession()
  local cid = mobileSession:SendRPC("GetInteriorVehicleData", {
      moduleType = pModuleType,
      subscribe = false
    })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {
      appID = common.getHMIAppId(),
      moduleType = pModuleType,
      subscribe = false
    })
  :Do(function(_, data)
      common.getHMIconnection():SendResponse(data.id, data.method, "SUCCESS", {
          moduleData = common.getModuleControlDataForResponse(pModuleType),
          isSubscribed = true -- HMI responds with true
        })
    end)

  mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS",
      moduleData = common.getModuleControlDataForResponse(pModuleType),
      isSubscribed = true
    })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.raiPTUn)
runner.Step("Activate App", common.activateApp)

for _, mod in pairs(modules) do
  runner.Step("Subscribe app to " .. mod, common.subscribeToModule, { mod })
  runner.Step("Send notification OnInteriorVehicleData " .. mod .. ". App is subscribed", common.isSubscribed, { mod })
end

runner.Title("Test")

for _, mod in pairs(modules) do
  runner.Step("Subscribe app to " .. mod, unSubscriptionToModule, { mod })
  runner.Step("Send notification OnInteriorVehicleData " .. mod .. ". App still subscribed", common.isSubscribed, { mod })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
