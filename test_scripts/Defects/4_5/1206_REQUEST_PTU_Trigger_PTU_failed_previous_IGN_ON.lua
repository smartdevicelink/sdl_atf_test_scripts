----------------------------------------------------------------------------------------------------
-- Script verifies issue https://github.com/SmartDeviceLink/sdl_core/issues/1206
-- Flow: HTTP, PROPRIETARY
----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require("user_modules/script_runner")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local mobile_session = require("mobile_session")
local common = require("test_scripts/Defects/4_5/commonDefects")
local color = require("user_modules/consts").color

--[[ General configuration parameters ]]
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "PROPRIETARY", "HTTP" } } }

--[[ Local Functions ]]
--[[ @registerApplicationAndWaitPTUStart: create mobile session, start RPC service, register mobile application
--! and check that 'SDL.OnStatusUpdate' notification is sent to HMI with 'UPDATE_NEEDED' status
--! @parameters:
--! self - test object which will be provided automatically by runner module
--! @return: none
--]]
local function registerApplicationAndWaitPTUStart(self)
  -- create mobile session
  self.mobileSession1 = mobile_session.MobileSession(self, self.mobileConnection)
  -- register expectation of 'SDL.OnStatusUpdate' notification on HMI connection
  -- it's expected that the value of 'status' argument will be 'UPDATE_NEEDED'
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status = "UPDATE_NEEDED" })
  :Do(function()
      -- print information about received notification to console
      commonFunctions:userPrint(color.blue, "Received OnStatusUpdate: UPDATE_NEEDED")
    end)
  -- start RPC service
  self.mobileSession1:StartService(7)
  :Do(function()
      -- send 'RegisterAppInterface' RPC with default parameters for mobile application
      -- and return correlation identifier
      local corId = self.mobileSession1:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      -- register expectation of response for 'RegisterAppInterface' request with appropriate correlation id
      -- on Mobile connection
      -- it's expected that request is processed successfully
      self.mobileSession1:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      -- register expectation of 'BC.OnAppRegistered' notification on HMI connection
      -- it's expected that the value of 'application.appName' argument will be equal to default application name
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {
        application = { appName = config.application1.registerAppInterfaceParams.appName }
      })
    end)
end

local function start(self)
  common.start(self)
  -- register expectation of 'SDL.OnStatusUpdate' notification on HMI connection
  -- it's expected that the value of 'status' argument will be 'UPDATE_NEEDED'
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status = "UPDATE_NEEDED" })
  :Do(function()
      -- print information about received notification to console
      commonFunctions:userPrint(color.blue, "Received OnStatusUpdate: UPDATE_NEEDED")
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile", common.start)
runner.Step("SDL Configuration", common.printSDLConfig)

runner.Title("Test")
runner.Step("Application Registration and wait for UPDATE_NEEDED", registerApplicationAndWaitPTUStart)
runner.Step("Ignition Off", common.ignitionOff)
runner.Step("Start SDL, HMI, connect Mobile and wait for UPDATE_NEEDED", start)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
