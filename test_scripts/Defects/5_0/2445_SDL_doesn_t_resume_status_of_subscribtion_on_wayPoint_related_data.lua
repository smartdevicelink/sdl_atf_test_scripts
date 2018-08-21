---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2445
--
-- Description:
-- SDL doesn't resume status of subscribtion on wayPoint-related data
-- Precondition:
-- 1) Into sdl_preloaded_pt.json add additional information about SubscribeWayPoints and UnSubscribeWayPoints.
-- 2) SDL and HMI are started.
-- 3) App registered and activated.
-- Steps to reproduce:
-- 1) Do SubscribeWayPoints for this app.
-- 2) Do Unexpected disconnect via CloseMobileSession() and receive UnSubscribeWayPoints in this way.
-- 3) Register app with the same ID once more.
-- Expected:
-- 1) Register an application successfully and resume status of subscribtion on wayPoint-related data, also 
--    resume HMIlevel being before unexpected disconnect (it means "FULL" level)
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local test = require("user_modules/dummy_connecttest")
local utils = require("user_modules/utils")

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local Functions ]]
local function cleanSessions()
    for i = 1, common.getAppsCount() do
      test.mobileSession[i] = nil
    end
    utils.wait()
end

local function pTUpdateFunc(tbl)
    local OWgroup = {
        rpcs = {
            GetWayPoints = {
                hmi_levels = { "BACKGROUND", "FULL", "LIMITED" }
            },
            SubscribeWayPoints = {
                hmi_levels = { "BACKGROUND", "FULL", "LIMITED" }
            },
            UnsubscribeWayPoints = {
                hmi_levels = { "BACKGROUND", "FULL", "LIMITED" }
            },
            OnWayPointChange =  {
                hmi_levels = { "BACKGROUND", "FULL", "LIMITED" }
            }
        }
    }
    tbl.policy_table.functional_groupings["NewTestCaseGroup"] = OWgroup
    tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID].groups = { "Base-4", "NewTestCaseGroup" }
end

local function subscribeWayPoints()
    local cid = common.getMobileSession():SendRPC("SubscribeWayPoints", {})
    common.getHMIConnection():ExpectRequest("Navigation.SubscribeWayPoints")
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",{})
    end)
    common.getMobileSession():ExpectResponse(cid, { success = true , resultCode = "SUCCESS" })
    common.getMobileSession():ExpectNotification("OnHashChange")
end

local function subscribeWayPointsAgain()
    local cid = common.getMobileSession():SendRPC("SubscribeWayPoints", {})
    common.getMobileSession():ExpectResponse(cid, { success = false , resultCode = "IGNORED" })
end

function closeMobileSession()
    local cid = common.getMobileSession():SendRPC("UnregisterAppInterface", {})
    common.getHMIConnection():ExpectRequest("Navigation.UnsubscribeWayPoints")
    :Do(function(_, data)
        common.getMobileSession():ExpectResponse(cid, { success = true , resultCode = "SUCCESS" })
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp, { 1 })
runner.Step("RAI, PTU", common.policyTableUpdate, { pTUpdateFunc })
runner.Step("Activate App", common.activateApp, { 1 })
runner.Step("SubscribeWayPoints", subscribeWayPoints)
runner.Step("Close mobile session", closeMobileSession)
runner.Step("Clean sessions", cleanSessions)

-- [[ Test ]]
runner.Title("Test")
runner.Step("Register App", common.registerAppWOPTU, { 1 })
runner.Step("Activate App", common.activateApp, { 1 })
runner.Step("SubscribeWayPoints once again after reregister", subscribeWayPointsAgain)

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)