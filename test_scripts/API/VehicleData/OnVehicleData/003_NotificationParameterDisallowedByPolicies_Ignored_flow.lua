---------------------------------------------------------------------------------------------------
-- User story: TO ADD !!!
-- Use case: TO ADD !!!
-- Item: Use Case 1: TO ADD!!!
--
-- Requirement summary:
-- [OnVehicleData] As a mobile app is subscribed for VI parameter
-- and received notification about this parameter change from hmi
--
-- Description:
-- In case:
-- 1) If application is subscribed to get vehicle data with 'engineOilLife' parameter
-- 2) Parameter is disallowed by Policies in this notification
-- 3) Notification about changes in subscribed parameter is received from hmi
-- SDL must:
-- Ignore this notification and not send to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/commonVehicleData')

--[[ Local Variables ]]
local rpc =  "SubscribeVehicleData"
-- removed because vin parameter is not applicable for SubscribeVehicleData
common.allVehicleData.vin = nil

--[[ Local Functions ]]
local function ptUpdate(pTbl)
  common.ptUpdate(pTbl)
  local NewTestGroup = common.cloneTable(pTbl.policy_table.functional_groupings["Emergency-1"])
  for vehicleDataName in pairs(NewTestGroup.rpcs) do
    NewTestGroup.rpcs[vehicleDataName].parameters = common.EMPTY_ARRAY
  end
  pTbl.policy_table.functional_groupings.NewTestGroup = NewTestGroup
  pTbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID].groups = { "Base-4", "Emergency-1" }
  pTbl.policy_table.app_policies[common.getConfigAppParams(2).fullAppID].groups = { "Base-4", "NewTestGroup" }
end

local function checkNotification2apps(pData)
  local hmiNotParams = { [pData] = common.allVehicleData[pData].value }
  local mobNotParams = common.cloneTable(hmiNotParams)
  if mobNotParams.emergencyEvent then
    mobNotParams.emergencyEvent.maximumChangeVelocity = 0
  end
  common.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", hmiNotParams)
  common.getMobileSession(1):ExpectNotification("OnVehicleData", mobNotParams)
  common.getMobileSession(2):ExpectNotification("OnVehicleData"):Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("RAI 1", common.registerApp, { 1 })
common.Step("PTU", common.policyTableUpdate, { common.ptUpdate })
runner.Step("RAI 2", common.registerApp, { 2 })
common.Step("PTU", common.policyTableUpdate, { ptUpdate })
runner.Step("Activate App1", common.activateApp, { 1 })
runner.Step("Activate App2", common.activateApp, { 2 })

runner.Title("Test")
for vehicleDataName in pairs(common.allVehicleData) do
  runner.Step("RPC " .. rpc .. " " .. vehicleDataName, common.processRPCSubscriptionSuccess, { rpc, vehicleDataName })
  runner.Step("RPC OnVehicleData " .. vehicleDataName, checkNotification2apps, { vehicleDataName })
end
