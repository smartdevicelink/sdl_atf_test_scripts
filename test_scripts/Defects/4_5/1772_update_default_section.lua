---------------------------------------------------------------------------------------------
-- Script verifies issue https://github.com/SmartDeviceLink/sdl_core/issues/1772
-- 1. Make sure SDL is built with PROPRIETARY flag
-- 2. Start SDL and HMI, first ignition cycle
-- 3. Connect device
-- Steps:
-- 1. Register new application
-- 2. Perform PTU with updated default section(can use attached file ptu.json)
-- Expected result:
-- SDL performs update and sends OnPermissionsChange to mobile app with updated permissions.
-- DB has updated info.
-- Actual result:
-- SDL sends to HMI UP_TO_DATE status, but does not update permissions internally.
-- DB is not updated according to new permissions.
-- SDL does not send OnPermissionsChange to mobile app with new permissions.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonDefects = require('test_scripts/Defects/4_5/commonDefects')

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
  speed = 450,
  shifted = true
}

--[[ Local Functions ]]
-- Preparation policy table for Policy table update
-- @tparam table tbl table to update
local function ptuUpdateFunc(tbl)
  -- creation record for PT with RPC GetVehicleData, hmi_levels and parameters
  local VDgroup = {
    rpcs = {
      GetVehicleData = {
        hmi_levels = { "BACKGROUND", "FULL", "LIMITED" },
        parameters = { "gps" }
      }
    }
  }
  -- add NewTestCaseGroup record in structure functional_groupings in PT with value VDgroup
  tbl.policy_table.functional_groupings["NewTestCaseGroup"] = VDgroup
  -- added created group NewTestCaseGroup in structure groups of section default
  -- for update default permissions with new GetVehicleData RPC
  tbl.policy_table.app_policies.default.groups = { "Base-4", "NewTestCaseGroup" }
  -- written nil in policy_table.app_policies[appID] to make sure that PT has no record with update related to appID
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID] = nil
end

-- Successful processing of GetVehicleData RPC
local function GetVD(self)
  -- Request from mobile app
  local cid = self.mobileSession1:SendRPC("GetVehicleData", { gps = true })
  -- expectation of VehicleInfo.GetVehicleData request from SDL on HMI side
  EXPECT_HMICALL("VehicleInfo.GetVehicleData", { gps = true })
  :Do(function(_, data)
      -- sending VehicleInfo.GetVehicleData response from HMI with resultCode SUCCESS
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {gps = gpsDataResponse})
    end)
  -- expectation of GetVehicleData response on mobile app with resultCode SUCCESS
  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
-- Stop SDL if process is still running, delete local policy table and log files
runner.Step("Clean environment", commonDefects.preconditions)
-- Start SDL and HMI, establish connection between SDL and HMI, open mobile connection via TCP and create mobile session
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonDefects.start)
-- Register application and perform PTU with table from local function ptuUpdateFunc
runner.Step("RAI, PTU", commonDefects.rai_ptu, { ptuUpdateFunc })
-- Activate app to FULL HMI level
runner.Step("Activate App", commonDefects.activate_app)

runner.Title("Test")
-- Check successful processing GetVehicleData after update default section with GetVehicleData RPC
runner.Step("GetVD_requet_is_success", GetVD)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonDefects.postconditions)
