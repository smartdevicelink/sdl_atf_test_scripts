---------------------------------------------------------------------------------------------------
-- User story:TBD
-- Use case:TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- Check that SDL does not the application registration with appID which has "null" permissions in Policy Table.
-- In case:
-- 1) Application registered with appID which has "null" permissions in Policy Table.
-- SDL does:
-- 1) Successfully register a mobile application
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Registration/commonRAI')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local utils = require('user_modules/utils')
local json = require("modules/json")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local preloadedPT = commonFunctions:read_parameter_from_smart_device_link_ini("PreloadedPT")
local paramsApp1 = common.getRequestParams(1)
paramsApp1.appID = "0000001"

--[[ Local Functions ]]
local function backupPreloadedPT()
  commonPreconditions:BackupFile(preloadedPT)
end

local function restorePreloadedPT()
  commonPreconditions:RestoreFile(preloadedPT)
end

local function updatePreloadedPT()
  local preloadedFile = commonPreconditions:GetPathToSDL() .. preloadedPT
  local pt = utils.jsonFileToTable(preloadedFile)
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  pt.policy_table.app_policies["0000001"] = json.null
  utils.tableToJsonFile(pt, preloadedFile)
end

local function registerApp(pParams, pResultCode)
  common.getMobileSession():StartService(7)
  :Do(function()
      local CorIdRegister = common.getMobileSession():SendRPC("RegisterAppInterface", pParams)
      EXPECT_HMICALL("BasicCommunication.GetSystemInfo")
      :Times(0)
      common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
      {
        application = {
          appName = pParams.appName,
          ngnMediaScreenAppName = pParams.ngnMediaScreenAppName,
          policyAppID = pParams.policyAppID,
          hmiDisplayLanguageDesired = pParams.hmiDisplayLanguageDesired,
          isMediaApplication = pParams.isMediaApplication,
          appType = pParams.appType,
        }
      })
      common.getMobileSession():ExpectResponse(CorIdRegister, { success = true, resultCode = pResultCode })
      :Do(function()
          common.getMobileSession():ExpectNotification("OnHMIStatus",
          {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
        end)
      common.getMobileSession():ExpectNotification("OnPermissionsChange")
      :Times(0)
    end)
  end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Back-up PreloadedPT", backupPreloadedPT)
runner.Step("Preloaded update", updatePreloadedPT)
runner.Step("Start SDL, init HMI, connect Mobile", common.start)

runner.Title("Test")
runner.Step("Application registered with appID has null permissions in Policy Table",
    registerApp, { paramsApp1, "SUCCESS" })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
runner.Step("Restore PreloadedPT", restorePreloadedPT)
