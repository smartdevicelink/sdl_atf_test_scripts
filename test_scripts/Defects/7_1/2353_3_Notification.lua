---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/2353
---------------------------------------------------------------------------------------------------
-- Description: Check SDL is able to proceed with notification from HMI after cut off of fake parameters
-- Scenario: notification that SDL should transfer to mobile app
--
-- Steps:
-- 1. HMI sends notification with fake parameter
-- SDL does:
--  - cut off fake parameters
--  - check whether notification is valid
--  - proceed with notification in case if it's valid and transfer it to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function sendOnSCU()
  local expDataToMobile = {
    systemCapability = {
      systemCapabilityType = "DISPLAYS",
      displayCapabilities = {
        {
          displayName = "MainDisplayName",
          windowCapabilities = {
            {
              windowID = 0,
              templatesAvailable = { "Tmpl1", "Tmpl2" }
            }
          }
        }
      }
    }
  }
  local dataFromHMI = utils.cloneTable(expDataToMobile)
  dataFromHMI.appID = common.getHMIAppId()
  dataFromHMI.systemCapability.fakeParam = "123"
  common.getHMIConnection():SendNotification("BasicCommunication.OnSystemCapabilityUpdated", dataFromHMI)
  common.getMobileSession():ExpectNotification("OnSystemCapabilityUpdated", expDataToMobile)
  :ValidIf(function(_, data)
      if data.payload.systemCapability.fakeParam then
        return false, "Unexpected 'fakeParam' is received"
      end
      return true
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect regular mobile, start Session", common.start)
runner.Step("Register App", common.registerAppWOPTU)

runner.Title("Test")
runner.Step("HMI sends OnSystemCapabilityUpdated", sendOnSCU)

runner.Title("Postconditions")
runner.Step("Stop SDL, restore SDL settings and PPT", common.postconditions)
