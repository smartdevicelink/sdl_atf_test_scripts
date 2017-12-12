---------------------------------------------------------------------------------------------
-- Script verifies issue https://github.com/SmartDeviceLink/sdl_core/issues/1206
-- Check that in state UPDATE_NEEDED after ignition cycle SDL will try to perform PolicyUpdate
---------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require("user_modules/script_runner")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local mobile_session = require("mobile_session")
local atf_logger = require("atf_logger")
local sdl = require("SDL")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local commonDefects = require("test_scripts/Defects/4_5/commonDefects")
local Color = require("user_modules/consts").color

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
config.defaultProtocolVersion = 2

--[[ Local Variables ]]
--[[ Local Functions ]]
local function preconditions()
    commonFunctions:SDLForceStop()
    commonSteps:DeletePolicyTable()
    commonSteps:DeleteLogsFiles()
end

local function registerApplicationAndWaitPTUStart(self)
    self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
    self.mobileSession:StartService(7):Do(function()
            local corId =self.mobileSession:SendRPC("RegisterAppInterface",
                                                    config.application1.registerAppInterfaceParams)

            self.mobileSession:ExpectResponse(corId, {success = true, resultCode = "SUCCESS"})

            EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
                                   {application = {appName = config.application1.registerAppInterfaceParams.appName}})
            EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"}):Do(function()
              commonFunctions:userPrint(Color.blue, "Received OnStatusUpdate:UPDATE_NEEDED")
            end)
        end)
end

function ignition_off(self)
    self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {reason = "SUSPEND"})
    EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete"):Do(
        function()
            self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {reason = "IGNITION_OFF"})
            self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", {reason = "IGNITION_OFF"})
            EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = false})
            EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose"):Do(function()
                  sdl:DeleteFile()
            end)
        end)
end

local function printSDLConfig()
    commonFunctions:printTable(sdl.buildOptions)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", preconditions)
runner.Step("Start SDL, HMI, connect Mobile", commonDefects.start)
runner.Step("SDL Configuration", printSDLConfig)

runner.Title("Test")
runner.Step("Application Registration and wait for UPDATE_NEEDED", registerApplicationAndWaitPTUStart)
runner.Step("Ignition Off", ignition_off)
runner.Step("Start SDL, HMI, connect Mobile", commonDefects.start)
runner.Step("Application Registration and wait for UPDATE_NEEDED", registerApplicationAndWaitPTUStart)


runner.Title("Postconditions")
runner.Step("Stop SDL", StopSDL)
