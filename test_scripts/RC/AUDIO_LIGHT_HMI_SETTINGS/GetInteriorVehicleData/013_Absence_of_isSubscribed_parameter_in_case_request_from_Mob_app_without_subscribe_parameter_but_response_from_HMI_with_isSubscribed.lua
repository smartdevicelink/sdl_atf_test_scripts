---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/2
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/current_module_status_data.md
-- Item: Use Case 1: Main Flow
--
-- Requirement summary:
-- [SDL_RC] Current module status data GetInteriorVehicleData
--
-- Description: TRS: GetInteriorVehicleData, #2
-- In case:
-- 1) RC app sends valid and allowed-by-policies GetInteriorVehicleData_request without "subscribe" parameter
-- 2) and SDL gets GetInteriorVehicleData_response with resultCode: <"any-result">
-- 3) and with "isSubscribed" parameter from HMI
-- SDL must:
-- 1) transfer GetInteriorVehicleData_response with resultCode: <"any-result">
-- and without "isSubscribed" param to the related app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/AUDIO_LIGHT_HMI_SETTINGS/commonRCmodules')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function getDataForModule(pModuleType, isSubscriptionActive)
  local mobileSession = common.getMobileSession()
  local cid = mobileSession:SendRPC("GetInteriorVehicleData", {
      moduleType = pModuleType
      -- no subscribe parameter
    })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {
      appID = common.getHMIAppId(),
      moduleType = pModuleType
    })
  :Do(function(_, data)
      common.getHMIconnection():SendResponse(data.id, data.method, "SUCCESS", {
          moduleData = common.getModuleControlData(pModuleType),
          isSubscribed = isSubscriptionActive -- return current value of subscription
        })
    end)
  :ValidIf(function(_, data) -- no subscribe parameter
      if data.params.subscribe == nil then
        return true
      end
      return false, 'Parameter "subscribe" is transfered with to HMI value: ' .. tostring(data.params.subscribe)
    end)

  mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS",
      moduleData = common.getModuleControlData(pModuleType)
    })
  :ValidIf(function(_, data) -- no isSubscribed parameter
      if data.payload.isSubscribed == nil then
        return true
      end
      return false, 'Parameter "isSubscribed" is transfered to App with value: ' .. tostring(data.payload.isSubscribed)
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.raiPTUn)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")

for _, mod in pairs(common.modules) do
  runner.Step("GetInteriorVehicleData " .. mod .. " NoSubscription", getDataForModule, { mod, false })
end

for _, mod in pairs(common.modules) do
  runner.Step("Subscribe app to " .. mod, common.subscribeToModule, { mod })
  runner.Step("GetInteriorVehicleData " .. mod .. " ActiveSubscription_subscribe", getDataForModule, { mod, true })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
