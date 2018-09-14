---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/1879
--
-- Description:
-- SDL does not send GetVehilceData_response to mobile app in case of receiving 'gpsData' structure
-- with only one parameter with valid value
-- Precondition:
-- SDL and HMI are started.
-- App is registered and activated.
-- In case:
-- 1) HMI sends GetVehilceData_response with 'gpsData' structure and this structure has one parameter with valid value.
-- Expected result:
-- 1) SDL must treat GetVehicleData_response as valid and transfer GetVehicleData_response to mobile app
-- Actual result:
-- N/V
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('user_modules/sequences/actions')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local beltStatusResponse = {
    driverBeltDeployed = "NOT_SUPPORTED",
    passengerBeltDeployed = "YES",
    passengerBuckleBelted = "YES",
    driverBuckleBelted = "YES",
    leftRow2BuckleBelted = "YES",
    passengerChildDetected = "YES",
    rightRow2BuckleBelted = "YES",
    middleRow2BuckleBelted = "YES",
    middleRow3BuckleBelted = "YES",
    leftRow3BuckleBelted = "YES",
    rightRow3BuckleBelted = "YES",
    leftRearInflatableBelted = "YES",
    rightRearInflatableBelted = "YES",
    middleRow1BeltDeployed = "YES",
    middleRow1BuckleBelted = "YES"
}

local gpsDataWithOneValidParam = {
    longitudeDegrees = 181,
    latitudeDegrees = 91,
    utcYear = 2101,
    utcMonth = 13,
    utcDay = 32,
    utcHours = 24,
    utcMinutes = 60,
    utcSeconds = 60,
    compassDirection = "false",
    pdop = 1001,
    hdop = 1001,
    vdop = 1001,
    actual = true, -- valid param
    satellites = 32,
    dimension = "true",
    altitude = 10001,
    heading = 360.1,
    speed = 501
}

--[[ Local Functions ]]
local function ptuForApp(tbl)
    local VDgroup = {
        rpcs = {
            GetVehicleData = {
                hmi_levels = {"BACKGROUND", "FULL", "LIMITED"},
                parameters = {"gps", "beltStatus"}
            }
        }
    }
    tbl.policy_table.functional_groupings["NewTestCaseGroup"] = VDgroup
    tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].groups = {"Base-4", "NewTestCaseGroup"}
end

local function GetVD()
    local cid = common.getMobileSession():SendRPC("GetVehicleData",
        {gps = true, beltStatus = true})
        common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", {gps = true, beltStatus = true})
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
        { gps = gpsDataWithOneValidParam, beltStatus = beltStatusResponse })
    end)
    common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS",
        gps = gpsDataWithOneValidParam, beltStatus = beltStatusResponse  })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("RAI, PTU", common.policyTableUpdate, { ptuForApp })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("GetVehicleData_SUCCESS", GetVD)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
