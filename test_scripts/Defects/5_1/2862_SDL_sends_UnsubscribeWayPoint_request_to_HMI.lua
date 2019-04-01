---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2862
--
-- Description:
-- SDL sends UnsubscribeWayPoint request to HMI for App1 when App2 is still subscribed to the WayPoint
-- Preconditions"
-- 1) SDL and HMI are started
-- 2) App1 and App2 are registered
-- 3) App1 and App2 are subscribed to SubscribeWayPoint
-- Steps to reproduce:
-- 1) App1 requests the UnsubscribeWayPoint
-- 2) App2 requests the UnsubscribeWayPoint
-- Expected:
-- 1) SDL does not transfer the request to HMI, unsubscribes internally and responds with result code SUCCESS, success: true for App1
-- 2) SDL sends the request to HMI for app2 and unsubscribes after successful HMI response

---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local functions ]]
local function PTUfunc(tbl)
  local appID1 = config.application1.registerAppInterfaceParams.fullAppID
  local appID2 = config.application2.registerAppInterfaceParams.appID
  local default = tbl.policy_table.app_policies["default"]
  tbl.policy_table.app_policies[appID1] = default
  tbl.policy_table.app_policies[appID1].groups = {'Base-4', 'WayPoints'}
  tbl.policy_table.app_policies[appID2] = default
  tbl.policy_table.app_policies[appID2].groups = {'Base-4', 'WayPoints'}
end  

local function SubscribeApp(appID, expectHMIRequest)
  local mobileSession = common.getMobileSession(appID)
  local cid = mobileSession:SendRPC( "SubscribeWayPoints", {})

  if expectHMIRequest then
    EXPECT_HMICALL("Navigation.SubscribeWayPoints")
    :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  end

  mobileSession:ExpectResponse(cid, { success = true,
    resultCode = "SUCCESS" })
end

local function MobileSuccessWithNoHMIRequest()
  local mobileSession = common.getMobileSession(1)
  local cid = mobileSession:SendRPC( "UnsubscribeWayPoints", {})
  
  mobileSession:ExpectResponse(cid, { success = true,
    resultCode = "SUCCESS" })

    EXPECT_HMICALL("Navigation.UnsubscribeWayPoints", {}):Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App 1", common.registerApp, {1})
runner.Step("PTU", common.policyTableUpdate, {PTUfunc})
runner.Step("Register App 2", common.registerAppWOPTU, {2})
runner.Step("Activate App 1", common.activateApp, {1})
runner.Step("Subscribe App 1", SubscribeApp, {1, true})
runner.Step("Activate App 2", common.activateApp, {2, false})
runner.Step("Subscribe App 2", SubscribeApp, {2})

-- [[ Test ]]
runner.Title("Test")
runner.Step("Unsubscribe App 1", MobileSuccessWithNoHMIRequest)

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)