---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0199-Adding-GPS-Shift-support.md
-- Description:
-- In case:
-- 1) App registered and subscribed on RADIO
-- 2) HMI sends "shifted" item in "stationLocation" parameter of "moduleData" parameter of OnInteriorVehicleData
--    notification
-- SDL does:
-- 1) Cut all parameters except longitudeDegrees, latitudeDegrees, altitude from stationLocation and send
--   OnInteriorVehicleData notification to mobile without "shifted" item in "stationLocation" structure
--   of "moduleData" parameter
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/GpsShiftSupport/commonGpsShift')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local Functions ]]
local function onInteriorVehicleData(pShiftValue)
    common.radioData.radioControlData.sisData.stationLocation.shifted = pShiftValue
    common.getHMIConnection():SendNotification("RC.OnInteriorVehicleData", { moduleData = common.radioData })
    local expectedRadioData = common.cloneTable(common.radioData)
    expectedRadioData.radioControlData.sisData.stationLocation.shifted = nil
    common.getMobileSession():ExpectNotification("OnInteriorVehicleData", { moduleData = expectedRadioData })
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
runner.Step("Subscribe on InteriorVehicleData, RADIO module", common.getInteriorVehicleData, { nil, true })

runner.Title("Test")
for _, v in pairs(common.shiftValue) do
    runner.Step("OnInteriorVehicleData, RADIO module, shifted " .. tostring(v), onInteriorVehicleData, { v })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditionsRC)
