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
local function ptu_update_func(tbl)
  local newTestGroup = common.cloneTable(tbl.policy_table.functional_groupings["Emergency-1"])
  for vehicleDataName in pairs (newTestGroup.rpcs) do
    newTestGroup.rpcs[vehicleDataName].parameters = common.EMPTY_ARRAY
  end
  tbl.policy_table.functional_groupings.newTestGroup = newTestGroup
  tbl.policy_table.app_policies[common.getMobileAppId(2)].groups = { "Base-4", "newTestGroup" }
end

local function checkNotification2apps(pData, self)
  local mobileSession1 = common.getMobileSession(self, 1)
  local mobileSession2 = common.getMobileSession(self, 2)
  local hmiNotParams = { [pData] = common.allVehicleData[pData].value }
  local mobNotParams = common.cloneTable(hmiNotParams)
  if mobNotParams.emergencyEvent then
    mobNotParams.emergencyEvent.maximumChangeVelocity = 0
  end
  self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", hmiNotParams)
  mobileSession1:ExpectNotification("OnVehicleData", mobNotParams)
  mobileSession2:ExpectNotification("OnVehicleData"):Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI App1 with PTU", common.registerAppWithPTU)
runner.Step("Activate App1", common.activateApp)
runner.Step("RAI App2 with PTU", common.registerAppWithPTU, { 2, ptu_update_func })
runner.Step("Activate App2", common.activateApp, { 2 })

runner.Title("Test")
for vehicleDataName in pairs(common.allVehicleData) do
  runner.Step("RPC " .. rpc .. " " .. vehicleDataName, common.processRPCSubscriptionSuccess, { rpc, vehicleDataName })
  runner.Step("RPC OnVehicleData " .. vehicleDataName, checkNotification2apps, { vehicleDataName })
end
