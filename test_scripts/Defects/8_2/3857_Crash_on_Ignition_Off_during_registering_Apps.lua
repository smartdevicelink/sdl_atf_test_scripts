---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3857
---------------------------------------------------------------------------------------------------
-- Description: The crash occurs on Ignition OFF during registering Apps
---------------------------------------------------------------------------------------------------
-- Preconditions:
-- 1. SDL and HMI are started
-- In case:
-- 1. Register 5 Apps during Ignition OFF
-- SDL does:
--  - send OnSDLClose notification to HMI and not crash
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local utils = require("user_modules/utils")
local color = require("user_modules/consts").color
local events = require("events")
local SDL = require('SDL')
local atf_logger = require("atf_logger")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function log(...)
  local str = "[" .. atf_logger.formated_time(true) .. "]"
  for i, p in pairs({...}) do
    local delimiter = "\t"
    if i == 1 then delimiter = " " end
    str = str .. delimiter ..tostring(p)
  end
  utils.cprint(color.magenta, str)
end

local function startServiceMultiple()
  for i = 1,5 do
    common.mobile.createSession(i):StartService(7)
  end
end

local function registerMultipleApps(pAppId)
  local mobSession = common.mobile.getSession(pAppId)
  mobSession:SendRPC("RegisterAppInterface", common.app.getParams(pAppId))
  log("App->SDL", "RegisterAppInterface", pAppId)
end

local function ignitionOff()
  common.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  log("HMI->SDL", "OnExitAllApplications", "SUSPEND")
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
      log("HMI->SDL", "OnSDLPersistenceComplete")
      common.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications",
        { reason = "IGNITION_OFF" })
      log("HMI->SDL", "OnExitAllApplications", "IGNITION_OFF")
      common.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose")
      :Do(function()
          log("HMI->SDL", "BasicCommunication.OnSDLClose")
          SDL.DeleteFile()
          for i = 1, common.mobile.getAppsCount() do
            common.mobile.deleteSession(i)
          end
        end)
    end)
  common.run.wait(3000)
end

local function registerAppIgn()
  local isFailed = false
  ignitionOff()
  common.getMobileSession():ExpectEvent(events.disconnectedEvent, "Disconnected")
  :Do(function()
      utils.cprint(color.magenta, "Disconnected!!!")
      isFailed = true
    end)
  :Times(AnyNumber())
  for i = 1,5 do
    if not isFailed then
      registerMultipleApps(i)
    else
      utils.cprint(color.magenta, "Skipped")
    end
  end
end

local function checkSDLLogError()
  local fileName = config.pathToSDL .. "SmartDeviceLinkCore.log"
  local errorMessage = "SIGSEGV signal has been caught"
  for l in io.lines(fileName) do
    if string.find(l, errorMessage) ~= nil then
      common.run.fail("Error message" .. errorMessage .. "should not observed in smartDeviceLink.log.")
    end
  end
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)

runner.Title("Test")
runner.Step("Start SDL, HMI, connect Mobile", common.start)
runner.Step("Start services", startServiceMultiple)
runner.Step("Register multiple Apps during ignition Off", registerAppIgn)
runner.Step("Check error SIGSEGV message in SmartDeviceLinkCore.log", checkSDLLogError)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)

