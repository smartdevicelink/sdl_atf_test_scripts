---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/1886
-- Description: PoliciesManager must allow all requested params in case "parameters" field is omitted
-- Precondition:
-- 1) SDL and HMI are started.
-- 2) App is registered and activated.
-- 3) PTU is performed and "parameters" field is omitted at PolicyTable for used request
-- In case:
-- 1) In case SDL receives OnVehicleData notification from HMI
-- and this notification is allowed by Policies for this mobile app
-- Expected result:
-- 1) SDL must transfer received notification with all parameters as is to mobile app
-- respond with <received_resultCode_from_HMI> to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function ptuUpdateFuncDissalowedRPC(tbl)
  local VDgroup = {
    rpcs = {
      GetVehicleData = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"},
        -- parameters omitted
      },
      OnVehicleData = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"},
        -- parameters omitted
      },
      SubscribeVehicleData = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"},
        -- parameters omitted
      },
      UnsubscribeVehicleData = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"},
        -- parameters omitted
      },
      SendLocation = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"},
        -- parameters omitted
      }
    }
  }
  tbl.policy_table.functional_groupings["NewTestCaseGroup"] = VDgroup
  if tbl.policy_table.functional_groupings["SendLocation"] then
    tbl.policy_table.functional_groupings["SendLocation"] = nil
  end
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].groups = {"Base-4", "NewTestCaseGroup"}
end

local gpsResponse = {
  longitudeDegrees = -180,
  latitudeDegrees = 90,
  utcYear = 2100,
  utcMonth = 12,
  utcDay = 22,
  utcHours = 20,
  utcMinutes = 50,
  utcSeconds = 50,
  compassDirection = "NORTH",
  pdop = 1000,
  hdop = 1000,
  vdop = 1000,
  actual = true,
  satellites = 31,
  dimension = "2D",
  altitude = 10000,
  heading = 359.99,
  speed = 500,
  shifted = true
}

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
  speed = 450,
  shifted = true
}

local requestParams = {
  longitudeDegrees = 1.1,
  latitudeDegrees = 1.1,
  addressLines =
  { "line1", "line2" },
  address = {
    countryName = "countryName",
    countryCode = "countryName",
    postalCode = "postalCode",
    administrativeArea = "administrativeArea",
    subAdministrativeArea = "subAdministrativeArea",
    locality = "locality",
    subLocality = "subLocality",
    thoroughfare = "thoroughfare",
    subThoroughfare = "subThoroughfare"
  },
  timeStamp = {
    millisecond = 0,
    second = 40,
    minute = 30,
    hour = 14,
    day = 25,
    month = 5,
    year = 2017,
    tz_hour = 5,
    tz_minute = 30
  },
  locationName = "location Name",
  locationDescription = "location Description",
  phoneNumber = "phone Number",
  deliveryMode = "PROMPT",
}

local function GetVD()
  local cid = common.getMobileSession():SendRPC("GetVehicleData", {gps = true})
  common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", {gps = true})
  :Do(function(_,data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {gps = gpsResponse})
  end)
  common.getMobileSession():ExpectResponse(cid, {success = true, resultCode = "SUCCESS"})
end

local function SubscribeVD()
  local cid = common.getMobileSession():SendRPC("SubscribeVehicleData", {gps = true})
  common.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData", {gps = true})
  :Do(function(_,data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
    {gps = { dataType = "VEHICLEDATA_GPS", resultCode = "SUCCESS" }})
  end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

local function OnVD()
  common.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", {gps = gpsDataResponse} )
  common.getMobileSession():ExpectNotification("OnVehicleData")
end

local function UnsubscribeVD()
  local cid = common.getMobileSession():SendRPC("UnsubscribeVehicleData", {gps = true})
  common.getHMIConnection():ExpectRequest("VehicleInfo.UnsubscribeVehicleData", {gps = true})
  :Do(function(_,data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
    {gps = {dataType = "VEHICLEDATA_GPS", resultCode = "SUCCESS"}})
  end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

local function sendLocation(params)
  local cid = common.getMobileSession():SendRPC("SendLocation", params)
  common.getHMIConnection():ExpectRequest("Navigation.SendLocation")
  :Do(function(_,data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Test ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("PTU update", common.policyTableUpdate, { ptuUpdateFuncDissalowedRPC })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("GetVD_parameters_ommited_in_policy_table", GetVD)
runner.Step("SubscribeVD_parameters_ommited_in_policy_table", SubscribeVD)
runner.Step("OnVD_parameters_ommited_in_policy_table", OnVD)
runner.Step("UnsubscribeVD_parameters_ommited_in_policy_table", UnsubscribeVD)
runner.Step("SendLocation_parameters_ommited_in_policy_table", sendLocation, { requestParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
