---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/3
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/SetInteriorVehicleData.md
-- Item: Use Case 1: Exceptions: 4.1
--
-- Requirement summary:
-- [SDL_RC] Set available control module settings SetInteriorVehicleData
-- [SDL_RC] Policy support of basic RC functionality
--
-- Description:
-- In case:
-- 1) "moduleType" in app's assigned policies has one or more valid values
-- 2) and SDL received SetInteriorVehicleData request from App with moduleType not in list
-- SDL must:
-- 1) Disallow app's remote-control RPCs for this module (success:false, "DISALLOWED")
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

--[[ Local Variables ]]
local mod = "RADIO"

--[[ Local Functions ]]
local function setVehicleData(pModuleType, self)
  local cid = self.mobileSession:SendRPC("SetInteriorVehicleData", {
    moduleData = commonRC.getSettableModuleControlData(pModuleType)
  })

  EXPECT_HMICALL("RC.SetInteriorVehicleData")
  :Times(0)

  EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED" })

  commonTestCases:DelayedExp(commonRC.timeout)
end

local function ptu_update_func(tbl)
	tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID].moduleType = { "CLIMATE" }
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu, { ptu_update_func })
runner.Step("Activate App", commonRC.activate_app)

runner.Title("Test")
runner.Step("SetInteriorVehicleData " .. mod, setVehicleData, { mod })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
