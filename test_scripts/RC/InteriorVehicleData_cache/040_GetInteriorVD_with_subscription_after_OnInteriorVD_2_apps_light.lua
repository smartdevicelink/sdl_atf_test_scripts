---------------------------------------------------------------------------------------------------
-- Requirement summary: InteriorVehicleData cache for different LIGHT ids
--
-- Description:
-- In case
-- 1. Mobile app1 is subscribed to module LIGHT
-- 2. HMI sends OnInteriorVD with params changing for module LIGHT for one id
-- 3. Mobile app2 sends GetInteriorVD(module_1, without subscribe parameter) request
-- SDL must
-- 1. Not send GetInteriorVD request to HMI
-- 2. send GetinteriorVD response to mobile app2 with actual data
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/InteriorVehicleData_cache/common_interiorVDcache')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

local mod = "LIGHT"

local params = {
  [1] = {
    {
      id = "READING_LIGHTS",
      status = "ON",
      density = 0.5,
      color = { red = 150, green = 200, blue = 250 }
    },
    {
      id = "AMBIENT_LIGHTS",
      status = "ON",
      density = 0.7,
      color = { red = 100, green = 100, blue = 100 }
    }
  },
  [2] = {
    {
      id = "AMBIENT_LIGHTS",
      status = "ON",
      density = 0.3,
      color = { red = 50, green = 150, blue = 120 }
    }
  },
  [3] = {
    {
      id = "READING_LIGHTS",
      status = "ON",
      density = 0.5,
      color = { red = 150, green = 200, blue = 250 }
    },
    {
      id = "AMBIENT_LIGHTS",
      status = "ON",
      density = 0.3,
      color = { red = 50, green = 150, blue = 120 }
    }
  }
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Set HMI data state for LIGHT module", common.setActualInteriorVD,
    {"LIGHT", { lightControlData = { lightState = params[1] } } })
runner.Step("Register app1", common.registerAppWOPTU, { 1 })
runner.Step("Register app2", common.registerAppWOPTU, { 2 })
runner.Step("Activate app1", common.activateApp, { 1 })
runner.Step("Activate app2", common.activateApp, { 2 })

runner.Title("Test")
runner.Step("App1 GetInteriorVehicleData with subscribe=true " .. mod, common.GetInteriorVehicleData,
  { mod, true, true, 1 })
runner.Step("App1 OnInteriorVehicleData for " .. mod, common.OnInteriorVD,
  { mod, true, 1 , { moduleType = mod, lightControlData = { lightState = params[2] } } })
runner.Step("Set HMI data state for " .. mod .. " module", common.setActualInteriorVD,
    {"LIGHT", { lightControlData = { lightState = params[3] } } })
runner.Step("App2 GetInteriorVehicleData without subscribe " .. mod, common.GetInteriorVehicleData,
  { mod, nil, false, 2 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
