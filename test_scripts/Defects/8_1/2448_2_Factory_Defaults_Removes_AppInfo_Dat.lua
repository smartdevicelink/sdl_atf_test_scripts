---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/2448
--
-- Description: Check that SDL deletes application info (resumption data) file during FACTORY_DEFAULTS
--
-- Preconditions:
-- 1. Core and HMI are started and initialized
-- 2. Mobile app is registered and activated
-- 3. HMI sends OnExitAllApplications with reason FACTORY_DEFAULTS
-- Steps:
-- 1. Core shuts down and removes the application info storage
--  a. SDL deletes AppInfoStorage file in AppStorageFolder
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require("user_modules/script_runner")
local common = require('user_modules/sequences/actions')
local SDL = require("SDL")
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 5

--[[ Local Functions ]]
local function checkAppInfoWasCleared()
  local appInfoPath = config.pathToSDL .. common.sdl.getSDLIniParameter("AppStorageFolder")
    .. "/" .. common.sdl.getSDLIniParameter("AppInfoStorage")
  local f = io.open(appInfoPath,"r")
  if f ~= nil then
    io.close(f)
    common.run.fail("App Info file was not cleared after FACTORY_DEFAULTS")
  end
end

local function factoryDefaults()
  local isOnSDLCloseSent = false
  common.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications",
    { reason = "FACTORY_DEFAULTS" })
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose")
  :Do(function()
      isOnSDLCloseSent = true
      SDL.DeleteFile()
    end)
  common.run.wait(3000)
  :Do(function()
      if isOnSDLCloseSent == false then utils.cprint(35, "BC.OnSDLClose was not sent") end
      StopSDL()
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI provides HMI capabilities", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Shutdown by FACTORY_DEFAULTS", factoryDefaults)
runner.Step("Check that SDL deletes app_info.dat resumption file", checkAppInfoWasCleared)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
