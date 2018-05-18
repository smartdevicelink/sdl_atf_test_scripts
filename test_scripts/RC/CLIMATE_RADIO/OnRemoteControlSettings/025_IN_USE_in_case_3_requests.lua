---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/10
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/resource_allocation.md
-- Item: Use Case 1: Exception 2
--
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/9
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/button_press_emulation.md
-- Item: Use Case 1: Exception 1.5
--
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/3
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/SetInteriorVehicleData.md
-- Item: Use Case 1: Exception 6.1
--
-- Requirement summary:
-- [SDL_RC] Resource allocation based on access mode
--
-- Description: TRS: OnRemoteControlSettings, #3
-- In case:
-- 1) SDL received OnRemoteControlSettings notification from HMI with allowed:true
-- 2) and "accessMode" = "AUTO_ALLOW" or without "accessMode" parameter at all
-- 3) and RC_module on HMI is alreay in control by RC-application_1
-- 4) and RC_module is currently executing request by RC_application_1
-- 5) and another RC_application_2 in HMILevel LIMITED sends control RPC (either SetInteriorVehicleData or ButtonPress)
-- 6) and another RC_application_3 in HMILevel FULL sends control RPC (either SetInteriorVehicleData or ButtonPress)
-- SDL must:
-- 1) deny access to RC_module for RC_application_2, RC_application_3 without asking a driver
-- 2) not process the request from RC_application_2, RC_application_3 and respond with result code IN_USE, success:false
-- 3) leave RC_application_1 in control of the RC_module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')
local mobile_session = require("mobile_session")

--[[ Local Variables ]]
local modules = { "CLIMATE", "RADIO" }
local access_modes = { nil, "AUTO_ALLOW" }
local hmiAppIds = { }

local app1Params = config.application1.registerAppInterfaceParams
local app2Params = config.application2.registerAppInterfaceParams
local app3Params = config.application3.registerAppInterfaceParams

app1Params.isMediaApplication = false
app1Params.appHMIType = { "NAVIGATION", "REMOTE_CONTROL" }
app2Params.isMediaApplication = true
app2Params.appHMIType = { "DEFAULT", "REMOTE_CONTROL" }
app3Params.isMediaApplication = false
app3Params.appHMIType = { "DEFAULT", "REMOTE_CONTROL" }

--[[ Local Functions ]]
local function ptu_update_func(tbl)
  tbl.policy_table.app_policies[app1Params.appID].AppHMIType = app1Params.appHMIType
  tbl.policy_table.app_policies[app2Params.appID] = commonRC.getRCAppConfig()
  tbl.policy_table.app_policies[app2Params.appID].AppHMIType = app2Params.appHMIType
  tbl.policy_table.app_policies[app3Params.appID] = commonRC.getRCAppConfig()
  tbl.policy_table.app_policies[app3Params.appID].AppHMIType = app3Params.appHMIType
end

local function step(pModuleType, pRPC1, pRPC2, self)
  local cid1
  if pRPC1 == "SetInteriorVehicleData" then
    cid1 = self.mobileSession1:SendRPC("SetInteriorVehicleData", {
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
        RUN_AFTER(hmiRespond, 4000)
      end)
  elseif pRPC1 == "ButtonPress" then
    cid1 = self.mobileSession1:SendRPC("ButtonPress", {
      moduleType = pModuleType,
      buttonName = commonRC.getButtonNameByModule(pModuleType),
      buttonPressMode = "SHORT"
    })
    EXPECT_HMICALL("Buttons.ButtonPress", {
      appID = commonRC.getHMIAppId(1),
      moduleType = pModuleType,
      buttonName = commonRC.getButtonNameByModule(pModuleType),
      buttonPressMode = "SHORT"
    })
    :Do(function(_, data)
        local function hmiRespond()
          self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
        end
        RUN_AFTER(hmiRespond, 4000)
      end)
  end
  self.mobileSession1:ExpectResponse(cid1, { success = true, resultCode = "SUCCESS" })

  local req3_func = function()
    local cid3
    local pRPC3 = pRPC2
    if pRPC3 == "SetInteriorVehicleData" then
      cid3 = self.mobileSession3:SendRPC("SetInteriorVehicleData", {
        moduleData = commonRC.getSettableModuleControlData(pModuleType)
      })
    elseif pRPC3 == "ButtonPress" then
      cid3 = self.mobileSession3:SendRPC("ButtonPress", {
        moduleType = pModuleType,
        buttonName = commonRC.getButtonNameByModule(pModuleType),
        buttonPressMode = "SHORT"
      })
    end
    self.mobileSession3:ExpectResponse(cid3, { success = false, resultCode = "IN_USE" })
  end

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
    :Do(function()
      req3_func()
    end)
  end

  RUN_AFTER(req2_func, 1000)
end

local function rai_n(id, self)
  self, id = commonRC.getSelfAndParams(id, self)
  if not id then id = 1 end
  self["mobileSession" .. id] = mobile_session.MobileSession(self, self.mobileConnection)
  self["mobileSession" .. id]:StartService(7)
  :Do(function()
      local corId = self["mobileSession" .. id]:SendRPC("RegisterAppInterface",
        config["application" .. id].registerAppInterfaceParams)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
        { application = { appName = config["application" .. id].registerAppInterfaceParams.appName } })
      :Do(function(_, d1)
          hmiAppIds[config["application" .. id].registerAppInterfaceParams.appID] = d1.params.application.appID
        end)
      self["mobileSession" .. id]:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          self["mobileSession" .. id]:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          :Times(AtLeast(1)) -- issue with SDL --> notification is sent twice
          self["mobileSession" .. id]:ExpectNotification("OnPermissionsChange")
        end)
    end)
end

local function activate_app(pAppId, pOnHMIStatusFunc, self)
  self, pAppId = commonRC.getSelfAndParams(pAppId, self)
  if not pAppId then pAppId = 1 end
  local pHMIAppId = hmiAppIds[config["application" .. pAppId].registerAppInterfaceParams.appID]
  local mobSession = commonRC.getMobileSession(self, pAppId)
  local requestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = pHMIAppId })
  EXPECT_HMIRESPONSE(requestId)
  if not pOnHMIStatusFunc then
    mobSession:ExpectNotification("OnHMIStatus",
      { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
  else
    pOnHMIStatusFunc(self)
  end
end

local function OnHMIStatus2Apps(self)
  self.mobileSession2:ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
  self.mobileSession1:ExpectNotification("OnHMIStatus",
    { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
end

local function OnHMIStatus3Apps(self)
  self.mobileSession3:ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
  self.mobileSession1:ExpectNotification("OnHMIStatus")
  :Times(0)
  self.mobileSession2:ExpectNotification("OnHMIStatus",
    { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI1, PTU", commonRC.rai_ptu, { ptu_update_func })
runner.Step("Activate App1", commonRC.activate_app)
runner.Step("RAI2", rai_n, { 2 })
runner.Step("Activate App2", activate_app, { 2, OnHMIStatus2Apps })
runner.Step("RAI3", rai_n, { 3 })
runner.Step("Activate App3", activate_app, { 3, OnHMIStatus3Apps })

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
        runner.Step("App1 " .. rpc1 .. " App2_App3_" .. rpc2, step, { mod, rpc1, rpc2 })
      end
    end
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
