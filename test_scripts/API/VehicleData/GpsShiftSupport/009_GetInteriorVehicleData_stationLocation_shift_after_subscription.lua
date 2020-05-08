---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0199-Adding-GPS-Shift-support.md
-- Description:
-- In case:
-- 1) Mobile sends GetInteriorVehicleData request with subscribe=true
-- 2) SDL transfers this request to HMI
-- 3) HMI sends "shifted" item in "stationLocation" parameter of "moduleData" parameter of GetInteriorVehicleData
--    response
-- 4) Mobile sends another GetInteriorVehicleData request without subscribe parameter
-- SDL does:
-- 1) Cut all parameters except longitudeDegrees, latitudeDegrees, altitude from stationLocation and
--   send GetInteriorVehicleData response to mobile without "shifted" item in "stationLocation" structure of
--   "moduleData" parameter for the first request
-- 2) Send a GetInteriorVehicleData response without "shifted" item for the second request
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/GpsShiftSupport/commonGpsShift')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local Functions ]]
local function getInteriorVehicleData(pShiftValue)
    common.radioData.radioControlData.sisData.stationLocation.shifted = pShiftValue
    local cid = common.getMobileSession():SendRPC("GetInteriorVehicleData", {
        moduleType = "RADIO",
        subscribe = true
    })
    common.getHMIConnection():ExpectRequest("RC.GetInteriorVehicleData", {
        moduleType = "RADIO"
      })
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {
            moduleData = common.radioData,
            isSubscribed = true
          })
    end)

    local expectedRadioData = common.cloneTable(common.radioData)
    expectedRadioData.radioControlData.sisData.stationLocation.shifted = nil
    common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS",
      isSubscribed = true,
      moduleData = expectedRadioData
    })
    :ValidIf(function(_, data)
        return common.checkShifted(data.payload.moduleData.radioControlData.sisData.stationLocation.shifted, nil)
    end)
end

local function getInteriorVehicleDataSubscribed()
    local cid = common.getMobileSession():SendRPC("GetInteriorVehicleData", {
        moduleType = "RADIO"
    })
    common.getHMIConnection():ExpectRequest("RC.GetInteriorVehicleData", {
        moduleType = "RADIO"
      })
    :Times(0)

    local expectedRadioData = common.cloneTable(common.radioData)
    expectedRadioData.radioControlData.sisData.stationLocation.shifted = nil
    common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS",
      moduleData = expectedRadioData
    })
    :ValidIf(function(_, data)
        return common.checkShifted(data.payload.moduleData.radioControlData.sisData.stationLocation.shifted, nil)
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditionsRC)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("GetInteriorVehicleData subscription RADIO module, shifted true", getInteriorVehicleData, { true })
runner.Step("GetInteriorVehicleData RADIO module subscribed, without shifted", getInteriorVehicleDataSubscribed)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditionsRC)
