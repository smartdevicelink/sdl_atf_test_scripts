---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/3163
---------------------------------------------------------------------------------------------------
-- Steps:
-- 1. SDL and HMI started
-- 2. Wait 5 seconds
-- 3. Simulate gear change to R
-- 4. Wait 5 seconds
-- 5. Simulate gear change to D
-- 6. After 10 seconds, simulate gear change to P.
-- 7. Wait 5 seconds
-- 8. Perform ignition off
-- 9. Repeat 1-8 steps
-- SDL does:
--  - work without crashes
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local events = require('events')
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local Functions ]]
local function ignitionOff()
  local timeout = 5000
  local event = events.Event()
  event.matches = function(event1, event2) return event1 == event2 end
  EXPECT_EVENT(event, "SDL shutdown")
  :Do(function()
      StopSDL()
    end)
  common.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
      common.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications",{ reason = "IGNITION_OFF" })
    end)
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
  :Times(0)

  local isSDLShutDownSuccessfully = false
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose")
  :Do(function()
      utils.cprint(35, "SDL was shutdown successfully")
      isSDLShutDownSuccessfully = true
      RAISE_EVENT(event, event)
    end)
  :Timeout(timeout)
  local function forceStopSDL()
    if isSDLShutDownSuccessfully == false then
      utils.cprint(35, "SDL was shutdown forcibly")
      RAISE_EVENT(event, event)
    end
  end
  RUN_AFTER(forceStopSDL, timeout + 500)
end

local function gearChanging(pValue)
  common.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { prndl = pValue })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)

runner.Title("Test")
for i = 1,10 do
  runner.Title("SDL restart iteration " .. i)
  runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  runner.Step("Wait 5 seconds", common.run.wait, { 5000 })
  runner.Step("Change gear to `REVERSE`", gearChanging, { "REVERSE" })
  runner.Step("Wait 5 seconds", common.run.wait, { 5000 })
  runner.Step("Change gear to `DRIVE`", gearChanging, { "DRIVE" })
  runner.Step("Wait 10 seconds", common.run.wait, { 10000 })
  runner.Step("Change gear to `PARK`", gearChanging, { "PARK" })
  runner.Step("Ignition off", ignitionOff)
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
