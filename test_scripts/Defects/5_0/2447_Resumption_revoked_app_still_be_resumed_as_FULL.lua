----------------------------------------------------------------------------------------------------
-- GitHub issue: https://github.com/smartdevicelink/sdl_core/issues/2447
----------------------------------------------------------------------------------------------------
-- Reproduction Steps:
-- 1) Register app with name = App1 and Id = 999 with uncheck Policy File Update
-- 2) Enter FULL
-- 3) Force stop application
-- 4) Start SPT then register another app and send LPT update. Then app in step 1 becomes revoked
-- 5) Register app with name = App1 and Id = 999

-- Expected Behavior:
-- SDL can't resume App1 as FULL
----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local json = require('modules/json')
local utils = require("user_modules/utils")
local test = require("user_modules/dummy_connecttest")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function PTUFuncToClearApp1Policy(tbl)
  tbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID] = json.null
end

local function cleanMobileSessions()
  for i = 1, #test.mobileSession do
    test.mobileSession[i] = nil
  end
end

local function unexpectedDisconnect()
  common.mobile.disconnect()
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered",
    { unexpectedDisconnect = true })
  common.run.wait(1000)
end

local function reconnectMobileConnection()
    common.getMobileConnection():Connect()
end

local function checkAppIsNotResumed(pAppId)
  common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp")
  :Times(0)
  common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus")
  :Times(0)
  utils.wait(10000)
end

local function registerApp(pAppId, pParamsId, pTimePolicyUpdate)
  if not pAppId then pAppId = 1 end
  common.getMobileSession(pAppId):StartService(7)
  :Do(function()
      local corId = common.getMobileSession(pAppId):SendRPC("RegisterAppInterface", common.getConfigAppParams(pParamsId))
      common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = common.getConfigAppParams(pParamsId).appName } })
      :Do(function(_, d1)
          common.setHMIAppId(d1.params.application.appID, pAppId)
          common.getHMIConnection():ExpectRequest("BasicCommunication.PolicyUpdate")
          :Do(function(_, d2)
              common.getHMIConnection():SendResponse(d2.id, d2.method, "SUCCESS", { })
            end)
          :Times(pTimePolicyUpdate)
        end)
      common.getMobileSession(pAppId):ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          common.getMobileSession(pAppId):ExpectNotification("OnPermissionsChange")
          :Times(AnyNumber())
        end)
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("Register App1", common.registerApp, { 1 })
-- update is performed because of SDL issue
runner.Step("PTU, revoke App1", common.policyTableUpdate)
runner.Step("Activate App1", common.activateApp, { 1 })
runner.Step("Force stop App1", unexpectedDisconnect)
runner.Step("CleanMobileSessions", cleanMobileSessions)
runner.Step("Reopen mobile connection", reconnectMobileConnection)

-- fuction registerApp is redefined because of ATF issue
runner.Step("Register App2", registerApp, { 1, 2, 1 })
runner.Step("PTU, revoke App1", common.policyTableUpdate, { PTUFuncToClearApp1Policy })
runner.Step("Register App1", registerApp, { 2, 1, 0 })
runner.Step("Check App1 is not resumed in FULL", checkAppIsNotResumed, { 2 })
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
