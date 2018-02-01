--  Requirement summary:
--  [RegisterAppInterface] SUCCESS
--  [RegisterAppInterface] RegisterAppInterface and HMILevel
--
--  Description:
--  Check that it is able to register up to 5 Apps on different connections via one transport.
--
--  1. Used precondition
--  SDL, HMI are running on system.
--
--  2. Performed steps
--  1st mobile device connect to system
--  appID_1->RegisterAppInterface(params)
--  2nd mobile device connect to system
--  appID_2->RegisterAppInterface(params)
--  3rd mobile device connect to system
--  appID_3->RegisterAppInterface(params)
--  4th mobile device connect to system
--  appID_4->RegisterAppInterface(params)
--  5th mobile device connect to system
--  appID_5->RegisterAppInterface(params)
--
--  Expected behavior:
--  1. SDL successfully registers all five applications and notifies HMI and mobile
--     SDL->HMI: OnAppRegistered(params)
--     SDL->appID: SUCCESS, success:"true":RegisterAppInterface()
--  2. SDL assignes HMILevel after application registering:
--     SDL->appID: OnHMIStatus(HMlLevel, audioStreamingState, systemContext)
---------------------------------------------------------------------------------------------------
--[[ General Precondition before ATF start ]]
config.defaultProtocolVersion = 2

-- [[ Required Shared Libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')
local events = require("events")

--[[ General Settings for configuration ]]
Test = require('user_modules/dummy_connecttest')
require('cardinalities')
require('user_modules/AppTypes')

-- [[Local variables]]
local devicePort = 12345

local devices = {
  "127.0.0.1",
  "192.168.100.199",
  "10.42.0.1",
  "1.0.0.1",
  "8.8.8.8"
}

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
commonSteps:DeletePolicyTable()
commonSteps:DeleteLogsFiles()

local function createConnectionAndRegisterApp(self, device, filename, app)
  local tcpConnection = tcp.Connection(device, devicePort)
  local fileConnection = file_connection.FileConnection(filename, tcpConnection)
  self.mobileConnection = mobile.MobileConnection(fileConnection)
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection, app)
  event_dispatcher:AddConnection(self.mobileConnection)
  self.mobileSession:ExpectEvent(events.connectedEvent, "Connection started")
  self.mobileConnection:Connect()
  self.mobileSession:StartService(7):Do(function()
    local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", app)
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appName = app.appName}})
    self.mobileSession:ExpectResponse(correlationId , { success = true, resultCode = "SUCCESS"})
    self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "NONE",
          audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}):Do(function()
      commonFunctions:userPrint(35, "App is successfully registered")
    end)
  end)
end

function Test.CreateDummyConections()
  for i = 1, 4 do
    os.execute("ifconfig lo:" .. i .." " .. devices[i + 1])
  end
end

function Test:Start_SDL()
  self:runSDL()
  commonFunctions:waitForSDLStart(self):Do(function()
    self:initHMI():Do(function()
      commonFunctions:userPrint(35, "HMI initialized")
      self:initHMI_onReady():Do(function()
        commonFunctions:userPrint(35, "HMI is ready")
      end)
    end)
  end)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

for i = 1, 5 do
  Test["CreateConnection_" .. i] = function(self)
    local filename = "mobile" .. i .. ".out"
    local app = config["application"..i].registerAppInterfaceParams
    createConnectionAndRegisterApp(self, devices[i], filename, app)
  end
end
-- [[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postcondition")
function Test.Stop_SDL()
  StopSDL()
end

function Test.ShutDownDummyConnections()
  for i = 1, 4 do
    os.execute("ifconfig lo:" .. i .." down")
  end
end

function Test.CleanTemporaryFiles()
  for i = 1, 5 do
    os.execute("rm -f " .. "mobile" .. i .. ".out")
  end
end

return Test
