---------------------------------------------------------------------------------------------------
-- Script verifies issue https://github.com/SmartDeviceLink/sdl_core/issues/1395
-- Script verifies SUSPEND -> OnSDLAwake -> SUSPEND -> IGN_OFF sequence for resumption data saving
-- Precondition:
-- 1. SDL and HMI are started.
-- 2. App is registered.
-- Steps:
-- 1. Send AddCommand and check that OnHashChanged() notification is sent to mobile.
-- 2. Send BC.OnExitAllApplications(SUSPEND) and check that OnHashChanged() notification
-- is not sent to mobile when new data are added.
-- 3. Send BasicCommunication.OnAwakeSDL and check that OnHashChanged() notification is sent to mobile.
-- 4. Perform IGN_OFF - IGN_ON cycle and check resumption of persistent data and HMI Level

---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local mobile_session = require("mobile_session")
local common = require('test_scripts/Defects/4_5/commonDefects')
local sdl = require('SDL')

--[[ Test Configuration ]]
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "PROPRIETARY", "EXTERNAL_PROPRIETARY" } } }

--[[ Local Variables ]]

--[[ Local Functions ]]
-- Successful processing AddCommand request from mobile app
local function AddCommand(self)
  -- Send AddCommand request from HMI
  self.mobileSession1:SendRPC("AddCommand", { cmdID = 1, vrCommands = {"VRCommand1"}})
  -- Expect VR.AddCommand request on HMI from SDL
  EXPECT_HMICALL("VR.AddCommand"):Do(function(_, data)
      -- Sending VR.AddCommand response from HMI to SDL with resultCode SUCCESS
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  -- Expect successful AddCommand response on mobile side from SDL
  self.mobileSession1:ExpectResponse("AddCommand", { success = true, resultCode = "SUCCESS" })
  -- Expect OnHashChange notification on mobile side from SDL
  self.mobileSession1:ExpectNotification("OnHashChange")
end

-- Successful processing AddCommand request from mobile app after OnExitAllApplications(SUSPEND) notification from HMI
local function AddCommandAfterSUSPEND(self)
  -- Send OnExitAllApplications(SUSPEND) from HMI to SDL
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  -- Send AddCommand request from mobile side to SDL
  self.mobileSession1:SendRPC("AddCommand", { cmdID = 2, vrCommands = {"VRCommand2"}})
  -- Expect "VR.AddCommand" request on HMI side from SDL
  EXPECT_HMICALL("VR.AddCommand"):Do(function(_, data)
      -- Send VR.AddCommand response from HMI to SDL with resultCode SUCCESS
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  -- Expect successful response AddCommand on mobile side from SDL
  self.mobileSession1:ExpectResponse("AddCommand", { success = true, resultCode = "SUCCESS" })
  -- Expect OnSDLPersistenceComplete notification on HMI side
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
  -- Expect 0 times of receiving OnHashChange notification on mobile side
  self.mobileSession1:ExpectNotification("OnHashChange"):Times(0)
  -- Delay in 3 sec to make sure in absence of OnHashChange notification
  common.delayedExp(3000)
end

-- OnAwakeSDL notification from HMI
local function OnAwakeSDL(self)
  -- Send OnAwakeSDL notification from HMI
  self.hmiConnection:SendNotification("BasicCommunication.OnAwakeSDL",{})
  -- Expect OnHashChange notification on HMI side
  self.mobileSession1:ExpectNotification("OnHashChange"):Do(function(_, data)
      -- Write hashID to self.currentHashID
      self.currentHashID = data.payload.hashID
    end)
end

-- Data resumption
local function expectResumeData(self)
  -- Expect 2 VR.AddCommand requests on HMI side
  local on_vr_commands_added = EXPECT_HMICALL("VR.AddCommand"):Do(function(_,data)
      -- Send response VR.AddCommand from HMI with resultCode SUCCESS
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS")
      end):Times(2)
    on_vr_commands_added:ValidIf(function(_, data)
        -- Check parameters of received HMI requests
        if (data.params.type == "Command" and (data.params.cmdID == 1 or data.params.cmdID == 2)) then
          if (data.params.appID == config.application1.registerAppInterfaceParams.hmi_app_id) then
            return true
          else
            return false, "Received the same notification or App is registered with wrong appID"
          end
        end
      end)
    -- Expect OnHashChange notification on mobile side
    self.mobileSession1:ExpectNotification("OnHashChange")
  end

  -- Register application with resumption data
  local function registerAppAndResumeData(self)
    -- Create mobile session
    self.mobileSession1 = mobile_session.MobileSession(self, self.mobileConnection)
    -- Open RPC service in created session
    self.mobileSession1:StartService(7):Do(function()
        -- Write actual hashID value in params for app registration to perform resumption
        config.application1.registerAppInterfaceParams.hashID = self.currentHashID
        -- resumption of AddCommand
        expectResumeData(self)
        -- Send request RegisterAppInterface from mobile side
        local corId = self.mobileSession1:SendRPC("RegisterAppInterface",
          config.application1.registerAppInterfaceParams)
        -- expect OnAppRegistered notification on HMI from SDL
        EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
          { application = { appName = config.application1.registerAppInterfaceParams.appName }}):Do(function(_, data)
            config.application1.registerAppInterfaceParams.hmi_app_id = data.params.application.appID
          end)
        -- Expect successful RegisterAppInterface response on mobile side from SDL
        self.mobileSession1:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
        -- Expect ActivateApp request on HMI from SDL
        EXPECT_HMICALL("BasicCommunication.ActivateApp",
          {appID = config.application1.registerAppInterfaceParams.hmi_app_id}):Do(function(_,data)
            -- Send ActivateApp response from HMI to SDL
            self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
          end)
        -- Expect 2 notifications OnHMIStatus, first with hmiLevel=NONE, second one with hmiLevel=FULL
        self.mobileSession1:ExpectNotification("OnHMIStatus",
          {hmiLevel = "NONE", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"},
          {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}):Times(2)
      end)
  end

  --[[ Scenario ]]
  runner.Title("Preconditions")
  -- Stop SDL if process is still running, delete local policy table and log files
  runner.Step("Clean environment", common.preconditions)
  -- Start SDL and HMI, establish connection between SDL and HMI, open mobile connection via TCP
  -- and create mobile session
  runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  -- Register application and perform PTU
  runner.Step("RAI, PTU", common.rai_ptu)
  runner.Step("Activate App", common.activate_app)

  runner.Title("Test")
  -- Add command after application registration
  runner.Step("Add Command", AddCommand)
  -- Successful processing AddCommand after SUSPEND
  runner.Step("Add Command After SUSPEND", AddCommandAfterSUSPEND)
  -- OnAwakeSDL notification from HMI
  runner.Step("Send OnAwakeSDL", OnAwakeSDL)
  runner.Step("IGNITION_OFF", common.ignitionOff)
  -- Start SDL and HMI, establish connection between SDL and HMI, open mobile connection via TCP
  -- and create mobile session
  runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  -- Register application process resumption data
  runner.Step("Register App And Resume Data", registerAppAndResumeData)

  runner.Title("Postconditions")
  runner.Step("Stop SDL", common.postconditions)
