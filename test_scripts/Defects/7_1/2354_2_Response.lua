---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/2354
---------------------------------------------------------------------------------------------------
-- Description: Check SDL is able to proceed with response from HMI after cut off of fake parameters
-- Scenario: response that SDL should use internally
--
-- Steps:
-- 1. SDL sends some request to HMI
-- 2. HMI responds with fake parameter
-- SDL does:
--  - cut off fake parameters
--  - check whether response is valid
--  - proceed with response in case if it's valid
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")
local hmi_values = require('user_modules/hmi_values')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function getHMIParams()
  local params = hmi_values.getDefaultHMITable()
  params.VehicleInfo.GetVehicleType.params.vehicleType.fakeParam = "123"
  return params
end

local function registerApp()
  local session = common.mobile.createSession()
  session:StartService(7)
  :Do(function()
      local cid = session:SendRPC("RegisterAppInterface", common.app.getParams())
      common.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppRegistered")
      session:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
      :ValidIf(function(_, data)
          if data.payload.vehicleType.fakeParam then
            return false, "Unexpected 'fakeParam' is received"
          end
          return true
        end)
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect regular mobile, start Session", common.start, { getHMIParams() })

runner.Title("Test")
runner.Step("Register App", registerApp)

runner.Title("Postconditions")
runner.Step("Stop SDL, restore SDL settings and PPT", common.postconditions)
