---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/2448
--
-- Description: Check that SDL deletes application info (resumption data) file during MASTER_RESET`
--
-- Preconditions:
-- 1. Core and HMI are started and initialized
-- 2. Mobile app is registered and activated
-- 3. HMI sends OnExitAllApplications with reason MASTER_RESET
-- Sequence:
-- 1. Core shuts down and removes the application info storage
--  a. SDL deletes AppInfoStorage file in AppStorageFolder
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require("user_modules/script_runner")
--local common = require("user_modules/sequences/actions")
local common = require("test_scripts/Smoke/commonSmoke")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 5

--[[ Local Functions ]]
local function checkAppInfoWasCleared()
  local appInfoPath = config.pathToSDL .. common.sdl.getSDLIniParameter("AppStorageFolder")
    .. "/" .. common.sdl.getSDLIniParameter("AppInfoStorage")
  
  local f=io.open(name,"r")
  if f ~= nil then 
 		io.close(f)
    common.run.fail("App Info file was not cleared after MASTER_RESET")
  end
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI provides HMI capabilities", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Shutdown by MASTER_RESET", common.masterReset)
runner.Step("Check that SDL deletes app_info.dat resumption file", checkAppInfoWasCleared)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
