---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0253-New-vehicle-data-StabilityControlsStatus.md
--
-- Description: Check receiving StabilityControlsStatus data via OnVehicleData notification
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) App1 and App2 are registered
-- 3) PTU is successfully performed
-- 4) App1 and App2 are activated
-- 5) App1 and App2 are subscribed on StabilityControlsStatus vehicle data
--
-- Steps:
-- 1) HMI sends VehicleInfo.OnVehicleData notification with StabilityControlsStatus data
--    SDL sends OnVehicleData notification with received from HMI data to App1 and App2
-- 2) App1 unsubscribes from StabilityControlsStatus vehicle data.
--    HMI sends VehicleInfo.OnVehicleData notification with StabilityControlsStatus data
--    SDL sends OnVehicleData notification with received from HMI data to App2 only
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/commonVehicleData')

--[[ Local Constants ]]
local APP1 = 1
local APP2 = 2

--[[ Local Functions ]]
local function getVDParams()
  local out = {}
  for k in pairs(common.allVehicleData) do
    table.insert(out, k)
  end
  return out
end

local function ptUpdate(pTbl)
  pTbl.policy_table.app_policies[common.getConfigAppParams(APP2).fullAppID].groups = { "Base-4", "Emergency-1" }
  pTbl.policy_table.app_policies[common.getConfigAppParams(APP1).fullAppID].groups = { "Base-4", "Emergency-1" }

  local grp = pTbl.policy_table.functional_groupings["Emergency-1"]
  local vdParams = getVDParams()
  for _, v in pairs(grp.rpcs) do
    v.parameters = common.cloneTable(vdParams)
  end
  pTbl.policy_table.vehicle_data = nil
end

local function processRPCSubscriptionSuccess(pRpcName, pData, pAppId, pIsCached)
  local reqParams = {
    [pData] = true
  }
  local respData
  if pData == "clusterModeStatus" then
    respData = "clusterModes"
  else
    respData = pData
  end
  local hmiResParams = {
    [respData] = {
      resultCode = "SUCCESS",
      dataType = common.allVehicleData[pData].type
    }
  }
  local cid = common.getMobileSession(pAppId):SendRPC(pRpcName, reqParams)
  if not pIsCached then
    common.getHMIConnection():ExpectRequest("VehicleInfo." .. pRpcName, reqParams)
    :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", hmiResParams)
      end)
  end
  local mobResParams = common.cloneTable(hmiResParams)
  mobResParams.success = true
  mobResParams.resultCode = "SUCCESS"
  common.getMobileSession(pAppId):ExpectResponse(cid, mobResParams)
end

local function checkNotificationSuccess(pData, pApps)
  local hmiNotParams = { [pData] = common.allVehicleData[pData].value }
  local mobNotParams = common.cloneTable(hmiNotParams)
  for _, appInfo in pairs(pApps) do
    if appInfo.isNotified then
      common.getMobileSession(appInfo.id):ExpectNotification("OnVehicleData", mobNotParams)
    else
      common.getMobileSession(appInfo.id):ExpectNotification("OnVehicleData"):Times(0)
    end
  end
  common.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", hmiNotParams)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, init HMI, connect default mobile", common.start)
common.Step("Register App1", common.registerApp, { APP1 })
common.Step("PTU", common.policyTableUpdate)
common.Step("Register App2", common.registerApp, { APP2 })
common.Step("PTU 2", common.policyTableUpdate, { ptUpdate })
common.Step("Activate App1", common.activateApp, { APP1 })
common.Step("Subscribe on StabilityControlsStatus VehicleData", processRPCSubscriptionSuccess,
  { "SubscribeVehicleData", "stabilityControlsStatus", APP1, false })
common.Step("Activate App2", common.activateApp, { APP2 })
common.Step("Subscribe on StabilityControlsStatus VehicleData", processRPCSubscriptionSuccess,
  { "SubscribeVehicleData", "stabilityControlsStatus", APP2, true })

common.Title("Test")
common.Step("Expect OnVehicleData with StabilityControlsStatus data on both Apps", checkNotificationSuccess,
  { "stabilityControlsStatus", {{ id = APP1, isNotified = true }, { id = APP2, isNotified = true }}})
common.Step("Unsubscribe App1 from StabilityControlsStatus VehicleData", processRPCSubscriptionSuccess,
  { "UnsubscribeVehicleData", "stabilityControlsStatus", APP1, true })
common.Step("Expect OnVehicleData with StabilityControlsStatus data on App2 only", checkNotificationSuccess,
  { "stabilityControlsStatus", {{ id = APP1, isNotified = false }, { id = APP2, isNotified = true }}})

common.Title("Postconditions")
common.Step("Stop SDL, restore environment", common.postconditions)
