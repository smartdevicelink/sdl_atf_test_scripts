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
local unknownParameter = "unknownParameter"

--[[ Local Functions ]]

--[[ @ptsToTable: decode snapshot from json to table
--! @parameters:
--! pFile - file for decode
--! @return: created table from file
--]]
local function ptsToTable(pFile)
  local f = io.open(pFile, "r")
  local content = f:read("*all")
  f:close()
  return json.decode(content)
end

--[[ @ptuUpdateFuncParams: update table with unknown parameter for PTU
--! @parameters:
--! pTbl - table for update
--! @return: none
--]]
local function ptuUpdateFuncParams(pTbl)
  local VDgroup = {
    rpcs = {
      GetVehicleData = {
        hmi_levels = { "NONE", "BACKGROUND", "FULL", "LIMITED" },
        parameters = { unknownParameter }
      }
    }
  }
  pTbl.policy_table.functional_groupings["NewTestCaseGroup1"] = VDgroup
  pTbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID].groups =
    { "Base-4", "NewTestCaseGroup1" }
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

--[[ @checkCuttingUnknowValues: Perform app registration, PTU and check absence of unknown values in
--! OnPermissionsChange notification
--! @parameters:
--! pPtuUpdateFunc - function with specific policy updates
--! self - test object
--! @return: none
--]]
local function checkCuttingUnknowValues(pPtuUpdateFunc, self)
  commonDefects.rai_ptu_n_without_OnPermissionsChange(1, pPtuUpdateFunc, self)
  self.mobileSession1:ExpectNotification("OnPermissionsChange")
  :Times(2)
  :ValidIf(function(exp, data)
      if exp.occurences == 2 then
        local isError = false
        local ErrorMessage = ""
        if #data.payload.permissionItem ~= 0 then
          for i = 1, #data.payload.permissionItem do
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
  :Do(function()
      if (commonSteps:file_exists(pathToPTS) == false) then
        self:FailTestCase(pathToPTS .. " is not created")
      else
        local pts = ptsToTable(pathToPTS)
        local parameters = pts.policy_table.functional_groupings.NewTestCaseGroup1.rpcs.GetVehicleData.parameters
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

--[[ @disallowedRPC: Unsuccessful processing of API with DISALLOWED status
--! @parameters:
--! RPC - RPC name
--! params - RPC params for mobile request
--! interface - interface of RPC on HMI
--! self - test object
--! @return: none
--]]
local function disallowedRPC(pRPC, pParams, pInterface, self)
  local cid = self.mobileSession1:SendRPC(pRPC, pParams)
  EXPECT_HMICALL(pInterface .. "." .. pRPC)
  :Times(0)
  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "DISALLOWED" })
  commonDefects.delayedExp()
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonDefects.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonDefects.start)

runner.Title("Test")
runner.Step("App registration, PTU, RPC with unknown parameter only", checkCuttingUnknowValues, { ptuUpdateFuncParams })

runner.Step("Check applying of PT by processing GetVehicleData", disallowedRPC,
  { "GetVehicleData", { gps = true }, "VehicleInfo" })

runner.Step("Remove Snapshot and trigger PTU, check new created PTS", removeSnapshotAndTriggerPTUFromHMI)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonDefects.postconditions)
