---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/1921
-- Precondition:
-- 1. SDL and HMI are started.
-- 2. App is registered.
-- Steps:
-- 1. SDL received UpdatedPT with at least one <unknown_parameter> or <unknown_RPC>
-- and after cutting off <unknown_parameter> or <unknown_RPC> UpdatedPT is invalid
-- Expected result: SDL must log the error internally and discard Policy Table Update
-- Actual result:N/A
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonDefects = require('test_scripts/Defects/4_5/commonDefects')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local json = require("modules/json")

--[[ General configuration parameters ]]
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "PROPRIETARY" } } }

--[[ Local variables ]]
-- define path to policy table snapshot
local pathToPTS = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath") .. "/"
  .. commonFunctions:read_parameter_from_smart_device_link_ini("PathToSnapshot")
-- set default parameters for 'SendLocation' RPC
local SendLocationParams = {
  longitudeDegrees = 1.1,
  latitudeDegrees = 1.1,
}
local unknownAPI = "UnknownAPI"
local unknownParameter = "unknownParameter"

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

--[[ @ptsToTable: decode snapshot from json to table
--! @parameters:
--! pts_f - file for decode
--! @return: created table from file
--]]
local function ptsToTable(pts_f)
  local f = io.open(pts_f, "r")
  local content = f:read("*all")
  f:close()
  return json.decode(content)
end

--[[ @ptuUpdateFuncRPC: update table with unknown RPC for PTU
--! @parameters:
--! tbl - table for update
--! @return: none
--]]
local function ptuUpdateFuncRPC(tbl)
  local VDgroup = {
    rpcs = {
      [unknownAPI] = {
        hmi_levels = { "NONE", "BACKGROUND", "FULL", "LIMITED" },
        parameters = { "gps" }
      },
      SendLocation = {
        hmi_levels = { "NONE", "BACKGROUND", "FULL", "LIMITED" }
      }
    }
  }
  tbl.policy_table.functional_groupings["NewTestCaseGroup1"] = VDgroup
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].groups =
    { "Base-4", "NewTestCaseGroup1" }
end

--[[ @ptuUpdateFuncParams: update table with unknown parameters for PTU
--! @parameters:
--! tbl - table for update
--! @return: none
--]]
local function ptuUpdateFuncParams(tbl)
  local VDgroup = {
    rpcs = {
      GetVehicleData = {
        hmi_levels = { "NONE", "BACKGROUND", "FULL", "LIMITED" },
        parameters = { "gps", unknownParameter }
      }
    }
  }
  tbl.policy_table.functional_groupings["NewTestCaseGroup2"] = VDgroup
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].groups =
    { "Base-4", "NewTestCaseGroup1", "NewTestCaseGroup2" }
end

--[[ @NotValidPtuUpdateFunc: update table for PTU with invalid content
--! @parameters:
--! tbl - table for update
--! @return: none
--]]
local function ptuUpdateFuncNotValid(tbl)
  local VDgroup = {
    rpcs = {
      GetVehicleData = {
        hmi_levels = { "BACKGROUND", "FULL", "LIMITED" },
        parameters = { "gps", unknownParameter }
      },
      SubscribeVehicleData = {
        hmi_levels = { "BACKGROUND", "FULL", "LIMITED" },
      },
      [unknownAPI] = {
        hmi_levels = { "BACKGROUND", "FULL", "LIMITED" },
        parameters = { "gps" }
      },
      SendLocation = {
        -- missed mandatory hmi_levels parameter
      }
    }
  }
  tbl.policy_table.functional_groupings["NewTestCaseGroup3"] = VDgroup
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].groups =
    { "Base-4", "NewTestCaseGroup1", "NewTestCaseGroup2", "NewTestCaseGroup3" }
end

--[[ @contains: verify if defined value is present in table
--! @parameters:
--! pTbl - table for update
--! pValue - value
--! @return: true - in case value is present in table, otherwise - false
--]]
local function contains(pTbl, pValue)
  for _, v in pairs(pTbl) do
    if v == pValue then return true end
  end
  return false
end

--[[ @CheckCuttingUnknownValues: expectation of OnPermissionsChange notification and check its content
--! @parameters:
--! pNotifTimes - expected number of OnPermissionsChange notification
--! self - test object
--! @return: none
--]]
local function CheckCuttingUnknownValues(pNotifTimes, self)
  self.mobileSession1:ExpectNotification("OnPermissionsChange")
    :Times(pNotifTimes)
    :ValidIf(function(_, data)
        local isError = false
        local ErrorMessage = ""
        if #data.payload.permissionItem ~= 0 then
          for i = 1, #data.payload.permissionItem do
            if data.payload.permissionItem[i].rpcName == unknownAPI then
              commonFunctions:userPrint(33, " OnPermissionsChange contains '" .. unknownAPI .. "' value")
            end
            local pp = data.payload.permissionItem[i].parameterPermissions
            if contains(pp.allowed, unknownParameter) or contains(pp.userDisallowed, unknownParameter) then
              isError = true
              ErrorMessage = ErrorMessage .. "\nOnPermissionsChange contains '" .. unknownParameter .. "' value"
            end
          end
        else
          isError = true
          ErrorMessage = ErrorMessage .. "\nOnPermissionsChange is not contain 'permissionItem' elements"
        end
        if isError == true then
          return false, ErrorMessage
        else
          return true
        end
      end)
end

--[[ @rai_with_OnPermissionChange: Perform app registration, check received OnPermissionsChange notification
--! @parameters:
--! pUpdateFunction - update table for PTU
--! self - test object
--! @return: none
--]]
local function rai_with_OnPermissionChange(ptuUpdateFunc, self)
  commonDefects.rai_ptu_n_without_OnPermissionsChange(1, ptuUpdateFunc, self)
  CheckCuttingUnknownValues(2, self)
end

--[[ @SuccessfulProcessingRPC: Successful processing API
--! @parameters:
--! RPC - RPC name
--! params - RPC params for mobile request
--! interface - interface of RPC on HMI
--! responseParams - parameters for sent response
--! self - test object
--! @return: none
--]]
local function SuccessfulProcessingRPC(RPC, params, interface, responseParams, self)
  local cid = self.mobileSession1:SendRPC(RPC, params)
  EXPECT_HMICALL(interface .. "." .. RPC, params)
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responseParams)
    end)
  self.mobileSession1:ExpectResponse(cid,{ success = true, resultCode = "SUCCESS" })
end

--[[ @triggerPTU: Trigger PTU from HMI via OnPolicyUpdate notification
--! @parameters:
--! self - test object
--! @return: none
--]]
local function triggerPTU(self)
  self.hmiConnection:SendNotification("SDL.OnPolicyUpdate", { })
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status = "UPDATE_NEEDED" }, { status = "UPDATING" })
  :Times(2)
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate", { file = pathToPTS })
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end)
end

--[[ @ptuExpUnsuccessFlow: Expectations of OnStatusUpdate notifications during unsuccessful PTU
--! @parameters: none
--! @return: none
--]]
local function ptuExpUnsuccessFlow()
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status = "UPDATE_NEEDED" })
end

--[[ @removeSnapshotAndTriggerPTUFromHMI: Remove snapshot and trigger PTU from HMI for creation new snapshot,
--! check absence of unknown parameters in snapshot
--! @parameters:
--! self - test object
--! @return: none
--]]
local function removeSnapshotAndTriggerPTUFromHMI(self)
  -- remove Snapshot
  os.execute("rm -f " .. pathToPTS)
  -- expect PolicyUpdate request on HMI side
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate", { file = pathToPTS })
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
      if (commonSteps:file_exists(pathToPTS) == false) then
        self:FailTestCase(pathToPTS .. " is not created")
      else
        local pts = ptsToTable(pathToPTS)
        local rpcs = pts.policy_table.functional_groupings.NewTestCaseGroup1.rpcs
        if rpcs[unknownAPI] then
          commonFunctions:userPrint(33, " Snapshot contains '" .. unknownAPI .. "'")
        end
        local parameters = pts.policy_table.functional_groupings.NewTestCaseGroup2.rpcs.GetVehicleData.parameters
        if contains(parameters, unknownParameter) then
          self:FailTestCase("Snapshot contains '" .. unknownParameter .. "' for GetVehicleData RPC")
        end
      end
    end)
  -- Sending OnPolicyUpdate notification form HMI
  self.hmiConnection:SendNotification("SDL.OnPolicyUpdate", { })

  -- Expect OnStatusUpdate notifications on HMI side
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status = "UPDATE_NEEDED" }, { status = "UPDATING" })
  :Times(2)
end

--[[ @DisallowedRPC: Unsuccessful processing of API with Disallowed status
--! @parameters:
--! RPC - RPC name
--! params - RPC params for mobile request
--! interface - interface of RPC on HMI
--! self - test object
--! @return: none
--]]
local function DisallowedRPC(RPC, params, interface, self)
  local cid = self.mobileSession1:SendRPC(RPC, params)
  EXPECT_HMICALL(interface .. "." .. RPC)
  :Times(0)
  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "DISALLOWED" })
  commonDefects.delayedExp()
end

--[[ @ptu: Policy table update
--! @parameters:
--! pUpdateFunction - update table for PTU
--! self - test object
--! @return: none
--]]
local function ptu(pUpdateFunction, self)
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status = "UP_TO_DATE" })
  commonDefects.ptu(pUpdateFunction, self)
  CheckCuttingUnknownValues(1, self)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonDefects.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonDefects.start)

runner.Title("Test")
runner.Step("App registration, PTU with unknown API", rai_with_OnPermissionChange, { ptuUpdateFuncRPC })
runner.Step("Check applying of PT by processing SendLocation", SuccessfulProcessingRPC,
  { "SendLocation", SendLocationParams, "Navigation", {} })
runner.Step("Trigger PTU from HMI", triggerPTU)

runner.Step("PTU with unknown parameters", ptu, { ptuUpdateFuncParams })
runner.Step("Check applying of PT by processing GetVehicleData", SuccessfulProcessingRPC,
  { "GetVehicleData", { gps = true }, "VehicleInfo", { gps = gpsDataResponse } })
runner.Step("Check applying of PT by processing SubscribeVehicleData", DisallowedRPC,
  { "SubscribeVehicleData", { gps = true }, "VehicleInfo" })

runner.Step("Remove Snapshot and trigger PTU, check new created PTS", removeSnapshotAndTriggerPTUFromHMI)
runner.Step("Invalid_PTU_after_cutting_off_unknown_values", commonDefects.unsuccessfulPTU,
  { ptuUpdateFuncNotValid, ptuExpUnsuccessFlow })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonDefects.postconditions)
