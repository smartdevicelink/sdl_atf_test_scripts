---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2461
--
-- Precondition:
-- SDL Core and HMI are started.
-- App is registered and activated
-- Description:
-- Steps to reproduce:
-- 1) App received SubscribeWayPoints response(SUCCESS)
-- 2) App expected disconnect via UnregisterAppInterface
-- 3) App re-register.
-- 4) Re - subscribe waypoints
-- Expected:
-- 1) HMI receives SubscribeWayPoints request after app re-registered
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
require('user_modules/all_common_modules')
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[Local Functions]]
local function pTUpdateFunc(tbl)
  local Vgroup = {
    rpcs = {
      SubscribeWayPoints = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED", "NONE"}
      },
      UnsubscribeWayPoints = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED", "NONE"}
      }
    }
  }
  tbl.policy_table.functional_groupings["NewTestCaseGroup"] = Vgroup
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].groups = {"Base-4", "NewTestCaseGroup"}
end

local function expectedDisconnect()
  local cid = common.getMobileSession():SendRPC("UnregisterAppInterface", {})
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered",
  { appID = common.getHMIAppId(), unexpectedDisconnect = false })
  common.getMobileSession():ExpectResponse(cid, {success = true, resultCode = "SUCCESS"})
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  common.getHMIConnection():ExpectRequest("Navigation.UnsubscribeWayPoints")
end

local function addWayPointsSubsription()
  local cid = common.getMobileSession():SendRPC("SubscribeWayPoints", {})
  common.getHMIConnection():ExpectRequest("Navigation.SubscribeWayPoints")
  :Do(function(_,data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",{})
  end)
  common.getMobileSession():ExpectResponse(cid, {success = true, resultCode = "SUCCESS"})
  common.getMobileSession():ExpectNotification("OnHashChange" )
  :Do(function(_, data)
    common.hashId = data.payload.hashID
  end)
end

local function reRegisterApplication()
  local default_app_params = config.application1.registerAppInterfaceParams
  local correlation_id = common.getMobileSession():SendRPC("RegisterAppInterface", default_app_params)
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
    { application = { appName = default_app_params.appName}})
  common.getMobileSession():ExpectResponse(correlation_id, {success = true, resultCode = "SUCCESS"})
  :Do(function()
    common.getMobileSession():ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end)
  common.getMobileSession():ExpectNotification("OnPermissionsChange")
end

--[[Scenario]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("RAI, PTU", common.policyTableUpdate, { pTUpdateFunc })
runner.Step("Register App 2", common.registerApp, { 2 })

runner.Step("Activate App", common.activateApp)
runner.Step("Subscribe waypoints", addWayPointsSubsription)

--[[Test]]
runner.Title("Test")
runner.Step("Unregister App 2", common.app.unRegister, { 2 })
runner.Step("Do expected disconnect", expectedDisconnect)
runner.Step("Re-register application", reRegisterApplication)
runner.Step("Re-SubscribeWayPoints", addWayPointsSubsription)

--[[Postconditions]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
