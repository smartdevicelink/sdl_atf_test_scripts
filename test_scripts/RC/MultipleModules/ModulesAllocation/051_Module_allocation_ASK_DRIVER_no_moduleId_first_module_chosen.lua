---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  Check that SDL chooses first moduleId from capabilities for allocation of RC module to mobile application
--  in case allocation request contains moduleType and does not contain moduleId and perform driver consent with
--  right moduleId
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) HMI sent RC capabilities with multiple modules of one type to SDL (moduleType: CLIMATE, moduleId: [C1A, C0C, C0A])
-- 3) RC access mode set from HMI: ASK_DRIVER
-- 4) Mobile is connected to SDL
-- 5) App1 and App2 (appHMIType: ["REMOTE_CONTROL"]) are registered from Mobile
-- 6) App1 sent userLocation which is within the serviceArea of module (moduleType: CLIMATE, moduleId: C1A)
--      through SetGlobalProperties RPC
--    App2 sent userLocation which is out of the serviceArea of module (moduleType: CLIMATE, moduleId: C1A)
--      through SetGlobalProperties RPC
-- 7) HMI level of App2 is BACKGROUND;
--    HMI level of App1 is FULL
-- 8) RC module (moduleType: CLIMATE, moduleId: C1A) is allocated to App2
--
-- Steps:
-- 1) App1 send SetInteriorVehicleData RPC (moduleType: CLIMATE) without moduleId to allocate RC module
--    HMI responds on GetInteriorVehicleDataConsent request with allowed: true for module
--      (moduleType: CLIMATE, moduleId: C1A)
--   Check:
--    SDL sends GetInteriorVehicleDataConsent RPC to HMI with module (moduleType: CLIMATE, moduleId: C1A)
--    SDL allocates module (moduleType: CLIMATE, moduleId: C1A) to App1 and sends appropriate OnRCStatus notifications
--    SDL responds on SetInteriorVehicleData RPC with resultCode: SUCCESS
---------------------------------------------------------------------------------------------------
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local testModuleCapabilities = {
  CLIMATE =  {
    {
      moduleName = 'Back Seat Climate', -- this module should be chosen if moduleId missed in request
      moduleInfo = {
        moduleId = 'C1A',
        allowMultipleAccess = true,
        location = { col = 0, colspan = 1, level = 0, levelspan = 1, row = 1, rowspan = 1 },
        serviceArea = { col = 0, colspan = 3, level = 0, levelspan = 1, row = 1, rowspan = 1 },
      },
      acEnableAvailable = true,
      acMaxEnableAvailable = true
    },
    {
      moduleName = 'Front Passenger Climate',
      moduleInfo = {
        moduleId = 'C0C',
        allowMultipleAccess = true,
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
        allowMultipleAccess = true,
        location = { col = 0, colspan = 1, level = 0, levelspan = 1, row = 0, rowspan = 1 },
        serviceArea = { col = 0, colspan = 1, level = 0, levelspan = 1, row = 0, rowspan = 1 },
      },
      acEnableAvailable = true,
      acMaxEnableAvailable = true
    }
  }
}


local appLocation = {
  [1] = common.grid.BACK_RIGHT_PASSENGER,
  [2] = common.grid.BACK_CENTER_PASSENGER
}

local rcAppIds = { 1, 2 }

local rcCapabilities = common.initHmiRcCapabilities(testModuleCapabilities, true)

--[[ Local Functions ]]
local function allocateModuleWithConsentNoModuleId(pAppId, pModuleType, pModuleId, pModuleParams, pRCAppIds)
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
  common.setRpcSuccessWithConsentNoModuleId(pModuleType, pModuleId, pAppId, moduleData)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Prepare preloaded policy table", common.preparePreloadedPT, { rcAppIds })
runner.Step("Prepare RC modules capabilities and initial modules data", common.initHmiDataState, { rcCapabilities })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { rcCapabilities })
runner.Step("Set RA mode: ASK_DRIVER", common.defineRAMode, { true, "ASK_DRIVER" })
runner.Step("Register App1", common.registerAppWOPTU, { 1 })
runner.Step("Register App2", common.registerAppWOPTU, { 2 })
runner.Step("Activate App1", common.activateApp, { 1 })
runner.Step("Send user location of App1 (Back Seat)", common.setUserLocation, { 1, appLocation[1] })
runner.Step("Activate App2", common.activateApp, { 2 })
runner.Step("Send user location of App2 (Back seat)", common.setUserLocation, { 2, appLocation[2] })
runner.Step("Allocate free module CLIMATE_C1A to App2", common.allocateModuleWithoutConsent,
    { 2, "CLIMATE", "C1A", { acEnable = false }, rcAppIds })

runner.Title("Test")
runner.Step("Activate App1", common.activateApp, { 1 })
runner.Step("Reallocate default module of CLIMATE to App1 after positive driver consent",
    allocateModuleWithConsentNoModuleId, { 1, "CLIMATE", "C1A", { acEnable = true }, rcAppIds })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
