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
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID].groups =
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
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID].groups =
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
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID].groups =
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

--[[ @CheckCuttingUnknowValues: Perform app registration, PTU and check absence of unknown values in
--! OnPermissionsChange notification
--! @parameters:
--! self - test object
--! @return: none
--]]
local function CheckCuttingUnknowValues(ptuUpdateFunc, self)
  commonDefects.rai_ptu_n_without_OnPermissionsChange(1, ptuUpdateFunc, self)
  self.mobileSession1:ExpectNotification("OnPermissionsChange")
  :Times(2)
  :ValidIf(function(exp, data)
      if exp.occurences == 2 then
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
      else
        return true
      end
    end)
end

--[[ @SuccessfulProcessingRPC: Successful processing API
--! @parameters:
--! RPC - RPC name
--! params - RPC params for mobile request
--! interface - interface of RPC on HMI
--! self - test object
--! @return: none
--]]
local function SuccessfulProcessingRPC(RPC, params, interface, self)
  local cid = self.mobileSession1:SendRPC(RPC, params)
  EXPECT_HMICALL(interface .. "." .. RPC, params)
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  self.mobileSession1:ExpectResponse(cid,{ success = true, resultCode = "SUCCESS" })
end

--[[ @removeSnapshotAndTriggerPTUFromHMI: Remove snapshot and trigger PTU from HMI for creation new snapshot,
--! check absence of unknown parameters in snapshot
--! invalid PTU after cutting of unknown values
--! @parameters:
--! self - test object
--! @return: none
--]]
local function removeSnapshotAndTriggerPTUFromHMI(self)
  -- remove Snapshot
  os.execute("rm -f " .. pathToPTS)
  -- expect PolicyUpdate request on HMI side
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate", { file = pathToPTS })
  :Do(function()
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
  -- PTU with invalid PT after cutting of unknown values
  commonDefects.unsuccessfulPTU(ptuUpdateFuncNotValid, self)
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

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonDefects.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonDefects.start)

runner.Title("Test")
runner.Step("App registration, PTU with unknown API", CheckCuttingUnknowValues, { ptuUpdateFuncRPC })
runner.Step("Check applying of PT by processing SendLocation", SuccessfulProcessingRPC,
  { "SendLocation", SendLocationParams, "Navigation" })
runner.Step("Unregister application", commonDefects.unregisterApp)

runner.Step("App registration, PTU with unknown parameters", CheckCuttingUnknowValues, { ptuUpdateFuncParams })
runner.Step("Check applying of PT by processing GetVehicleData", SuccessfulProcessingRPC,
  { "GetVehicleData", { gps = true }, "VehicleInfo" })
runner.Step("Check applying of PT by processing SubscribeVehicleData", DisallowedRPC,
  { "SubscribeVehicleData", { gps = true }, "VehicleInfo" })

runner.Step("Remove Snapshot, created new PTS, invalid PTU after cutting of unknown values",
  removeSnapshotAndTriggerPTUFromHMI)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonDefects.postconditions)
