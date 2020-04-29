---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0199-Adding-GPS-Shift-support.md
-- Description:
-- In case:
-- 1) Mobile sends GetInteriorVehicleData request
-- 2) SDL transfers this request to HMI
-- 3) HMI sends "shifted" item in "stationLocation" parameter of "moduleData" parameter of GetInteriorVehicleData
--    response
-- SDL does:
-- 1) Cut all parameters except longitudeDegrees, latitudeDegrees, altitude from stationLocation and
--   send GetInteriorVehicleData response to mobile without "shifted" item in "stationLocation" structure of
--   "moduleData" parameter
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
        subscribe = false
    })
    common.getHMIConnection():ExpectRequest("RC.GetInteriorVehicleData", {
        moduleType = "RADIO"
      })
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {
            moduleData = common.radioData,
            isSubscribed = false
          })
    end)

    local expectedRadioData = common.cloneTable(common.radioData)
    expectedRadioData.radioControlData.sisData.stationLocation.shifted = nil
    common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS",
      isSubscribed = false,
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
for _, v in pairs(common.shiftValue) do
    runner.Step("GetInteriorVehicleData RADIO module, shifted " .. tostring(v), getInteriorVehicleData, { v })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditionsRC)
