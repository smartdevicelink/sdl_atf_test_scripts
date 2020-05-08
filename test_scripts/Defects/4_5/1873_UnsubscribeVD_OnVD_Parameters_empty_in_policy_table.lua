---------------------------------------------------------------------------------------------
-- GitHub issue: https://github.com/SmartDeviceLink/sdl_core/issues/1873
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonDefects = require('test_scripts/Defects/4_5/commonDefects')
local json = require("json")

--[[ Test Configuration ]]
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "PROPRIETARY", "EXTERNAL_PROPRIETARY" } } }

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
--! @ptuUpdateFuncDisallowedRPC: Update PT with empty parameters
--! @parameters:
--! tbl - policy table
--! @return: none
local function ptuUpdateFuncDisallowedRPC(tbl)
  local VDgroup = {
    rpcs = {
      SubscribeVehicleData = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"},
        parameters = {"gps"}
      },
      OnVehicleData = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"},
        parameters = json.EMPTY_ARRAY
      },
      UnsubscribeVehicleData = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"},
        parameters = json.EMPTY_ARRAY
      }
    }
  }
  tbl.policy_table.functional_groupings.NewTestCaseGroup = VDgroup
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].groups =
  {"Base-4", "NewTestCaseGroup"}
end

--[[ Local Functions ]]
--! @SubscribeVD: Successful processing SubscribeVehicleData RPC
--! @parameters:
--! self - test object
--! @return: none
local function SubscribeVD(self)
  -- Send request SubscribeVehicleData from mobile app
  local cid = self.mobileSession1:SendRPC("SubscribeVehicleData", {gps = true})
  -- Expect SubscribeVehicleData request on HMI side form SDL
  EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData")
  :Do(function(_,data)
      -- Send SubscribeVehicleData response from HMI to SDL with resultCode SUCCESS
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
        gps = { resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS" }
      })
    end)
  -- Expect successful SubscribeVehicleData response on mobile app
  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Local Functions ]]
--! @UnsubscribeVD: Processing UnsubscribeVehicleData RPC with resultCode DISALLOWED
--! @parameters:
--! self - test object
--! @return: none
local function UnsubscribeVD(self)
  local cid = self.mobileSession1:SendRPC("UnsubscribeVehicleData", {gps = true})
  -- Send UnsubscribeVehicleData request from mobile app
  EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData")
  -- Does not expect UnsubscribeVehicleData request on HMI side, times 0.
  :Times(0)
  commonDefects.delayedExp()
  -- Expect UnsubscribeVehicleData response on mobile side from SDL with resultCode DISALLOWED
  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "DISALLOWED" })
end

--[[ Local Functions ]]
--! @OnVD: Processing OnVehicleData RPC with resultCode DISALLOWED
--! @parameters:
--! self - test object
--! @return: none
local function OnVD(self)
  -- Send OnVehicleData request notification from HMI to SDL
  self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", {gps = gpsDataResponse} )
  -- Does not expect OnVehicleData notification on mobile side, times 0.
  self.mobileSession1:ExpectNotification("OnVehicleData")
  :Times(0)
  commonDefects.delayedExp(500)
end

--[[ Scenario ]]
runner.Title("Preconditions")
-- Stop SDL if process is still running, delete local policy table and log files
runner.Step("Clean environment", commonDefects.preconditions)
-- Start SDL and HMI, establish connection between SDL and HMI, open mobile connection via TCP and create mobile session
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonDefects.start)
-- Register application, perform PTU with policy table from ptuUpdateFuncDisallowedRPC
runner.Step("RAI, PTU", commonDefects.rai_ptu, { ptuUpdateFuncDisallowedRPC })
runner.Step("Activate App", commonDefects.activate_app)
-- Subscribe to gps as precondition for UnsubscribeVehicleData
runner.Step("SubscribeVD", SubscribeVD)

runner.Title("Test")
-- Processing OnVehicleData notification as not allowed by policies
runner.Step("OnVD_parameters_empty_in_policy_table", OnVD)
-- Processing GetVehicleData RPC with resultCode DISALLOWED
runner.Step("UnsubscribeVD_parameters_empty_in_policy_table", UnsubscribeVD)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonDefects.postconditions)
