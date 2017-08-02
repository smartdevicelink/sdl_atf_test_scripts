---------------------------------------------------------------------------------------------------
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
local commonRC = require('test_scripts/RC/commonRC')

--[[ Local Variables ]]
local modules = { "CLIMATE", "RADIO" }

--[[ Local Functions ]]
local function getDataForModule(pModuleType, isSubscriptionActive, self)
  local cid = self.mobileSession:SendRPC("GetInteriorVehicleData", {
    moduleType = pModuleType
    -- no subscribe parameter
  })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {
    appID = self.applications["Test Application"],
    moduleType = pModuleType
  })
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
        moduleData = commonRC.getModuleControlData(pModuleType),
        isSubscribed = isSubscriptionActive -- return current value of subscription
      })
    end)
  :ValidIf(function(_, data) -- no subscribe parameter
      if data.params.subscribe == nil then
        return true
      end
      return false, 'Parameter "subscribe" is transfered with to HMI value: ' .. tostring(data.params.subscribe)
    end)

  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS",
    moduleData = commonRC.getModuleControlData(pModuleType)
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
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)

runner.Title("Test")

for _, mod in pairs(modules) do
  runner.Step("GetInteriorVehicleData " .. mod .. " NoSubscription", getDataForModule, { mod, false })
end

for _, mod in pairs(modules) do
  runner.Step("Subscribe app to " .. mod, commonRC.subscribeToModule, { mod, 1 })
  runner.Step("GetInteriorVehicleData " .. mod .. " ActiveSubscription_subscribe", getDataForModule, { mod, true })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
