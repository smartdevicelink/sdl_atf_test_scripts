---------------------------------------------------------------------------------------------------
-- Requirement summary:
-- [SDL_RC] Resource allocation based on access mode
--
-- Sequence:
-- 1) 3 REMOTE_CONTROL Apps are registered (App_1, App_2, App_3)
-- 2) Access mode: ASK_DRIVER
-- 3) App_1 takes control for <module>
-- 4) App_2 is activated (FULL)
-- 5) App_2->SDL: <RC_control_RPC> for <module>
-- 6) SDL->HMI: GetInteriorVehicleDataConsent (App_2)
-- 7) HMI doesn't respond for GetInteriorVehicleDataConsent (App_2)
-- 8) App_3 is activated (FULL)
-- 9) App_3->SDL: <RC_control_RPC> request for <module>
-- 10) SDL->App_3: IN_USE: <RC_control_RPC> (success:false)
-- 11) SDL doesn't send GetInteriorVehicleDataConsent (App_3)
-- 12) HMI->SDL: GetInteriorVehicleDataConsent (App_2, allowed:true)
-- 13) SDL->HMI: RC.SetInteriorVehicleData (App_2)
-- 14) HMI->SDL: SUCCESS: RC.SetInteriorVehicleData (App_2)
-- 15) SDL->App_2: SUCCESS: SetInteriorVehicleData
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.application3.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Local Variables ]]
local pModuleType = "CLIMATE"
local pRPC1 = "SetInteriorVehicleData"
local pRPC2 = "ButtonPress"

--[[ Local Functions ]]
local function ptu_update_func(tbl)
  tbl.policy_table.app_policies[config.application2.registerAppInterfaceParams.appID] = commonRC.getRCAppConfig()
  tbl.policy_table.app_policies[config.application3.registerAppInterfaceParams.appID] = commonRC.getRCAppConfig()
end

local function step(self)
  local cid1 = self.mobileSession2:SendRPC(commonRC.getAppEventName(pRPC1), commonRC.getAppRequestParams(pRPC1, pModuleType))
  local consentRPC = "GetInteriorVehicleDataConsent"
  EXPECT_HMICALL(commonRC.getHMIEventName(consentRPC), commonRC.getHMIRequestParams(consentRPC, pModuleType, 2, self))
  :Do(function(_, data)
      local function hmiRespond()
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", commonRC.getHMIResponseParams(consentRPC, true))
        EXPECT_HMICALL(commonRC.getHMIEventName(pRPC1), commonRC.getHMIRequestParams(pRPC1, pModuleType, 2, self))
        :Do(function(_, data2)
            self.hmiConnection:SendResponse(data2.id, data2.method, "SUCCESS", commonRC.getHMIResponseParams(pRPC1, pModuleType))
          end)
      end
      RUN_AFTER(hmiRespond, 2000)
    end)
  :Do(function(_, data)
      print("GetInteriorVehicleDataConsent - AppID: " .. data.params.appID)
    end)
  self.mobileSession2:ExpectResponse(cid1, { success = true, resultCode = "SUCCESS" })

  local req2_func = function()
    commonRC.activate_app(3, self)
    local cid2 = self.mobileSession3:SendRPC(commonRC.getAppEventName(pRPC2), commonRC.getAppRequestParams(pRPC2, pModuleType))
    self.mobileSession3:ExpectResponse(cid2, { success = false, resultCode = "IN_USE" })
  end

  RUN_AFTER(req2_func, 1000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI1, PTU", commonRC.rai_ptu, { ptu_update_func })
runner.Step("RAI2", commonRC.rai_n, { 2 })
runner.Step("RAI3", commonRC.rai_n, { 3 })
runner.Step("Activate App1", commonRC.activate_app)

runner.Title("Test")
runner.Step("Set RA mode: ASK_DRIVER", commonRC.defineRAMode, { true, "ASK_DRIVER" })

runner.Step("App1 SetInteriorVehicleData", commonRC.rpcAllowed, { pModuleType, 1, "SetInteriorVehicleData" })

runner.Step("Activate App2", commonRC.activate_app, { 2 })
runner.Step("Step", step)

-- for _, mod in pairs(modules) do
--   runner.Title("Module: " .. mod)
--   -- set control for App1
--   runner.Step("App1 SetInteriorVehicleData", commonRC.rpcAllowed, { mod, 1, "SetInteriorVehicleData" })
--   for i = 1, #access_modes do
--     runner.Title("Access mode: " .. tostring(access_modes[i]))
--     -- set RA mode
--     runner.Step("Set RA mode", commonRC.defineRAMode, { true, access_modes[i] })
--     -- try to set control for App2 while request for App1 is executing
--     local rpcs = { "SetInteriorVehicleData", "ButtonPress" }
--     for _, rpc1 in pairs(rpcs) do
--       for _, rpc2 in pairs(rpcs) do
--         runner.Step("App1 " .. rpc1 .. " App2 " .. rpc2, step, { mod, rpc1, rpc2 })
--       end
--     end
--   end
-- end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
