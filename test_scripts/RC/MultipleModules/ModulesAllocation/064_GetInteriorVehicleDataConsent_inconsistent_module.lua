---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  Check that SDL rejects asking driver of consent of RC module
--  if GetInteriorVehicleDataConsent RPC request contains inconsistent values in moduleType and moduleIds array
--  (all of moduleIds belong to another moduleType)
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) HMI sent RC capabilities with modules of each type to SDL
-- 3) RC access mode set from HMI: ASK_DRIVER
-- 4) Mobile is connected to SDL
-- 5) App1 (appHMIType: ["REMOTE_CONTROL"]) is registered from Mobile
-- 6) HMI level of App1 is FULL;
--
-- Steps:
-- 1) Send GetInteriorVehicleDataConsent RPC with inconsistent values in moduleType and moduleIds array
--     for each RC module type sequentially (moduleType: <moduleType>, moduleIds: [<moduleId>]) from App1
--   Check:
--    SDL responds on GetInteriorVehicleDataConsent RPC with resultCode:"UNSUPPORTED_RESOURCE", success:false
--    SDL does not send OnRCStatus notifications to HMI and Apps
---------------------------------------------------------------------------------------------------
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local testServiceArea = common.grid.BACK_SEATS

local rcAppIds = { 1 }

--[[ Local Functions ]]
local function getModules(pModuleType, pModules)
  if pModuleType ~= "BUTTONS" then
    if not pModules[1] then -- HMI_SETTINGS and LIGHT
      pModules =  { pModules }
    end
    return pModules
  end
  return nil
end

local function buildTestModulesStruct(pRcCapabilities)
  local moduleConfuseMap = {
    CLIMATE = "RADIO",
    RADIO = "AUDIO",
    AUDIO = "SEAT",
    SEAT = "CLIMATE",
    LIGHT = "HMI_SETTINGS",
    HMI_SETTINGS = "LIGHT"
  }
  local modulesStuct = {}
  for moduleType, modules in pairs(pRcCapabilities) do
    modules = getModules(moduleType, modules)
    if modules then
      modulesStuct[moduleType] = {}
      for _, rcModuleCapabilities in ipairs(modules) do
        modulesStuct[moduleType][rcModuleCapabilities.moduleInfo.moduleId] = true
      end
    end
  end
  local confusedModulesStruct = {}
  for moduleType, consentArray in pairs(modulesStuct) do
    confusedModulesStruct[moduleConfuseMap[moduleType]] = consentArray
  end
  return confusedModulesStruct
end

local function rejectConsent(pAppId, pModuleType, pConsentArray)
  local moduleIdArray = {}
  for k in pairs(pConsentArray) do
    table.insert(moduleIdArray, k)
  end
  common.rpcReject(pModuleType, nil, pAppId, "GetInteriorVehicleDataConsent", moduleIdArray, "UNSUPPORTED_RESOURCE")
end

local rcCapabilities = common.initHmiRcCapabilitiesMultiConsent(testServiceArea)
local testModules = buildTestModulesStruct(rcCapabilities)

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Prepare preloaded policy table", common.preparePreloadedPT, { rcAppIds })
runner.Step("Prepare RC modules capabilities and initial modules data", common.initHmiDataState, { rcCapabilities })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { rcCapabilities })
runner.Step("Register App1", common.registerAppWOPTU, { 1 })
runner.Step("Activate App1", common.activateApp, { 1 })

runner.Title("Test")
for moduleType, consentArray in pairs(testModules) do
  runner.Step("Ask driver to consent reallocation of modules of " .. moduleType
      .. " passing module ids of another module to App1", rejectConsent, { 1, moduleType, consentArray })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
