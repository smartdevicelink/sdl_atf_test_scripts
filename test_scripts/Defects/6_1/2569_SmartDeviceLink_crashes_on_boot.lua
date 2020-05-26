---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2569
-- Description:
-- SmartDeviceLink crashes on boot.
-- Precondition:
-- 1) Simulate ignition OFF.
--   (Send from HMI send notification OnExitAllApplications(IGNITION_OFF))
-- 2) Wait 2 minutes.
-- 3) Simulate ignition ON. (start SDL)
-- 4) Wait between 1 and 16 seconds (varying in each iteration).
-- 5) Simulate gear change to R
--    (Send from HMI send request "VehicleInfo" {prndl="REVERSE"})
-- 6) Wait between 6 and 12 seconds (varying in each iteration).
-- 7) Simulate gear change to D
--    (Send from HMI send request "VehicleInfo" {prndl="DRIVE"})
-- 8) After 10 seconds, simulate gear change to P.
--    (Send from HMI send request "VehicleInfo" {prndl="PARK"})
-- 9) Wait 2 minutes.
--    Repeat 1 - 9 for several times.
-- Expected result:
-- 1) No catastrophic failures. All functionality verified.
-- Actual result:
-- SmartDeviceLink crashes on boot.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")
local SDL = require('SDL')
local test = require('user_modules/dummy_connecttest')
local utils = require('user_modules/utils')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local timeout = 1000

--[[ Local Functions ]]
local function ignitionOff()
    common.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications",
      { reason = "IGNITION_OFF" })
    common.getMobileSession():ExpectNotification("OnAppInterfaceUnregistered",
      { reason = "IGNITION_OFF" })
    common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered",
      { unexpectedDisconnect = true })
    common.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose")
    :Do(function()
      StopSDL()
    end)
end

local function OnVehicleData(pValue)
    common.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { prndl = pValue })
end

local function getStringSDLStatus(pStatus)
    if pStatus == SDL.STOPPED then
        return "STOPPED"
    elseif pStatus == SDL.RUNNING then
        return "RUNNING"
    elseif pStatus == SDL.CRASH then
        return "CRASH"
    end
    return nil
end

local  function checkStatusSDL()
    local status = SDL:CheckStatusSDL()
    utils.cprint(35, "SDL status:", tostring(getStringSDLStatus(status)))
    if status == SDL.STOPPED or status == SDL.CRASH then
        test:FailTestCase("SDL was stopped/crashed")
    end
end

--[[ Test ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
for i =  1, 10 do
    runner.Title("Start cycle " .. i )
    runner.Step("IGNITION_OFF", ignitionOff)
    runner.Step("Wait", utils.wait, { timeout }) -- 120000
    runner.Step("Ignition On", common.start)
    runner.Step("Wait", utils.wait, { timeout }) -- 16000
    runner.Step("HMI send request VehicleInfo prndl: REVERSE", OnVehicleData, { "REVERSE" })
    runner.Step("Wait", utils.wait, { timeout }) -- 12000
    runner.Step("HMI send request VehicleInfo prndl: DRIVE", OnVehicleData, { "DRIVE" })
    runner.Step("Wait", utils.wait, { timeout }) -- 10000
    runner.Step("HMI send request VehicleInfo prndl: PARK", OnVehicleData, { "PARK" })
    runner.Step("Wait", utils.wait, { timeout }) -- 120000
    runner.Step("Check status SDL", checkStatusSDL)
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
