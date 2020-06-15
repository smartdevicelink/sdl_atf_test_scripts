---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0253-New-vehicle-data-StabilityControlsStatus.md
--
-- Description: UnsubscribeVehicleData RPC with `stabilityControlsStatus` parameter
-- which is NOT allowed by Policies and other parameters which are allowed by Policies
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) App is registered
-- 3) PTU is successfully performed
-- 4) App is activated
-- 5) App is subscribed on gps vehicle data
--
-- Steps:
-- 1) App sends UnsubscribeVehicleData (with stabilityControlsStatus = true and gps = true) request to SDL
--    SDL cuts stabilityControlsStatus off
--    SDL sends VehicleInfo.UnsubscribeVehicleData request with (gps = true) to HMI
--    HMI sends VehicleInfo.UnsubscribeVehicleData response "SUCCESS" with
--      (gps = { resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"})
--    SDL sends UnsubscribeVehicleData response with (success: true, resultCode: "SUCCESS",
--      gps = { resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"},
--      stabilityControlsStatus = { resultCode = "DISALLOWED", dataType = "VEHICLEDATA_STABILITYCONTROLSSTATUS"})
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/commonVehicleData')

--[[ Test Configuration ]]
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 6
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 2

--[[ Local Functions ]]
local function ptUpdate(pTbl)
  pTbl.policy_table.app_policies[common.getConfigAppParams().fullAppID].groups = { "Base-4", "Emergency-1" }
  local grp = pTbl.policy_table.functional_groupings["Emergency-1"]
  grp.rpcs.SubscribeVehicleData.parameters = {
    "gps"
  }
  grp.rpcs.UnsubscribeVehicleData.parameters = {
    "gps"
  }
  pTbl.policy_table.vehicle_data = nil
end

local function processRPCSubscriptionPartiallyDisallowed(pAllowedData, pDisallowedData)
  local rpcName = "UnsubscribeVehicleData"
  local mobReqParams = {
    [pAllowedData] = true,
    [pDisallowedData] = true
  }
  local hmiReqParams = {
    [pAllowedData] = true
  }
  local respData
  if pAllowedData == "clusterModeStatus" then
    respData = "clusterModes"
  else
    respData = pAllowedData
  end
  local hmiResParams = {
    [respData] = {
      resultCode = "SUCCESS",
      dataType = common.allVehicleData[pAllowedData].type
    }
  }
  local mobResParams = common.cloneTable(hmiResParams)
  mobResParams[pDisallowedData] = {
    resultCode = "DISALLOWED",
    dataType = common.allVehicleData[pDisallowedData].type
  }
  mobResParams.success = true
  mobResParams.resultCode = "SUCCESS"
  mobResParams.info = '\'' .. pDisallowedData .. '\'' ..  " disallowed by policies."
  local cid = common.getMobileSession():SendRPC(rpcName, mobReqParams)
  common.getHMIConnection():ExpectRequest("VehicleInfo." .. rpcName, hmiReqParams)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", hmiResParams)
    end)
  common.getMobileSession():ExpectResponse(cid, mobResParams)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, init HMI, connect default mobile", common.start)
common.Step("Register App", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { ptUpdate })
common.Step("Activate App", common.activateApp)
common.Step("Subscribe on StabilityControlsStatus VehicleData", common.processRPCSubscriptionSuccess,
  { "SubscribeVehicleData", { "gps" }})

common.Title("Test")
common.Step("Unsubscribe from StabilityControlsStatus is not allowed by policies",
  processRPCSubscriptionPartiallyDisallowed, { "gps", "stabilityControlsStatus" })

common.Title("Postconditions")
common.Step("Stop SDL, restore environment", common.postconditions)
