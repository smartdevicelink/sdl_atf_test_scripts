---------------------------------------------------------------------------------------------
-- GitHub issue: https://github.com/SmartDeviceLink/sdl_core/issues/1881
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonDefects = require('test_scripts/Defects/4_5/commonDefects')
local mobile_session = require("mobile_session")

--[[ Test Configuration ]]
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "PROPRIETARY", "EXTERNAL_PROPRIETARY" } } }

--[[ Local Variables ]]
config.application1.registerAppInterfaceParams.isMediaApplication = true
config.application1.registerAppInterfaceParams.appHMIType = {"DEFAULT"}
config.application2.registerAppInterfaceParams.isMediaApplication = false
config.application2.registerAppInterfaceParams.appHMIType = {"DEFAULT"}

--[[ Local Functions ]]
-- Prepare policy table for policy table update
-- @tparam table tbl table to update
local function ptUpdateFunc(pTbl)
  -- make sure that OnDriverDistraction is disallowed in HMILevel NONE
  pTbl.policy_table.functional_groupings["Base-4"].rpcs["OnDriverDistraction"].hmi_levels = {
    "FULL",
    "LIMITED",
    "BACKGROUND"
  }
end


--! @OnDDinNONE: Processing OnDriverDistraction notification with expectations 0 times
--! @parameters:
--! id - id of session,
--! params - parameters for OnDriverDistraction request
--! self - test object
--! @return: none
local function OnDDinNONE(id, params, self)
  -- Send OnDriverDistraction request from mobile app
  self.hmiConnection:SendNotification("UI.OnDriverDistraction", params)
  -- Expect 0 OnDriverDistraction notifications on mobile side means does not receive notification
  self["mobileSession" .. id]:ExpectNotification("OnDriverDistraction")
  :Times(0)
  -- Delay in 2 sec
  commonDefects.delayedExp(2000)
end

--! @OnDD: Successful processing OnDriverDistraction
--! @parameters:
--! id - id of session,
--! params - parameters for OnDriverDistraction request
--! self - test object
--! @return: none
local function OnDD(id, params, self)
  -- Send OnDriverDistraction notification from mobile side
  self.hmiConnection:SendNotification("UI.OnDriverDistraction", params)
  -- Expect OnDriverDistraction notification on mobile app
  self["mobileSession" .. id]:ExpectNotification("OnDriverDistraction", params)
end

--! @OnDD2Apps: Successful processing OnDriverDistraction on one session and expect 0 times on second session
--! @parameters:
--! idres - id of session for expectation notification,
--! id - id of session,
--! params - parameters for OnDriverDistraction request
--! self - test object
--! @return: none
local function OnDD2Apps(idres, id, params, self)
  -- Send OnDriverDistraction notification from mobile application
  self.hmiConnection:SendNotification("UI.OnDriverDistraction", params)
  -- Expect 0 notifications on mobile app
  self["mobileSession" .. id]:ExpectNotification("OnDriverDistraction")
  :Times(0)
  -- Expect notification on mobile app
  self["mobileSession" .. idres]:ExpectNotification("OnDriverDistraction", params)
  commonDefects.delayedExp(2000)
end

--! @ActivationAppWithOnDD: Receiving OnDriverDistraction notification right after activation with one application
--! @parameters:
--! params - parameters for OnDriverDistraction request
--! self - test object
--! @return: none
local function ActivationAppWithOnDD( params, self)
  -- Get HMI id of first application
  local hmiAppId = commonDefects.getHMIAppId(1)
  -- Sent ActivateApp request from HMI to SDL
  local requestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = hmiAppId })
  -- Expect ActivateApp response on HMI
  EXPECT_HMIRESPONSE(requestId)
  -- Expect OnHMIStatus notification on mobile app
  self.mobileSession1:ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
  -- Expect OnDriverDistraction notification on mobile app
  self.mobileSession1:ExpectNotification("OnDriverDistraction", params)
end

--! @RegisterAppWithOnDDResumption: Receiving OnDriverDistraction right after resume app in Limited HMI level
--! @parameters:
--! params - parameters for OnDriverDistraction request
--! self - test object
--! @return: none
local function RegisterAppWithOnDDResumption( params, self)
  -- Open mobile session
  self.mobileSession1 = mobile_session.MobileSession(self, self.mobileConnection)
  -- Open RPC service in created session
  self.mobileSession1:StartService(7)
  :Do(function()
      -- Send RegisterAppInterface request from mobile app
      local corId = self.mobileSession1:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      -- Expect OnAppRegistered notification on HMI side
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
        { application = { appName = config.application1.registerAppInterfaceParams.appName } })
      -- Expect successful RegisterAppInterface response on mobile side from SDL
      self.mobileSession1:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          -- Expect 2 OnHMIStatus notifications on mobile app,
          -- first one with hmiLevel = "NONE", second one with hmiLevel = "LIMITED"
          self.mobileSession1:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE" },
            { hmiLevel = "LIMITED" })
          :Times(2)
          -- Expect OnPermissionsChange notification on mobile side from SDL with applied permissions
          self.mobileSession1:ExpectNotification("OnPermissionsChange")
          -- Expect 0 OnDriverDistraction notifications on second mobile application
          self.mobileSession2:ExpectNotification("OnDriverDistraction")
          :Times(0)
          -- Expect ExpectNotification notification on first mobile app
          self.mobileSession1:ExpectNotification("OnDriverDistraction", params)
          commonDefects.delayedExp(1000)
        end)
    end)
end

--! @ActivationAppWithOnDD2Apps: Receiving OnDriverDistraction notification right after activation with two applications
--! @parameters:
--! params - parameters for OnDriverDistraction request
--! self - test object
--! @return: none
local function ActivationAppWithOnDD2Apps( params, self)
  -- Get HMI id of second registered application
  local hmiAppId = commonDefects.getHMIAppId(2)
  -- Send request ActivateApp from HMI for activation second app
  local requestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = hmiAppId })
  -- Expect ActivateApp response on HMI side
  EXPECT_HMIRESPONSE(requestId)
  -- Expect OnHMIStatus notification with hmiLevel = "FULL" on second mobile application
  self.mobileSession2:ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL"})
  -- Expect OnDriverDistraction notification on second mobile application
  self.mobileSession2:ExpectNotification("OnDriverDistraction", params)
  -- Expect 0 OnDriverDistraction notifications on first mobile application
  self.mobileSession1:ExpectNotification("OnDriverDistraction")
  :Times(0)
  -- Expect OnHMIStatus on first mobile app with hmiLevel = "LIMITED"
  self.mobileSession1:ExpectNotification("OnHMIStatus",
    { hmiLevel = "LIMITED"})
  commonDefects.delayedExp(1000)
end

--! @CloseSession: Closing first session
--! @parameters:
--! self - test object
--! @return: none
local function CloseSession(self)
  self.mobileSession1:Stop()
end

--[[ Scenario ]]
runner.Title("Preconditions")
-- Stop SDL if process is still running, delete local policy table and log files
runner.Step("Clean environment", commonDefects.preconditions)
-- Start SDL and HMI, establish connection between SDL and HMI, open mobile connection via TCP and create mobile session
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonDefects.start)
-- Register application, perform PTU
runner.Step("RAI, PTU", commonDefects.rai_ptu, {ptUpdateFunc})

runner.Title("Test")
-- Absence of OnDriverDistraction notification on mobile app in NONE HMI level
runner.Step("Absence_OnDriverDistraction_in_NONE", OnDDinNONE, {1, {state = "DD_ON"}})
-- Receiving OnDriverDistraction notification on mobile app in FULL HMI level
runner.Step("OnDriverDistraction_in_FULL", ActivationAppWithOnDD, {{state = "DD_ON"}})
runner.Step("UnregisterRegisterApp", commonDefects.unregisterApp, {1})

-- Register first application
runner.Step("RAI_first_app", commonDefects.rai_n, {1, false})
-- Register second application
runner.Step("RAI_second_app", commonDefects.rai_ptu_n, {2, ptUpdateFunc})
-- Activate first application
runner.Step("Activate_first_app", commonDefects.activate_app)
-- Receiving OnDriverDistraction notification on mobile app with FULL HMI level
-- and check absence notification on second mobile application with NONE HMI level
runner.Step("OnDriverDistraction_in_FULL_ansence_in_NONE", OnDD2Apps, {1, 2, {state = "DD_ON"}})
-- Receiving OnDriverDistraction notification on mobile app with FULL HMI level
-- and check absence notification on second mobile application with NONE HMI level by changing DriverDistraction status
runner.Step("OnDriverDistraction_changed_in_FULL_ansence_in_NONE", OnDD2Apps, {1, 2, {state = "DD_OFF"}})
-- Receiving OnDriverDistraction notification on mobile app after activation
runner.Step("OnDriverDistraction_after_app_activation", ActivationAppWithOnDD2Apps, {{state = "DD_OFF"}})

-- Close first session
runner.Step("CloseSession", CloseSession)
-- Change DriverDistraction status and check receiving of OnDriverDistraction notification on mobile app in FULL level
runner.Step("OnDriverDistraction_change_in_FULL", OnDD, {2, {state = "DD_ON"}})
-- Receiving OnDriverDistraction notification on mobile app in LIMITED HMI level after changing HMI status from NONE
runner.Step("OnDriverDistraction_in_LIMITED_after_resumption", RegisterAppWithOnDDResumption, {{state = "DD_ON"}})

runner.Title("Postconditions")
runner.Step("Stop SDL", commonDefects.postconditions)
