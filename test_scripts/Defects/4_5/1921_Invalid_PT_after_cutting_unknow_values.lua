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

--[[ Local Functions ]]
local CuttingUnknownStatus = false

--[[ Local Functions ]]
local function ptuUpdateFunc(tbl)
  local VDgroup = {
    rpcs = {
      GetVehicleData = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"},
        parameters = {"gps"}
      },
      SubscribeVehicleData = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"},
        newParameter = {"value"}
      },
      UnknownAPI = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"},
        parameters = {"gps"}
      },
      SendLocation = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}
      }
    }
  }
  tbl.policy_table.functional_groupings["NewTestCaseGroup"] = VDgroup
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID].groups =
  {"Base-4", "NewTestCaseGroup"}
end

local function NotValidPtuUpdateFunc(tbl)
  local VDgroup = {
    rpcs = {
      GetVehicleData = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"},
        parameters = {"gps"}
      },
      SubscribeVehicleData = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"},
        newParameter = {"value"}
      },
      UnknownAPI = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"},
        parameters = {"gps"}
      },
      SendLocation = {
        -- missed mandatory hmi_levels parameter
      }
    }
  }
  tbl.policy_table.functional_groupings["NewTestCaseGroup"] = VDgroup
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID].groups =
  {"Base-4", "NewTestCaseGroup"}
end

local function CheckCuttingUnknowValues(self)
  commonDefects.rai_ptu_n_without_OnPermissionsChange(1, ptuUpdateFunc,self)
  self.mobileSession1:ExpectNotification("OnPermissionsChange")
  :Times(2)
  :ValidIf(function(_,data)
      local ErrorStatus = false
      local ErrorMessage = ""
      if #data.payload.permissionItem ~= 0 then
        for i=1, #data.payload.permissionItem do
          if data.payload.permissionItem[i].rpcName == "UnknownAPI" then
            ErrorStatus = true
            CuttingUnknownStatus = true
            ErrorMessage = ErrorMessage .. " OnPermissionsChange contains unknown_RPC value.\n"
          end
          if data.payload.permissionItem[i].newParameter then
            ErrorStatus = true
            CuttingUnknownStatus = true
            ErrorMessage = ErrorMessage .. " OnPermissionsChange contains unknown_parameter value.\n"
          end
        end
      else
        ErrorStatus = true
        ErrorMessage = ErrorMessage .. "OnPermissionsChange is not contain permissionItem elements"
      end
      if ErrorStatus == true then
        return false, ErrorMessage
      else
        return true
      end
    end)
  commonFunctions:userPrint(33, "Check PTU content of PTU attempt in SDL log by message 'PTU content is'.\n"
    .. "'policy_table' must not contain 'newParameter' and 'UnknownAPI' values.")
end

local function InvalidPTAfterCutingUnknownValues(self)
  if CuttingUnknownStatus == true then
    self:FailTestCase("Unknown values are not cut from PT, so test case is not executed.")
  else
    commonDefects.UnsuccessPTU(NotValidPtuUpdateFunc,self)
    commonFunctions:userPrint(33, "Check PTU content of second PTU attempt in SDL log by message" ..
    " 'PTU content is'.\n'policy_table' must not contain 'newParameter' and 'UnknownAPI' values.")
  end
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonDefects.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonDefects.start)

runner.Title("Test")
runner.Step("Check_cutting_unknown_values_from_PT", CheckCuttingUnknowValues)
runner.Step("Invalid_PTU_after_cuting_unknown_values", InvalidPTAfterCutingUnknownValues)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonDefects.postconditions)

