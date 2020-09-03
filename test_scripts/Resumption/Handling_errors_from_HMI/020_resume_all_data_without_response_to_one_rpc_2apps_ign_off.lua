---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0190-resumption-data-error-handling.md
--
-- Description:
-- Check data resumption is failed for 1st app and succeeded for 2nd app in case
-- if HMI does not respond to at least one request from SDL related to the 1st app during default timeout
-- (Ignition Off/On scenario)
--
-- In case:
-- 1. AddCommand_1, AddSubMenu_1, CreateInteractionChoiceSet_1, SetGlobalProperties_1, SubscribeButton_1,
--  SubscribeVehicleData_1, SubscribeWayPoints_1, CreateWindow_1, GetInteriorVehicleData_1 are sent by app1
-- 2. AddCommand_2, AddSubMenu_2, CreateInteractionChoiceSet_2, SetGlobalProperties_2, SubscribeButton_2,
--  SubscribeVehicleData_2, SubscribeWayPoints_2, CreateWindow_2, GetInteriorVehicleData_2 are sent by app2
-- 3. IGN_OFF and IGN_ON are performed
-- 4. App1 and app2 re-register with actual HashId
-- SDL does:
--  - start resumption process for both apps
--  - send set of <Rpc_n> requests to HMI
-- 5. HMI does not respond to one request (related to app1) and responds <successful> for others
-- SDL does:
--  - process responses from HMI
--  - remove already restored data for app1 when default timeout expires:
--    - send set of revert <Rpc_n> requests related to app1 to HMI (except the one related to timed out response)
--    - respond RegisterAppInterfaceResponse(success=true,result_code=RESUME_FAILED) to mobile application app1
--  - restore all data for app2
--  - respond RegisterAppInterfaceResponse(success=true,result_code=SUCCESS) to mobile application app2
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
  subscribeVehicleData = { "VehicleInfo" },
  getInteriorVehicleData = { "RC" },
  createWindow = { "UI" }
}

local rpcsForApp2 = {
  addCommand = { "UI", "VR" },
  addSubMenu = { "UI" },
  createIntrerationChoiceSet = { "VR" },
  setGlobalProperties = { "UI", "TTS" },
  createWindow = { "UI" }
}

local VehicleDataForApp2 = {
  requestParams = { speed = true },
  responseParams = { speed = { resultCode = "SUCCESS", dataType = "VEHICLEDATA_SPEED"} }
}

--[[ Local Functions ]]
function common.errorResponse()
  -- HMI does not respond
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
for k, value in common.pairs(rpcs) do
  for _, interface in common.pairs(value) do
    runner.Title("Rpc " .. k .. " missing response to interface " .. interface)
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
    runner.Step("Add for app2 getInteriorVehicleData", common.getInteriorVehicleData, { 2, false, "CLIMATE" })
    runner.Step("WaitUntilResumptionDataIsStored", common.waitUntilResumptionDataIsStored)
    runner.Step("IGNITION OFF", common.ignitionOff)
    runner.Step("IGNITION ON", common.start)
    runner.Step("openRPCserviceForApp1", common.openRPCservice, { 1 })
    runner.Step("openRPCserviceForApp2", common.openRPCservice, { 2 })
    runner.Step("Reregister Apps resumption error to " .. interface .. " " .. k, common.reRegisterAppsWithError,
      { common.checkResumptionData2Apps, k, interface, 15000 })
    runner.Step("Unregister app1", common.unregisterAppInterface, { 1 })
    runner.Step("Unregister app2", common.unregisterAppInterface, { 2 })
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
