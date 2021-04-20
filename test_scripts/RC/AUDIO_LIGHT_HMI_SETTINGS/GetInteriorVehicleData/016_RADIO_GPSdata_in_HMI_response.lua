---------------------------------------------------------------------------------------------------
-- Proposal https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0099-new-remote-control-modules-and-parameters.md
-- User story: TBD
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/current_module_status_data.md
-- Item: Use Case 1: Main Flow
--
-- Requirement summary:
-- [SDL_RC] Current module status data GetInteriorVehicleData
--
-- Description:
-- In case:
-- 1) RC app sends GetInteriorVehicleData request with valid parameters
-- 2) and SDL gets response (resultCode: SUCCESS) and data from GPSData struct in stationLocation from HMI
-- SDL must:
-- 1) Respond to App with success:true, "SUCCESS" and resend values received from HMI in case all values are valid and all mandatory parameters are present
-- S) Respond to App with success:false, "GENERIC_ERROR" in case mandatry parameters are missed
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/commonRC")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local moduleName = "RADIO"

local paramsForPositiveCase = {
  mandatoryOnly = {
    longitudeDegrees = 20.1,
    latitudeDegrees = 20.1
  },
  mandatoryWithAltitude = {
    longitudeDegrees = 20.1,
    latitudeDegrees = 20.1,
    altitude = 20.1
  },
  allGPSdata = {
    longitudeDegrees = 20.1,
    latitudeDegrees = 20.1,
    altitude = 20.1,
    utcYear = 2020,
    utcMonth = 5,
    utcDay = 15,
    utcHours = 5,
    utcMinutes = 30,
    utcSeconds = 30,
    compassDirection = "NORTH",
    pdop = 5,
    hdop = 5,
    vdop = 5,
    actual = true,
    satellites = 5,
    dimension = "NO_FIX",
    heading = 10.1,
    speed = 15
  }
}

local paramsMissingMandatory = {
  onlyLongitude = {
    longitudeDegrees = 20.1
  },
  onlyLatitude = {
    latitudeDegrees = 20.1
  }
}

--[[ Local Functions ]]
local function getRadioParams(pStationLocationParams)
  local rcCapabilities = common.getDefaultHMITable().RC.GetCapabilities.params.remoteControlCapability
  local moduleId = rcCapabilities.radioControlCapabilities[1].moduleInfo.moduleId
  local  radioParams = {
    moduleType = moduleName,
    moduleId = moduleId,
    radioControlData = {
      sisData = {
        stationShortName = "Name2",
        stationIDNumber = {
          countryCode = 200,
          fccFacilityId = 200
        },
        stationLongName = "RadioStationLongName2",
        stationLocation = pStationLocationParams,
        stationMessage = "station message 2"
      }
    }
  }
  return radioParams
end

local function getDataForModule(pStationLocationParams, isSuccess)
  local radioParamsHMIRes = getRadioParams(pStationLocationParams)
  local dataForMobileRes = common.cloneTable(pStationLocationParams)
  for key in pairs (dataForMobileRes) do
    if key ~= "longitudeDegrees" and key ~= "latitudeDegrees" and key ~= "altitude" then
      dataForMobileRes[key] = nil
    end
  end
  local radioParamsMobileRes = getRadioParams(dataForMobileRes)
  local mobileSession = common.getMobileSession()
  local cid = mobileSession:SendRPC("GetInteriorVehicleData", {
      moduleType = moduleName
    })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {
      moduleType = moduleName
    })
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { moduleData = radioParamsHMIRes })
    end)
  if isSuccess == true then
    mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS", moduleData = radioParamsMobileRes })
  else
    mobileSession:ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle" })
  end

end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")

for key, value in pairs(paramsForPositiveCase) do
  runner.Step("GetInteriorVehicleData stationLocation " .. key, getDataForModule, { value, true })
end
for key, value in pairs(paramsMissingMandatory) do
  runner.Step("GetInteriorVehicleData stationLocation " .. key, getDataForModule, { value, false })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
