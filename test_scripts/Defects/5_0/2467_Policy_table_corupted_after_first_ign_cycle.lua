---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/2467
---------------------------------------------------------------------------------------------------
-- Description: SDL does not change data in Policy database during Ignition cycle
--
-- Steps:
-- 1. SDL and HMI are started.
-- 2. App is registered and activated
-- 3. PTU is performed with "SendLocation" group
-- 4. Ignition cycle is performed
-- 5. App is registered and activated
-- 6. App sends SendLocation request
-- SDL does:
--  - respond with SendLocation(success = true, resultCode = "SUCCESS")
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('user_modules/sequences/actions')
local runner = require('user_modules/script_runner')
local utils = require("user_modules/utils")
local color = require("user_modules/consts").color
local SDL = require("SDL")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function pTUpdateFunc(tbl)
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].groups =
    { "Base-4", "SendLocation" }
end

local function sendLocation()
  local cid = common.getMobileSession():SendRPC("SendLocation",
    { longitudeDegrees = 1.1, latitudeDegrees = 1.1 })
  common.getHMIConnection():ExpectRequest("Navigation.SendLocation", { longitudeDegrees = 1.1, latitudeDegrees = 1.1 })
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",{})
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true , resultCode = "SUCCESS" })
end

local function ignitionOff()
  local isOnSDLCloseSent = false
  common.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
      common.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications",
        { reason = "IGNITION_OFF" })
      common.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose")
      :Do(function()
          isOnSDLCloseSent = true
          SDL.DeleteFile()
        end)
    end)
  common.run.wait(3000)
  :Do(function()
      if isOnSDLCloseSent == false then utils.cprint(color.magenta, "BC.OnSDLClose was not sent") end
      common.mobile.deleteSession()
      StopSDL()
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { pTUpdateFunc })
runner.Step("Activate App", common.activateApp)
runner.Step("Send Location", sendLocation)
runner.Step("IGNITION_OFF", ignitionOff)

-- [[ Test ]]
runner.Step("IGNITION_ON", common.start)
runner.Step("Register App", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)
runner.Step("Send Location after Ignition cycle", sendLocation)

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
