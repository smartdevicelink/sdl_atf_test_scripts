---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2862
-- Description:
-- SDL sends UnsubscribeWayPoint request to HMI for App1 when App2 is still subscribed to the WayPoint
--  Precondition: 
-- 1) SDL and HMI are started
-- 2) App1 and App2 are registered
-- 3) App1 and App2 are subscribed to SubscribeWayPoint
--
--  Steps:
-- 1) App1 requests the UnsubscribeWayPoint
-- 2) App2 requests the UnsubscribeWayPoint
--
--  Expected:
-- 1) SDL does not transfer the request to HMI, unsubscribes internally and responds with result code SUCCESS, success: true for App1
-- 2) SDL sends the request to HMI for app2 and unsubscribes after successful HMI response
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/AppServices/commonAppServices')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local variables ]]
sub_list = {}

subscribeRPC = {
  name = "SubscribeWayPoints",
  hmi_name = "Navigation.SubscribeWayPoints",
  params = {},
  result = { success = true }
}

unsubscribeRPC = {
  name = "UnsubscribeWayPoints",
  hmi_name = "Navigation.UnsubscribeWayPoints",
  params = {},
  result = { success = true }
}

--[[ Local functions ]]
local function PTUfunc(tbl)
  pt_entry = common.getAppDataForPTU(1)
  pt_entry.groups = { "Base-4" , "WayPoints" }
  tbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID] = pt_entry
  pt_entry = common.getAppDataForPTU(2)
  pt_entry.groups = { "Base-4" , "WayPoints" }
  tbl.policy_table.app_policies[common.getConfigAppParams(2).fullAppID] = pt_entry
end

local function SubscribeWayPoints(app_id)
  if app_id == nil then app_id = 1 end
  local mobileSession = common.getMobileSession(app_id)
  local cid = mobileSession:SendRPC(subscribeRPC.name, subscribeRPC.params)

  if #sub_list == 0 then
    --Expect HMI call for the first app which sends a SubscribeWayPoints request
    EXPECT_HMICALL(subscribeRPC.hmi_name, nil):Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})    
    end)
  end 

  table.insert(sub_list, app_id)
  mobileSession:ExpectResponse(cid, subscribeRPC.result)
end

local function UnsubscribeWayPoints(app_id)
  if app_id == nil then app_id = 1 end
  local mobileSession = common.getMobileSession(app_id)
  local cid = mobileSession:SendRPC(unsubscribeRPC.name, unsubscribeRPC.params)

  if #sub_list == 1 then
    --Expect HMI call for the last app which sends a UnsubscribeWayPoints request
    EXPECT_HMICALL(unsubscribeRPC.hmi_name, nil):Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})    
    end)
  end 
  
  table.remove(sub_list)
  mobileSession:ExpectResponse(cid, unsubscribeRPC.result)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)    
runner.Step("RAI App 1", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { PTUfunc })
runner.Step("Activate App", common.activateApp, { 1 })
runner.Step("SubscribeWayPoints App 1", SubscribeWayPoints, { 1 })   
runner.Step("RAI App 2", common.registerAppWOPTU, { 2 })
runner.Step("Activate App", common.activateApp, { 2 })   
runner.Step("SubscribeWayPoints App 2", SubscribeWayPoints, { 2 })   

runner.Title("Test")       
runner.Step("UnSubscribeWayPoints App 1", UnsubscribeWayPoints, { 1 })
runner.Step("UnSubscribeWayPoints App 2", UnsubscribeWayPoints, { 2 })   

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
