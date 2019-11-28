---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2442
--
-- Description:
-- The root cause of the issue is a stack overflow which is occurring due to recursive call of deeply nested areas
-- and objects. We have readValue(..) which calls readObject(..) or readArray(..), which call readValue(...).
-- Steps to reproduce:
-- 1) SDL and HMI are started
-- 2) App1 is registered and triggered PTU
-- 3) Json file with 50 nestings for PTU, PTU is performed successful
-- 4) App2 is registered and triggered PTU
-- 5) Json file with 51 nestings for PTU
-- SDL does:
-- - a) Ignore json file
-- - b) PTU is performed unsuccessful
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

 -- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- --  [[ Local Functions ]]
local function pTUpdateFunc1(tbl)
  local Group = {
    rpcs = {
      Data = {
        hmi_levels = {
          {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l =
          {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l =
          {l50nestings = {"FULL"}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
        }
      }
    }
  }
  tbl.policy_table.functional_groupings["Group"] = Group
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].groups = {"Base-4", "Group"}
end

local function pTUpdateFunc2(tbl)
  local Group = {
    rpcs = {
      Data2 = {
        hmi_levels = {
          {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l =
          {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l = {l =
          {l = {l51nestings = {"FULL"}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
        }
      }
    }
  }
  tbl.policy_table.functional_groupings["Group"] = Group
  tbl.policy_table.app_policies[config.application2.registerAppInterfaceParams.fullAppID].groups = {"Base-4", "Group"}
end

local function expNotificationFunc()
  common.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate",
    { status = "UPDATING" }, { status = "UPDATE_NEEDED" })
  :Times(2)
end

runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App1", common.registerApp, { 1 })
runner.Step("PTU, json with 50 nestings", common.policyTableUpdate, { pTUpdateFunc1 })

runner.Title("Test")
runner.Step("Register App2", common.registerApp, { 2 })
runner.Step("PTU, json with 51 nestings", common.policyTableUpdate, { pTUpdateFunc2, expNotificationFunc })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
