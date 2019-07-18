---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  Test for checking negative trial to subscribe if "subscribe" parameter was omitted in request from mobile.
--  Check that if we made some changes in module, to which we failed to subscribe, SDL will send no notifications
--  to the mobile application
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) HMI sent SEAT module capabilities to the SDL
-- 3) Mobile is connected to the SDL
-- 4) App is registered and activated
--
-- Steps:
-- 1) App sends "GetInteriorVehicleData"(moduleType = "SEAT", moduleId = "650765bb") request
--   Check:
--    SDL resends "RC.GetInteriorVehicleData" (moduleType = "SEAT", moduleId = "650765bb") request to the HMI
--    HMI sends "RC.GetInteriorVehicleData"(moduleType = "SEAT", moduleId = "650765bb", seatControlData)
--     response to the SDL
--    SDL resends "GetInteriorVehicleData"
--     (moduleType = "SEAT", moduleId = "650765bb", seatControlData, resultCode = SUCCESS) response to the App
-- 2) After some changes were made to the module HMI sends "RC.OnInteriorVehicleData" notification to the SDL
--   Check:
--    SDL does not send any notification to the App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local customSeatCapabilities = {
  {
    moduleName = "Seat of Driver",
    moduleInfo = {
      moduleId = "a42bf1e0-e02e-4462-912a-7d4230815f73",
      location = {
        col = 0, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1
      },
      serviceArea = {
        col = 0, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1
      },
      allowMultipleAccess = true
    },
    coolingEnabledAvailable = true,
    coolingLevelAvailable = true,
    horizontalPositionAvailable = true,
    verticalPositionAvailable = true
  },
  {
    moduleName = "Seat of Front Passenger",
    moduleInfo = {
      moduleId = "650765bb-2f89-4d68-a665-6267c80e6c62",
      location = {
        col = 2, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1
      },
      serviceArea = {
        col = 2, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1
      },
      allowMultipleAccess = true
    },
    coolingEnabledAvailable = true,
    coolingLevelAvailable = true,
    horizontalPositionAvailable = true,
    verticalPositionAvailable = true,
    massageEnabledAvailable = true,
    massageModeAvailable = true,
    massageCushionFirmnessAvailable = true,
    memoryAvailable = true
  }
}
local rcCapabilities = { SEAT = customSeatCapabilities }
local seatDataToSet = {
  moduleType = "SEAT",
  seatControlData = {
    coolingEnabled = true,
    coolingLevel = 77,
    horizontalPosition = 77,
    verticalPosition = 44
  }
}
local omittedSubscribe = nil
local notSubscribed = false
local moduleId = customSeatCapabilities[2].moduleInfo.moduleId

local function subscribeToModuleNegative(pModuleType, pModuleId, pAppId, pSubscribe)
  local rpc = "GetInteriorVehicleData"
  local mobSession = common.getMobileSession(pAppId)
  local hmi = common.getHMIConnection()
  local cid = mobSession:SendRPC(rpc, common.getAppRequestParams(rpc, pModuleType, pModuleId, pSubscribe))
  hmi:ExpectRequest("RC."..rpc, common.getHMIRequestParams(rpc, pModuleType, pModuleId, pAppId, pSubscribe))
  :Do(function(_, data)
    hmi:SendResponse(data.id, data.method, "SUCCESS",
      common.getHMIResponseParams(rpc, pModuleType, pModuleId, pSubscribe))
    end)
  mobSession:ExpectResponse(cid, common.getAppResponseParams
    (rpc, true, "SUCCESS", pModuleType, pModuleId, pSubscribe))
  :ValidIf(function(_, data)
      if data and data.payload and data.payload.moduleData then
        if data.payload.moduleData.audioControlData and nil ~= data.payload.moduleData.audioControlData.keepContext then
          return false, "Mobile response GetInteriorVehicleData contains unexpected keepContext parameter"
        end
      end
      return true
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Prepare RC modules capabilities and initial modules data", common.initHmiDataState, { rcCapabilities })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { rcCapabilities })
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { common.PTUfunc })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
  runner.Step("Subscribe on SEAT module by sending moduleType and moduleId", subscribeToModuleNegative,
    { "SEAT", moduleId, 1, omittedSubscribe })
  runner.Step("Check of NOT receiving notification by the App after making changes in SEAT module", common.isSubscribed,
    { "SEAT", moduleId, 1, notSubscribed, seatDataToSet })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
