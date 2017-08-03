---------------------------------------------------------------------------------------------------
-- Requirement summary:
-- [SDL_RC] Resource allocation based on access mode
--
-- Description: TRS: OnRemoteControlSettings, #3
-- In case:
-- 1) SDL received OnRemoteControlSettings notification from HMI with allowed:true
-- 2) and "accessMode" = "AUTO_ALLOW" or without "accessMode" parameter at all
-- 3) and RC_module on HMI is alreay in control by RC-application_1
-- 4) and RC_module is currently executing request by RC_application_1
-- 5) and another RC_application_2 in HMILevel FULL sends control RPC (either SetInteriorVehicleData or ButtonPress)
-- SDL must:
-- 1) deny access to RC_module for RC_application_2 without asking a driver
-- 2) not process the request from RC_application_2 and respond with result code IN_USE, success:false
-- 3) leave RC_application_1 in control of the RC_module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Local Variables ]]
local modules = { "CLIMATE", "RADIO" }
local access_modes = { nil, "AUTO_ALLOW" }

--[[ Local Functions ]]
local function ptu_update_func(tbl)
  tbl.policy_table.app_policies[config.application2.registerAppInterfaceParams.appID] = commonRC.getRCAppConfig()
end

local function step(pModuleType, pRPC1, pRPC2, self)
  local cid1
  if pRPC1 == "SetInteriorVehicleData" then
    cid1 = self.mobileSession:SendRPC("SetInteriorVehicleData", {
      moduleData = commonRC.getSettableModuleControlData(pModuleType)
    })
    EXPECT_HMICALL("RC.SetInteriorVehicleData", {
      appID = self.applications["Test Application"],
      moduleData = commonRC.getSettableModuleControlData(pModuleType)
    })
    :Do(function(_, data)
        local function hmiRespond()
          self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
            moduleData = commonRC.getSettableModuleControlData(pModuleType)
          })
        end
        RUN_AFTER(hmiRespond, 2000)
      end)
  elseif pRPC1 == "ButtonPress" then
    cid1 = self.mobileSession:SendRPC("ButtonPress", {
      moduleType = pModuleType,
      buttonName = commonRC.getButtonNameByModule(pModuleType),
      buttonPressMode = "SHORT"
    })
    EXPECT_HMICALL("Buttons.ButtonPress", {
      appID = commonRC.getHMIAppId(self, 1),
      moduleType = pModuleType,
      buttonName = commonRC.getButtonNameByModule(pModuleType),
      buttonPressMode = "SHORT"
    })
    :Do(function(_, data)
        local function hmiRespond()
          self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
        end
        RUN_AFTER(hmiRespond, 2000)
      end)
  end
  self.mobileSession:ExpectResponse(cid1, { success = true, resultCode = "SUCCESS" })

  local req2_func = function()
    local cid2
    if pRPC2 == "SetInteriorVehicleData" then
      cid2 = self.mobileSession2:SendRPC("SetInteriorVehicleData", {
        moduleData = commonRC.getSettableModuleControlData(pModuleType)
      })
    elseif pRPC2 == "ButtonPress" then
      cid2 = self.mobileSession2:SendRPC("ButtonPress", {
        moduleType = pModuleType,
        buttonName = commonRC.getButtonNameByModule(pModuleType),
        buttonPressMode = "SHORT"
      })
    end
    self.mobileSession2:ExpectResponse(cid2, { success = false, resultCode = "IN_USE" })
  end

  RUN_AFTER(req2_func, 1000)
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

for _, mod in pairs(modules) do
  runner.Title("Module: " .. mod)
  -- set control for App1
  runner.Step("App1 SetInteriorVehicleData", commonRC.rpcAllowed, { mod, 1, "SetInteriorVehicleData" })
  for i = 1, #access_modes do
    runner.Title("Access mode: " .. tostring(access_modes[i]))
    -- set RA mode
    runner.Step("Set RA mode", commonRC.defineRAMode, { true, access_modes[i] })
    -- try to set control for App2 while request for App1 is executing
    local rpcs = { "SetInteriorVehicleData", "ButtonPress" }
    for _, rpc1 in pairs(rpcs) do
      for _, rpc2 in pairs(rpcs) do
        runner.Step("App1 " .. rpc1 .. " App2 " .. rpc2, step, { mod, rpc1, rpc2 })
      end
    end
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
