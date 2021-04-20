---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  Check that SDL chooses first moduleId from capabilities for allocation of RC module to mobile application
--  in case allocation request contains moduleType and does not contain moduleId
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) HMI sent RC capabilities with multiple modules of one type to SDL (moduleType: CLIMATE, moduleId: [C0C, C0A, C1A])
-- 3) Mobile is connected to SDL
-- 4) App1 and App2 (appHMIType: ["REMOTE_CONTROL"]) are registered from Mobile
-- 5) App1 sent userLocation which is within the serviceArea of module (moduleType: CLIMATE, moduleId: C0C)
--      through SetGlobalProperties RPC
--    App2 sent userLocation which is out of the serviceArea of module (moduleType: CLIMATE, moduleId: C0C)
--      through SetGlobalProperties RPC
-- 6) HMI level of App1 is BACKGROUND;
--    HMI level of App2 is FULL
-- 7) RC module (moduleType: CLIMATE, moduleId: C0C) is free
--
-- Steps:
-- 1) Send SetInteriorVehicleData RPC (moduleType: CLIMATE) without moduleId from App2 to allocate RC module
--   Check:
--    SDL responds on SetInteriorVehicleData RPC with resultCode: REJECTED and with moduleId: C0C
--    SDL does not allocate module (moduleType: CLIMATE, moduleId: C0C) to App2
--      and does not send OnRCStatus notifications
-- 2) Activate App1 and send SetInteriorVehicleData RPC (moduleType: CLIMATE) without moduleId from it
--      to allocate RC module
--   Check:
--    SDL responds on SetInteriorVehicleData RPC with resultCode: SUCCESS and with moduleId: C0C
--    SDL allocates module (moduleType: CLIMATE, moduleId: C0C) to App1 and sends appropriate OnRCStatus notifications
---------------------------------------------------------------------------------------------------
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local testModuleCapabilities = {
  CLIMATE =  {
    {
      moduleName = 'Front Passenger Climate', -- this module should be chosen if moduleId missed in request
      moduleInfo = {
        moduleId = 'C0C',
        allowMultipleAccess = false,
        location = { col = 2, colspan = 1, level = 0, levelspan = 1, row = 0, rowspan = 1 },
        serviceArea = { col = 2, colspan = 1, level = 0, levelspan = 1, row = 0, rowspan = 1 },
      },
      acEnableAvailable = true,
      acMaxEnableAvailable = true
    },
    {
      moduleName = 'Driver Climate',
      moduleInfo = {
        moduleId = 'C0A',
        allowMultipleAccess = false,
        location = { col = 2, colspan = 1, level = 0, levelspan = 1, row = 0, rowspan = 1 },
        serviceArea = { col = 2, colspan = 1, level = 0, levelspan = 1, row = 0, rowspan = 1 },
      },
      acEnableAvailable = true,
      acMaxEnableAvailable = true
    },
    {
      moduleName = 'Back Seat Climate',
      moduleInfo = {
        moduleId = 'C1A',
        allowMultipleAccess = false,
        location = { col = 2, colspan = 1, level = 0, levelspan = 1, row = 0, rowspan = 1 },
        serviceArea = { col = 2, colspan = 1, level = 0, levelspan = 1, row = 0, rowspan = 1 },
      },
      acEnableAvailable = true,
      acMaxEnableAvailable = true
    },
  }
}


local appLocation = {
  [1] = common.grid.FRONT_PASSENGER,
  [2] = common.grid.BACK_CENTER_PASSENGER
}

local rcAppIds = { 1, 2 }

local rcCapabilities = common.initHmiRcCapabilities(testModuleCapabilities, true)

--[[ Local Functions ]]
local function rejectedAllocationOfModuleNoModuleId(pAppId, pModuleType, pModuleId, pModuleParams, pRCAppIds)
  local moduleData = common.buildSettableModuleData(pModuleType, nil, pModuleParams)
  for _, appId in pairs(pRCAppIds) do
    common.getMobileSession(appId):ExpectNotification("OnRCStatus"):Times(0)
  end
  common.getHMIConnection():ExpectNotification("RC.OnRCStatus"):Times(0)
  common.setRpcRejectNoModuleId(pModuleType, pModuleId, pAppId, moduleData, "REJECTED")
end

local function allocateModuleNoModuleId(pAppId, pModuleType, pModuleId, pModuleParams, pRCAppIds)
  local hmiExpDataTable  = { }
  local moduleData = common.buildSettableModuleData(pModuleType, pModuleId, pModuleParams)
  common.setModuleAllocation(pModuleType, pModuleId, pAppId)
  for _, appId in pairs(pRCAppIds) do
    local rcStatusForApp = common.getModulesAllocationByApp(appId)
    hmiExpDataTable[common.getHMIAppId(appId)] = common.cloneTable(rcStatusForApp)
    rcStatusForApp.allowed = true
    common.expectOnRCStatusOnMobile(appId, rcStatusForApp)
  end
  common.expectOnRCStatusOnHMI(hmiExpDataTable)
  common.setRpcSuccessNoModuleId(pModuleType, pModuleId, pAppId, moduleData)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Prepare preloaded policy table", common.preparePreloadedPT, { rcAppIds })
runner.Step("Prepare RC modules capabilities and initial modules data", common.initHmiDataState, { rcCapabilities })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { rcCapabilities })
runner.Step("Set RA mode: AUTO_ALLOW", common.defineRAMode, { true, "AUTO_ALLOW" })
runner.Step("Register App1", common.registerAppWOPTU, { 1 })
runner.Step("Register App2", common.registerAppWOPTU, { 2 })
runner.Step("Activate App1", common.activateApp, { 1 })
runner.Step("Send user location of App1 (Front passenger)", common.setUserLocation, { 1, appLocation[1] })
runner.Step("Activate App2", common.activateApp, { 2 })
runner.Step("Send user location of App2 (Back seat)", common.setUserLocation, { 2, appLocation[2] })

runner.Title("Test")
runner.Step("Reject allocation of module CLIMATE without moduleId from App2", rejectedAllocationOfModuleNoModuleId,
    { 2, "CLIMATE", "C0C", { acEnable = false }, rcAppIds })
runner.Step("Activate App1", common.activateApp, { 1 })
runner.Step("Allocate module CLIMATE without moduleId from App1", allocateModuleNoModuleId,
    { 1, "CLIMATE", "C0C", { acEnable = false }, rcAppIds })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
