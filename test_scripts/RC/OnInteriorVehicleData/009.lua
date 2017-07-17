---------------------------------------------------------------------------------------------------
-- RPC: OnInteriorVehicleData
-- Script: 009
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonRC = require('test_scripts/RC/commonRC')
local runner = require('user_modules/script_runner')

--[[ Local Functions ]]
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
          moduleData = commonRC.getModuleControlData(pModuleType),
          isSubscribed = true
        })
    end)

  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS",
      moduleData = commonRC.getModuleControlData(pModuleType),
      isSubscribed = true
    })
end

local function unSubscriptionToModule(pModuleType, self)
  local cid = self.mobileSession:SendRPC("GetInteriorVehicleData", {
      moduleDescription = {
        moduleType = pModuleType
      },
      subscribe = false
    })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {
      appID = self.applications["Test Application"],
      moduleDescription = {
        moduleType = pModuleType
      },
      subscribe = false
    })
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
          moduleData = commonRC.getModuleControlData(pModuleType),
          -- no isSubscribed parameter
        })
    end)

  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS",
      moduleData = commonRC.getModuleControlData(pModuleType),
      isSubscribed = true
    })
end

local function stepSubscribed(pModuleType, self)
  self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
      moduleData = commonRC.getAnotherModuleControlData(pModuleType)
    })

  EXPECT_NOTIFICATION("OnInteriorVehicleData", {
      moduleData = commonRC.getAnotherModuleControlData(pModuleType)
    })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Step("Subscribe app to CLIMATE", subscriptionToModule, {"CLIMATE"})
runner.Step("Send notification OnInteriorVehicleData_CLIMATE. App subscribed", stepSubscribed, {"CLIMATE"})
runner.Step("Subscribe app to RADIO", subscriptionToModule, {"RADIO"})
runner.Step("Send notification OnInteriorVehicleData_RADIO. App subscribed", stepSubscribed, {"RADIO"})
runner.Title("Test")
runner.Step("Unsubscribe app to CLIMATE", unSubscriptionToModule, {"CLIMATE"})
runner.Step("Send notification OnInteriorVehicleData_CLIMATE. App still subscribed", stepSubscribed, {"CLIMATE"})
runner.Step("Unsubscribe app to RADIO", unSubscriptionToModule, {"RADIO"})
runner.Step("Send notification OnInteriorVehicleData_RADIO. App still subscribed", stepSubscribed, {"RADIO"})
runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
