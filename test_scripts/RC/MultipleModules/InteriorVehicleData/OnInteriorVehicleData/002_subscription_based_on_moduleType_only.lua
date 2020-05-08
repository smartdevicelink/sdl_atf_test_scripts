---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  Check regularity of subscribe process by sending "GetInteriorVehicleData" request containing only "moduleType"
--  parameter
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) HMI sent all modules capabilities to the SDL
-- 3) Mobile is connected to the SDL
-- 4) App is registered and activated
--
-- Steps:
-- 1) App sends "GetInteriorVehicleData"(moduleType = "AUDIO", subscribe = true) request to the SDL
--   Check:
--    SDL resends "RC.GetInteriorVehicleData"(moduleType = "AUDIO", moduleId = "0876b4be", subscribe = true)
--     request to the HMI, adding a default "0876b4be" value
--    HMI sends "RC.GetInteriorVehicleData"
--     (moduleType = "AUDIO", moduleId = "0876b4be", audioControlData, isSubscribed = true) response to the SDL
--    SDL resends "GetInteriorVehicleData"
--     (moduleType = "AUDIO", moduleId = "0876b4be", audioControlData, resultCode = "SUCCESS") response to the App
-- 2) After some changes were made to the "0876b4be" module, HMI sends
--     "RC.OnInteriorVehicleData"(moduleType = "AUDIO", moduleId = "0876b4be", audioControlData) notification to the SDL
--   Check:
--    SDL resend OnInteriorVehicleData
--     (moduleType = "AUDIO", moduleId = "0876b4be", audioControlData) notification to the App
-- 3) After some changes were made to the "c64f6c90" module HMI sends
--     "RC.OnInteriorVehicleData"(moduleType = "AUDIO", moduleId = "c64f6c90", audioControlData) notification to the SDL
--   Check:
--    SDL does not send any notification to the App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local customAudioCapabilities = {
  {
    moduleName = "Audio Driver Seat",
    moduleInfo = {
      moduleId = "0876b4be-f1ce-4f5c-86e9-5ca821683a1b",
      location = {
        col = 0, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1
      },
      serviceArea = {
        col = 0, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1
      },
      allowMultipleAccess = true
    },
    sourceAvailable = true,
    keepContextAvailable = true,
    volumeAvailable = true,
    equalizerAvailable = true,
    equalizerMaxChannelId = 100
  },
  {
    moduleName = "Audio Front Passenger Seat",
    moduleInfo = {
      moduleId = "d77a4bd2-5bd2-4c5a-991a-7ec5f14911ca",
      location = {
        col = 2, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1
      },
      serviceArea = {
        col = 2, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1
      },
      allowMultipleAccess = true
    },
    sourceAvailable = true,
    keepContextAvailable = true,
    volumeAvailable = true,
    equalizerAvailable = true,
    equalizerMaxChannelId = 100
  },
  {
    moduleName = "Audio 2nd Row Left Seat",
    moduleInfo = {
      moduleId = "c64f6c90-6fcb-4543-ae65-c401b3ca08b2",
      location = {
        col = 0, row = 1, level = 0, colspan = 1, rowspan = 1, levelspan = 1
      },
      serviceArea = {
        col = 0, row = 1, level = 0, colspan = 1, rowspan = 1, levelspan = 1
      },
      allowMultipleAccess = true
    },
    sourceAvailable = true,
    keepContextAvailable = true,
    volumeAvailable = true,
    equalizerAvailable = true,
    equalizerMaxChannelId = 100
  }
}
local rcCapabilities = { AUDIO = customAudioCapabilities }
local audioDataToSet = {
  moduleType = "AUDIO",
  audioControlData = {
    source = "FM",
    keepContext = false,
    volume = 44,
    equalizerSettings = {
      {
        channelId = 8,
        channelName = "Channel 7",
        channelSetting = 20
      }
    }
  }
}
local updateData = {
  { moduleId = customAudioCapabilities[1].moduleInfo.moduleId, isSubscribed = true },
  { moduleId = customAudioCapabilities[3].moduleInfo.moduleId, isSubscribed = false }
}
local defaultModuleId = updateData[1].moduleId

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Prepare RC modules capabilities and initial modules data", common.initHmiDataState, { rcCapabilities })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { rcCapabilities })
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { common.PTUfunc })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Subscribe on AUDIO module by sending only moduleType omitting moduleId", common.rpcWithModuleIdOmitted,
  { 1, "AUDIO", defaultModuleId, true })

for key, data in pairs(updateData) do
  local testModuleData = {}
  testModuleData[key] = common.cloneTable(audioDataToSet)
  testModuleData[key].moduleId = data.moduleId
  runner.Step("Check whether we receive or not notifications after changing "..string.sub(data.moduleId,1,8).." module",
    common.isSubscribed, { "AUDIO", data.moduleId, 1, data.isSubscribed, testModuleData[key] })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
