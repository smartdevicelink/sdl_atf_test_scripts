---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/3372
--
-- Precondition:
-- SDL Core and HMI are started
-- Two apps registered and activated
-- Description:
-- Steps to reproduce:
-- 1) App1 received SubscribeWayPoints response(SUCCESS)
-- 2) App2 disconnects
-- 3) App1 disconnects
-- Expected:
-- 1) HMI does not receive UnsubscribeWayPoints request after App2 un-registeres
-- 2) HMI does receive UnsubscribeWayPoints request after App1 un-registers
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

local function unregisterApp(pAppId, unSubWayPoints)
  EXPECT_HMICALL("Navigation.UnsubscribeWayPoints"):Times(unSubWayPoints)
  common.app.unRegister(pAppId)
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
runner.Step("Unregister App 2", unregisterApp, { 2, 0 })
runner.Step("Unregister App 1", unregisterApp, { 1, 1 })

--[[Postconditions]]
runner.Title("Postconditions")
