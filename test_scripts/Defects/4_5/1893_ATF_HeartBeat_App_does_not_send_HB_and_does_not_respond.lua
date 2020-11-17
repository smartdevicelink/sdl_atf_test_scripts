----------------------------------------------------------------------------------------------------
-- Script verifies issue https://github.com/SmartDeviceLink/sdl_core/issues/1893
-- Flow: PROPRIETARY
----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require("user_modules/script_runner")
local common = require("test_scripts/Defects/4_5/commonDefects")
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local mobile_session = require('mobile_session')
local events = require("events")

--[[ General Precondition before ATF start ]]
-- switch ATF to use 3rd version (with HeartBeat) of SDL protocol
config.defaultProtocolVersion = 3
-- define default application is Media one
config.application1.registerAppInterfaceParams.isMediaApplication = true

-- [[Local variables]]
-- array with default parameters for mobile applications
local appParams = {
  [1] = config.application1.registerAppInterfaceParams,
  [2] = config.application2.registerAppInterfaceParams
}
-- array to store HMI application identifiers
local hmiAppId = {}
-- array to store mobile sessions
local mobileSession = {}

--[[ Local Functions ]]

--[[ @updateINIFile: update parameters in SDL .ini file
--! @parameters: none
--! @return: none
--]]
local function updateINIFile()
  -- backup .ini file
  common.backupINIFile()
  -- change the value of 'HeartBeatTimeout' parameter
  commonFunctions:write_parameter_to_smart_device_link_ini("HeartBeatTimeout", 5000)
end

--[[ @connectMobile: create mobile connection
--! @parameters:
--! self - test object which will be provided automatically by runner module
--! @return: none
--]]
local function connectMobile(self)
  -- connect mobile device
  self.mobileConnection:Connect()
  -- register "Connected" expectation
  EXPECT_EVENT(events.connectedEvent, "Connected")
end

--[[ @Register_App: create mobile session, start RPC service and register mobile application
--! @parameters: none
--! appId - application number (1, 2, etc.)
--! answerHeartbeatFromSDL - if 'true' ATF will answer on heartbeat messages from SDL
--! self - test object which will be provided automatically by runner module
--! @return: none
--]]
local function Register_App(appId, answerHeartbeatFromSDL, self)
  -- create mobile session
  mobileSession[appId] = mobile_session.MobileSession(self, self.mobileConnection)
  -- set parameters for heartbeat
  mobileSession[appId].activateHeartbeat = true
  mobileSession[appId].sendHeartbeatToSDL = false
  mobileSession[appId].answerHeartbeatFromSDL = answerHeartbeatFromSDL
  mobileSession[appId].ignoreSDLHeartBeatACK = false
  -- start RPC service
  mobileSession[appId]:StartRPC()
  :Do(function()
      -- send 'RegisterAppInterface' RPC with defined parameters for mobile application
      -- and return correlation identifier
      local correlation_id = mobileSession[appId]:SendRPC("RegisterAppInterface", appParams[appId])
      -- register expectation of 'BC.OnAppRegistered' notification on HMI connection
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {
        application = { appName = appParams[appId].appName }
      })
      :Do(function(_,data)
          -- save HMI application Id: it will be required in next steps
          hmiAppId[appId] = data.params.application.appID
        end)
      -- register expectation of response for 'RegisterAppInterface' request with appropriate correlation id
      -- on Mobile connection
      mobileSession[appId]:ExpectResponse(correlation_id, { success = true, resultCode = "SUCCESS" })
      -- register expectation of 'OnHMIStatus' notification on Mobile connection
      -- it's expected that value of 'hmiLevel' parameter will be 'NONE'
      mobileSession[appId]:ExpectNotification("OnHMIStatus", {
        hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"
      })
      -- register expectation of 'OnPermissionsChange' notification on Mobile connection
      mobileSession[appId]:ExpectNotification("OnPermissionsChange", {})
    end)
end

--[[ @Wait_15_seconds_And_Verify_OnAppUnregistered: wait 15 sec and check if 1st application is unregistered
--! due to heartbeat timeout
--! @parameters: none
--! @return: none
--]]
local function Wait_15_seconds_And_Verify_OnAppUnregistered()
  -- register expectation of 'BC.OnAppUnregistered' notification on HMI connection
  -- it's expected that 1st application is unregistered with 'unexpectedDisconnect' = true
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { appID = hmiAppId[1], unexpectedDisconnect = true })
  -- increase default timeout for wait from 10s to 15s
  -- this is required in order to heartbeat timeout of SDL is run out
  -- and SDL is able to close session for 1st application
  :Timeout(15000)
  :Do(function()
      -- stop heartbeat (if it was started previously)
      mobileSession[1]:StopHeartbeat()
    end)
end

--[[ @Verify_That_Second_App_Still_Registered: verify that 2nd application is still registered
--! @parameters: none
--! @return: none
--]]
local function Verify_That_Second_App_Still_Registered()
  -- send 'RegisterAppInterface' RCP with defined parameters
  local cor_id = mobileSession[2]:SendRPC("RegisterAppInterface", appParams[2])
  -- register expectation that response will be unsuccessful with appropriate resultCode
  -- meaning session for 2nd application is still alive
  mobileSession[2]:ExpectResponse(cor_id, { success = false, resultCode = "APPLICATION_REGISTERED_ALREADY"})
end

--[[ @Stop_HB_2nd_App: stop heartbeat for 2nd app, wait 15 sec and check that 2nd application is unregistered
--! due to heartbeat timeout, also verify that mobile connection is not closed
--! @parameters: none
--! @return: none
--]]
local function Stop_HB_2nd_App()
  -- switch off heartbeat for 2nd application
  mobileSession[2].answerHeartbeatFromSDL = false
  mobileSession[2]:StopHeartbeat()
  -- register expectation of 'BC.OnAppUnregistered' notification on HMI connection
  -- it's expected that the application is unregistered with 'unexpectedDisconnect' = true
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { appID = hmiAppId[2], unexpectedDisconnect = true })
  -- increase default timeout for wait from 10s to 15s
  -- this is required in order to heartbeat timeout of SDL is run out
  -- and SDL is able to close session for application
  :Timeout(15000)
  -- register expectation that mobile connection won't be closed
  EXPECT_EVENT(events.disconnectedEvent, "Disconnected")
  :Times(0)
end

--[[ @Verify_That_New_Session_can_be_created: verify that new mobile session can be created on existing connection
--! @parameters:
--! self - test object which will be provided automatically by runner module
--! @return: none
--]]
local function Verify_That_New_Session_can_be_created(self)
  -- create mobile session
  mobileSession[3] = mobile_session.MobileSession(self, self.mobileConnection)
  -- set heartbeat options
  mobileSession[3].activateHeartbeat = false
  mobileSession[3].sendHeartbeatToSDL = false
  mobileSession[3].answerHeartbeatFromSDL = false
  mobileSession[3].ignoreSDLHeartBeatACK = false
  -- start RPC service
  mobileSession[3]:StartRPC()
end

-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update INI file", updateINIFile)
runner.Step("SDL Configuration", common.printSDLConfig)
runner.Step("Start SDL and HMI", common.startWithoutMobile)
runner.Step("Connect Mobile", connectMobile)

runner.Title("Test")
runner.Step("Register_1st_App_without_HeartBeat", Register_App, { 1, false })
runner.Step("Register_2nd_App_with_HeartBeat", Register_App, { 2, true })
runner.Step("Wait_15_seconds_And_Verify_OnAppUnregistered", Wait_15_seconds_And_Verify_OnAppUnregistered)
runner.Step("Verify_That_Second_App_Still_Registered", Verify_That_Second_App_Still_Registered)
runner.Step("Stop_HeartBeat_for_2nd_App_and_verify_that_connection_is_alive", Stop_HB_2nd_App)
runner.Step("Verify_That_New_Session_can_be_created", Verify_That_New_Session_can_be_created)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
runner.Step("Restore INI file", common.restoreINIFile)
