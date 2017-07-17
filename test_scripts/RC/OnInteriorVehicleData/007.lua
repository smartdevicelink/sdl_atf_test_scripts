---------------------------------------------------------------------------------------------------
-- RPC: OnInteriorVehicleData
-- Script: 007
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonRC = require('test_scripts/RC/commonRC')
local runner = require('user_modules/script_runner')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

--[[ Local Functions ]]
local function getModuleData(moduleType)
  if moduleType == "CLIMATE" then
    return { moduleType = moduleType, climateControlData = commonRC.getClimateControlData() }
  end
  return { moduleType = moduleType, radioControlData = commonRC.getRadioControlData() }
end

local function subscriptionToModule(pModuleType, self)
  local cid = self.mobileSession:SendRPC("GetInteriorVehicleData", {
      moduleDescription = {
          moduleType = pModuleType
        },
      subscribe = true
    })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {
      appID = self.applications["Test Application"],
      moduleDescription = {
        moduleType = pModuleType
      },
      subscribe = true
    })
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
          moduleData = 123, -- invalid data
          isSubscribed = true
        })
    end)

  EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
end

local function stepUnsubscribed(pModuleType, self)
  self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
      moduleData = getModuleData(pModuleType)
    })

  EXPECT_NOTIFICATION("OnInteriorVehicleData", {}):Times(0)
  commonTestCases:DelayedExp(commonRC.timeout)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Title("Test")
runner.Step("Subscribe app to CLIMATE (invalid response from HMI)", subscriptionToModule, {"CLIMATE"})
runner.Step("Send notification OnInteriorVehicleData_CLIMATE. App is not subscribed", stepUnsubscribed, {"CLIMATE"})
runner.Step("Subscribe app to RADIO (invalid response from HMI)", subscriptionToModule, {"RADIO"})
runner.Step("Send notification OnInteriorVehicleData RADIO. App is not subscribed", stepUnsubscribed, {"RADIO"})
runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
