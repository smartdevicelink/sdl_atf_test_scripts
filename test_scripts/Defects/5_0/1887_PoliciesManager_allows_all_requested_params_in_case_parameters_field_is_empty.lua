---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/1887
--
-- Description:
-- PoliciesManager allows all requested params in case "parameters" field is empty
-- Precondition:
-- SDL and HMI are started.
-- App is registered and activated.
-- In case:
-- 1) In case SDL receives OnVehicleData notification from HMI
--    and this notification is allowed by Policies for this mobile app
--    and "parameters" field is empty at PolicyTable for OnVehicleData notification
-- Expected result:
-- 1) SDL must log corresponding error internally
--    SDL must NOT transfer this notification to mobile app
-- Actual result:
-- N/A
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('user_modules/sequences/actions')
local runner = require('user_modules/script_runner')
local json = require("json")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local gpsDataResponse = {
    longitudeDegrees = 100,
    latitudeDegrees = 20,
    utcYear = 2050,
    utcMonth = 10,
    utcDay = 30,
    utcHours = 20,
    utcMinutes = 50,
    utcSeconds = 50,
    compassDirection = "NORTH",
    pdop = 5,
    hdop = 5,
    vdop = 5,
    actual = false,
    satellites = 30,
    dimension = "2D",
    altitude = 9500,
    heading = 350,
    speed = 450
}

--[[ Local Functions ]]
local function pTUpdateFunc(tbl)
    local VDgroup = {
        rpcs = {
            SubscribeVehicleData = {
                hmi_levels = {"BACKGROUND", "FULL", "LIMITED"},
                parameters = {"gps"}
            },
            OnVehicleData = {
                hmi_levels = {"BACKGROUND", "FULL", "LIMITED"},
                parameters = json.EMPTY_ARRAY
            }
        }
    }
    tbl.policy_table.functional_groupings["NewTestCaseGroup"] = VDgroup
    tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].groups = {"Base-4", "NewTestCaseGroup"}
end

local function SubscribeVD()
    local cid = common.getMobileSession():SendRPC("SubscribeVehicleData", {gps = true})
    EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData")
    :Do(function(_,data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {
        gps = { resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS" }
      })
    end)
    common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

local function onVehicleData()
    common.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", {gps = gpsDataResponse} )
    common.getMobileSession():ExpectNotification("OnVehicleData")
    :Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { pTUpdateFunc })
runner.Step("Activate App", common.activateApp)
runner.Step("SubscribeVD", SubscribeVD)

runner.Title("Test")
runner.Step("OnVD_parameters_empty_in_policy_table", onVehicleData)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
