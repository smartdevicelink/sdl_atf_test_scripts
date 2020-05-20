---------------------------------------------------------------------------------------------
-- GitHub issue https://github.com/SmartDeviceLink/sdl_core/issues/1873
---------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonDefects = require('test_scripts/Defects/4_5/commonDefects')
local json = require("json")

--[[ Test Configuration ]]
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "PROPRIETARY", "EXTERNAL_PROPRIETARY" } } }

--[[ Local Functions ]]
local function updateINIFile()
  commonDefects.backupINIFile()
  commonDefects.clear_HMICapabilitiesCacheFile_parameter_in_INIFile()
end

--! @ptuUpdateFuncDisallowedRPC: Update PT with empty parameters
--! @parameters:
--! tbl - policy table
--! @return: none
local function ptuUpdateFuncDisallowedRPC(tbl)
  local VDgroup = {
    rpcs = {
      GetVehicleData = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"},
        parameters = json.EMPTY_ARRAY
      },
      SubscribeVehicleData = {
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
--! @GetVD: Processing GetVehicleData RPC with resultCode DISALLOWED
--! @parameters:
--! self - test object
--! @return: none
local function GetVD(self)
  -- Send GetVehicleData request from mobile app
  local cid = self.mobileSession1:SendRPC("GetVehicleData", {gps = true})
  -- Does not expect GetVehicleData request on HMI side, times 0.
  EXPECT_HMICALL("VehicleInfo.GetVehicleData")
  :Times(0)
  commonDefects.delayedExp()
  -- Expect GetVehicleData response on mobile side from SDL with resultCode DISALLOWED
  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "DISALLOWED" })
end

--[[ Local Functions ]]
--! @SubscribeVD: Processing SubscribeVehicleData RPC with resultCode DISALLOWED
--! @parameters:
--! self - test object
--! @return: none
local function SubscribeVD(self)
  -- Send SubscribeVehicleData request from mobile app
  local cid = self.mobileSession1:SendRPC("SubscribeVehicleData", {gps = true})
  -- Does not expect GetVehicleData request on HMI side, times 0.
  EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData")
  :Times(0)
  commonDefects.delayedExp()
  -- Expect GetVehicleData response on mobile side from SDL with resultCode DISALLOWED
  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "DISALLOWED" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
-- Stop SDL if process is still running, delete local policy table and log files
runner.Step("Clean environment", commonDefects.preconditions)
runner.Step("Update INI file", updateINIFile)
-- Start SDL and HMI, establish connection between SDL and HMI, open mobile connection via TCP and create mobile session
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonDefects.start)
-- Register application, perform PTU with policy table from ptuUpdateFuncDisallowedRPC
runner.Step("RAI, PTU", commonDefects.rai_ptu, { ptuUpdateFuncDisallowedRPC })
runner.Step("Activate App", commonDefects.activate_app)

runner.Title("Test")
-- Processing GetVehicleData RPC with resultCode DISALLOWED
runner.Step("GEtVD_parameters_empty_in_policy_table", GetVD)
-- Processing SubscribeVehicleData RPC with resultCode DISALLOWED
runner.Step("SubscribeVD_parameters_empty_in_policy_table", SubscribeVD)

-- Perform Ignition Off / On
runner.Step("Ignition Off", commonDefects.ignitionOff)
runner.Step("Start SDL, HMI, connect Mobile", commonDefects.start)
runner.Step("RAI", commonDefects.rai_n)
runner.Step("Activate App", commonDefects.activate_app)
-- Processing GetVehicleData RPC with resultCode DISALLOWED
runner.Step("GEtVD_parameters_empty_in_policy_table", GetVD)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonDefects.postconditions)
runner.Step("Restore INI file", commonDefects.restoreINIFile)
