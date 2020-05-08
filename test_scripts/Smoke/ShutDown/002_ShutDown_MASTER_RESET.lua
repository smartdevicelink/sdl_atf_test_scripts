--  Requirement summary:
--  [Policies] Master Reset
--
-- Description:
-- On Master Reset, Policy Manager must revert Local Policy Table
-- to the Preload Policy Table.
--
-- 1. Used preconditions
-- SDL and HMI are running
-- App is registered
--
-- 2. Performed steps
-- Perform Master Reset
-- HMI sends OnExitAllApplications with reason MASTER_RESET
--
-- Expected result:
-- 1. SDL clear all Apps folder, app_info.dat file and shut down
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local putFileParams = {
  requestParams = {
    syncFileName = 'icon.png',
    fileType = "GRAPHIC_PNG",
    persistentFile = false,
    systemFile = false
  },
  filePath = "files/icon.png"
}

-- [[ Local Functions ]]
local function expAppUnregistered()
  common.getMobileSession():ExpectNotification("OnAppInterfaceUnregistered", { reason = "MASTER_RESET" })
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
end

local function expResData()
  common.getHMIConnection():ExpectRequest("VR.AddCommand")
  :Times(0)
  common.getMobileSession():ExpectNotification("OnHashChange")
  :Times(0)
end

local function expResLvl()
  common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp")
  :Times(0)
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
  :Times(1)
end

local function listFiles()
  local cid = common.getMobileSession():SendRPC("ListFiles", {})
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :ValidIf(function(_, data)
      if data.payload.filenames ~= nil then
        return false, "Files in app storage was not removed"
      end
      return true
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("Add Command", common.addCommand)
runner.Step("Put File", common.putFile, { putFileParams })

runner.Title("Test")
runner.Step("Shutdown by MASTER_RESET", common.masterReset, { expAppUnregistered })
runner.Step("Start SDL, HMI, connect Mobile", common.start)
runner.Step("ReRegister App", common.reregisterApp, { "RESUME_FAILED", expResData, expResLvl })
runner.Step("List Files", listFiles)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
