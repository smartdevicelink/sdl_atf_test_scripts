---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  HMI sent to SDL capabilities where only one module is available per module type.
--  Mobile App sends "SetInteriorVehicleData" requests with omitted "moduleId" parameters to every available module,
--  SDL should transfer these requests adding the default "moduleId" values to the HMI and use these parameters
--  in further communications.
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) HMI sent capabilities with only one module per module type
-- 3) Mobile is connected to the SDL
-- 4) App is registered and activated
--
-- Steps:
-- 1) App sends "SetInteriorVehicleData"(moduleType = "RADIO", radioControlData) request to the SDL
--   Check:
--    SDL resends "RC.SetInteriorVehicleData" (moduleType = "RADIO", moduleId = "00bd6d93", radioControlData)
--     request to the HMI adding the default "moduleId" value
--    HMI sends "RC.SetInteriorVehicleData"(moduleType = "RADIO", moduleId = "00bd6d93", radioControlData) response
--     to the SDL
--    SDL resends "SetInteriorVehicleData"
--     (moduleType = "RADIO", moduleId = "00bd6d93", radioControlData, resultCode = "SUCCESS") response to the App
-- 2-6) Repeat step #1 but selecting another one from the remaining available modules
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local rcCapabilities = {}
for _, v in pairs(common.getRcModuleTypes()) do rcCapabilities[v] = common.DEFAULT end        -- enable all possible RC
                                                                                              -- capabilities in HMI
local subscribeData = {
  RADIO = common.getRcCapabilities().RADIO[1].moduleInfo.moduleId,
  CLIMATE = common.getRcCapabilities().CLIMATE[1].moduleInfo.moduleId,
  SEAT = common.getRcCapabilities().SEAT[1].moduleInfo.moduleId,
  AUDIO = common.getRcCapabilities().AUDIO[1].moduleInfo.moduleId,
  LIGHT = common.getRcCapabilities().LIGHT.moduleInfo.moduleId,
  HMI_SETTINGS = common.getRcCapabilities().HMI_SETTINGS.moduleInfo.moduleId
}
local requestModuleData = {
  RADIO = {
    moduleType = "RADIO",
    radioControlData = {
      frequencyInteger = 1,
      radioEnable = true
    }
  },
  CLIMATE = {
    moduleType = "CLIMATE",
    climateControlData = {
      fanSpeed = 50,
      desiredTemperature = {
        unit = "CELSIUS",
        value = 10.5
      },
      acEnable = true,
      autoModeEnable = true
    }
  },
  SEAT = {
    moduleType = "SEAT",
    seatControlData = {
      id = "DRIVER",
      horizontalPosition = 50,
      verticalPosition = 50,
      frontVerticalPosition = 50,
      backVerticalPosition = 50,
      backTiltAngle = 50
    }
  },
  AUDIO = {
    moduleType = "AUDIO",
    audioControlData = {
      source = "AM",
      keepContext = false,
      volume = 50
    }
  },
  LIGHT = {
    moduleType = "LIGHT",
    lightControlData = {
      lightState = {
        {
          id = "FRONT_LEFT_HIGH_BEAM",
          status = "ON",
          density = 0.2
        }
      }
    }
  },
  HMI_SETTINGS = {
    moduleType = "HMI_SETTINGS",
    hmiSettingsControlData = {
      displayMode = "AUTO",
      temperatureUnit = "FAHRENHEIT",
      distanceUnit = "MILES"
    }
  }
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { rcCapabilities })
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { common.PTUfunc })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
for moduleType, moduleId in pairs(subscribeData) do
  runner.Step("Send request for "..moduleType.." module", common.sendSuccessRpcNoModuleId,
    { moduleType, moduleId, 1, "SetInteriorVehicleData", requestModuleData[moduleType],  })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
