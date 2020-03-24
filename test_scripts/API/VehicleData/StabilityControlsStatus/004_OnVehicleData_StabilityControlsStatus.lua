---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0253-New-vehicle-data-StabilityControlsStatus.md
--
-- Description: Check receiving StabilityControlsStatus data via OnVehicleData notification
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) App is registered
-- 3) PTU is successfully performed
-- 4) App is activated
-- 5) App is subscribed on StabilityControlsStatus vehicle data and is not subscribed on GPS data

-- Steps:
-- 1) HMI sends VehicleInfo.OnVehicleData notification with StabilityControlsStatus data
--   (escSystem = "ON", trailerSwayControl = "OFF")
-- SDL does:
--  - send OnVehicleData notification with received from HMI data to App
-- 2) HMI sends VehicleInfo.OnVehicleData notification with GPS data
-- SDL does:
--  - not send OnVehicleData notification with received from HMI data to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
-- local common = require('test_scripts/API/VehicleData/StabilityControlsStatus/commonVDStabilityControlsStatus')
local common = require('test_scripts/API/VehicleData/commonVehicleData')

local function getVDParams()
  local out = {}
  for k in pairs(common.allVehicleData) do
    table.insert(out, k)
  end
  return out
end

local function ptUpdate(pTbl)
  pTbl.policy_table.app_policies[common.getConfigAppParams(2).fullAppID].groups = { "Base-4", "Emergency-1" }
  pTbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID].groups = { "Base-4", "Emergency-1" }

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
-- common.Step("Prepare preloaded policy table", common.preparePreloadedPT)
common.Step("Start SDL, init HMI, connect default mobile", common.start)
common.Step("Register App", common.registerApp)
common.Step("PTU", common.policyTableUpdate)
common.Step("Register App", common.registerApp, { 2 })
common.Step("PTU 2", common.policyTableUpdate, { ptUpdate })
common.Step("Activate App", common.activateApp)
common.Step("Subscribe on StabilityControlsStatus VehicleData", processRPCSubscriptionSuccess,
  {"SubscribeVehicleData", "stabilityControlsStatus", 1, false })
common.Step("Activate App", common.activateApp, { 2 })
common.Step("Subscribe on StabilityControlsStatus VehicleData", processRPCSubscriptionSuccess,
  {"SubscribeVehicleData", "stabilityControlsStatus", 2, true })

common.Title("Test")
common.Step("Expect OnVehicleData with StabilityControlsStatus data on both Apps", checkNotificationSuccess,
  { "stabilityControlsStatus", { { id = 1, isNotified = true }, { id = 2, isNotified = true } } })
common.Step("Unsubscribe App1 from StabilityControlsStatus VehicleData", processRPCSubscriptionSuccess,
  {"UnsubscribeVehicleData", "stabilityControlsStatus", 1, true })
common.Step("Expect OnVehicleData with StabilityControlsStatus data on App2 only", checkNotificationSuccess,
  { "stabilityControlsStatus", { { id = 1, isNotified = false }, { id = 2, isNotified = true } } })

common.Title("Postconditions")
common.Step("Stop SDL, restore environment", common.postconditions)
