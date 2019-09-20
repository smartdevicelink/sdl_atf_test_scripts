---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0178-GetInteriorVehicleData.md
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case
-- 1. Mobile app1 is subscribed to module_1
-- 2. HMI sends OnInteriorVD with one param changing for module_1
-- 3. Mobile app1 sends GetInteriorVD(module_1, without subscribe parameter) request
-- SDL must
-- 1. not send GetInteriorVD request to HMI
-- 2. send GetinteriorVD response to mobile app1 with actual data
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/InteriorVehicleData_cache/common_interiorVDcache')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

local OnInteriorVDparams = {
  CLIMATE =  { fanSpeed = 30 },
  RADIO = { frequencyFraction = 3 },
  SEAT = { id = "FRONT_PASSENGER" },
  LIGHT = { lightState = { { id = "FRONT_RIGHT_HIGH_BEAM", status = "ON" } } },
  AUDIO = { source = "FM" },
  HMI_SETTINGS = { displayMode = "NIGHT" }
}

local function getModuleData(module_type, pParams)
  local out = { moduleType = module_type }
  if module_type == "CLIMATE" then
    out.climateControlData = pParams
  elseif module_type == "RADIO" then
    out.radioControlData = pParams
  elseif module_type == "SEAT" then
    out.seatControlData = pParams
  elseif module_type == "AUDIO" then
    out.audioControlData = pParams
  elseif module_type == "LIGHT" then
    out.lightControlData = pParams
  elseif module_type == "HMI_SETTINGS" then
    out.hmiSettingsControlData = pParams
  end
  return out
end

local function setActualInteriorVD(pInitialParams, pUpdatedParams)
  local moduleType = pInitialParams.moduleType
  if moduleType == "LIGHT" then
    local mergedParams = common.cloneTable(pInitialParams)
    mergedParams.lightControlData.lightState[2] = pUpdatedParams.lightControlData.lightState[1]
    common.setActualInteriorVD(moduleType, { lightControlData = mergedParams.lightControlData })
  end
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register app1", common.registerAppWOPTU, { 1 })
runner.Step("Activate app1", common.activateApp, { 1 })

runner.Title("Test")

for _, mod in pairs(common.modules) do
  local initialParams = common.cloneTable(common.actualInteriorDataStateOnHMI[mod])
  local updatedParams = getModuleData(mod, OnInteriorVDparams[mod])
  runner.Step("App1 GetInteriorVehicleData with subscribe=true " .. mod, common.GetInteriorVehicleData,
    { mod, true, true, 1 })
  runner.Step("App1 OnInteriorVehicleData for " .. mod, common.OnInteriorVD,
    { mod, true, 1, updatedParams })
  runner.Step("Set HMI data state for " .. mod .. " module", setActualInteriorVD, {
    initialParams, updatedParams })
  runner.Step("App1 GetInteriorVehicleData without subscribe " .. mod, common.GetInteriorVehicleData,
    { mod, nil, false, 1 })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
