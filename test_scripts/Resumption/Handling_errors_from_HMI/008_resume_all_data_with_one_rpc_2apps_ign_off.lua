---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0190-resumption-data-error-handling.md
--
-- Requirement summary:TBD
--
-- Description:
-- In case:
-- 1. AddCommand_1, AddSubMenu_1, CreateInteractionChoiceSet_1, SetGlobalProperties_1, SubscribeButton_1, SubscribeVehicleData_1, SubscribeWayPoints_1 are added by app1
-- 2. AddCommand_2, AddSubMenu_2, CreateInteractionChoiceSet_2, SetGlobalProperties_2, SubscribeButton_2, SubscribeVehicleData_2, SubscribeWayPoints_2 are added by app2
-- 3. IGN_OFF and IGN_ON are performed
-- 4. App1 and app2 reregister with actual HashId
-- 5. Rpc_n related to app1 is sent from SDL to HMI during resumption
-- 6. HMI responds with error resultCode to Rpc_n request
-- 7. HMI responds with success to remaining requests
-- SDL does:
-- 1. process unsuccess response from HMI
-- 2. remove already restored data from app1
-- 3. respond RegisterAppInterfaceResponse(success=true,result_code=RESUME_FAILED) to mobile application app1
-- 4. restore all data for app2 and respond RegisterAppInterfaceResponse(success=true,result_code=SUCCESS)to mobile application app2
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Resumption/Handling_errors_from_HMI/commonResumptionErrorHandling')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local Variables ]]
local rpcs = {
  addCommand = { "UI", "VR" },
  addSubMenu = { "UI" },
  createIntrerationChoiceSet = { "VR" },
  setGlobalProperties = { "UI", "TTS" },
  subscribeVehicleData = { "VehicleInfo" }
}

local rpcsForApp2 = {
  addCommand = { "UI", "VR" },
  addSubMenu = { "UI" },
  createIntrerationChoiceSet = { "VR" },
  setGlobalProperties = { "UI", "TTS" }
}

local VehicleDataForApp2 = {
  requestParams = { speed = true },
  responseParams = { speed = { resultCode = "SUCCESS", dataType = "VEHICLEDATA_SPEED"} }
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
for k, value in pairs(rpcs) do
  for _, interface in pairs(value) do
    runner.Title("Rpc " .. k .. " error resultCode to interface " .. interface)
    runner.Step("Register app1", common.registerAppWOPTU)
    runner.Step("Register app2", common.registerAppWOPTU, { 2 })
    runner.Step("Activate app1", common.activateApp)
    runner.Step("Activate app2", common.activateApp, { 2 })
    for rpc in pairs(rpcs) do
      runner.Step("Add for app1 " .. rpc, common[rpc])
    end
    for rpc in pairs(rpcsForApp2) do
      runner.Step("Add for app2 " .. rpc, common[rpc], { 2 })
    end
    runner.Step("Add for app2 subscribeVehicleData", common.subscribeVehicleData, { 2, VehicleDataForApp2 })
    runner.Step("WaitUntilResumptionDataIsStored", common.waitUntilResumptionDataIsStored)
    runner.Step("IGNITION OFF", common.ignitionOff)
    runner.Step("IGNITION ON", common.start)
    runner.Step("openRPCserviceForApp1", common.openRPCservice, { 1 })
    runner.Step("openRPCserviceForApp2", common.openRPCservice, { 2 })
    runner.Step("Reregister Apps resumption error to " .. interface .. " " .. k,common.reRegisterApps,
      {common.checkResumptionData2Apps, k, interface})
    runner.Step("Unregister app1", common.unregisterAppInterface, { 1 })
    runner.Step("Unregister app2", common.unregisterAppInterface, { 2 })
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
