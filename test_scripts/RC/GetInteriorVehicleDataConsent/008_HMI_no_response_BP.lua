---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/10
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/resource_allocation.md
-- Item: Use Case 1: Exception 2.1
--
-- Requirement summary:
-- [SDL_RC] Resource allocation based on access mode
--
-- Description: TRS: OnRemoteControlSettings, #5; TRS: GetInteriorVehicleDataConsent, #3
-- In case:
-- 1) SDL received OnRemoteControlSettings notification from HMI with "ASK_DRIVER" access mode
-- 2) and RC application (in HMILevel FULL) requested access to remote control module
-- that is already allocated to another RC application
-- 3) and SDL requested user consent from HMI via GetInteriorVehicleDataConsent
-- 4) and HMI did not respond during default timeout or response is invalid or erroneous
-- SDL must:
-- 1) respond on control request to RC application with result code GENERIC_ERROR, success:false
-- 2) not allocate access for remote control module to the requested application
-- (meaning SDL must leave control of remote control module without changes)
-- Note: SDL must initiate user prompt in case of consequent control request for the same module from this application
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')
local commonTestCases = require("user_modules/shared_testcases/commonTestCases")

--[[ Local Variables ]]
local modules = { "CLIMATE", "RADIO" }

--[[ Local Functions ]]
local function ptu_update_func(tbl)
  tbl.policy_table.app_policies[config.application2.registerAppInterfaceParams.appID] = commonRC.getRCAppConfig()
end

local function rpcNoHMIResponse(pModuleType, pAppId, pRPC, self)
  local consentRPC = "GetInteriorVehicleDataConsent"
  local mobSession = commonRC.getMobileSession(self, pAppId)
  local cid = mobSession:SendRPC(commonRC.getAppEventName(pRPC), commonRC.getAppRequestParams(pRPC, pModuleType))
  EXPECT_HMICALL(commonRC.getHMIEventName(consentRPC), commonRC.getHMIRequestParams(consentRPC, pModuleType, pAppId))
  :Do(function(_, _)
      -- HMI does not respond
      EXPECT_HMICALL(commonRC.getHMIEventName(pRPC)):Times(0)
    end)
  mobSession:ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
  commonTestCases:DelayedExp(11000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI1, PTU", commonRC.rai_ptu, { ptu_update_func })
runner.Step("Activate App1", commonRC.activate_app)
runner.Step("RAI2", commonRC.rai_n, { 2 })
runner.Step("Activate App2", commonRC.activate_app, { 2 })

runner.Title("Test")
runner.Step("Set RA mode: ASK_DRIVER", commonRC.defineRAMode, { true, "ASK_DRIVER" })

for _, mod in pairs(modules) do
  runner.Title("Module: " .. mod)
  -- set control for App1
  runner.Step("App1 SetInteriorVehicleData", commonRC.rpcAllowed, { mod, 1, "SetInteriorVehicleData" })
  -- set control for App2 --> Ask driver --> HMI: doesn't respond
  runner.Step("App2 ButtonPress 1st GENERIC_ERROR", rpcNoHMIResponse, { mod, 2, "ButtonPress" })
  runner.Step("App2 ButtonPress 2nd SUCCESS", commonRC.rpcAllowedWithConsent, { mod, 2, "ButtonPress" })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
