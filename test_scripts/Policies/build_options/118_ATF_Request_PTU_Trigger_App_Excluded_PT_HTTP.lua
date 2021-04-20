---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PolicyTableUpdate] Request PTU - an app registered is not listed in local PT

-- Description:
-- The policies manager must request an update to its local policy table
--when an appID of a registered app is not listed on the Local Policy Table.

-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- Connect mobile phone over WiFi.
-- Register new application.
-- Successful PTU.
-- 2. Performed steps
-- Register new application
--
-- Expected result:
-- PTU is requested. PTS is created.
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
-- SDL->HMI: BasicCommunication.PolicyUpdate
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "HTTP" } } })

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local json = require("modules/json")

--[[ Local variables]]
local ptu
local onsysrequest_app1 = false
local onsysrequest_app2 = false

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()
--TODO: Should be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')
local mobile_session = require('mobile_session')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test.Precondition_Wait()
  commonTestCases:DelayedExp(5000)
end

function Test:Precondition_HTTP_Successful_Flow ()
  testCasesForPolicyTable:flow_PTU_SUCCEESS_HTTP (self)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_StartNewSession()
  self.mobileSession1 = mobile_session.MobileSession( self, self.mobileConnection)
  self.mobileSession1:StartService(7)
end

function Test:TestStep_PTU_AppID_SecondApp_NotListed_PT()
  local correlationId = self.mobileSession1:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)

  self.mobileSession1:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS"})
  self.mobileSession1:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application2.registerAppInterfaceParams.appName } })
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status = "UPDATE_NEEDED" }, {status = "UPDATING"}):Times(2)

  self.mobileSession1:ExpectNotification("OnSystemRequest")
  :Do(function(_, data)
      print("SDL->MOB2: OnSystemRequest()", data.payload.requestType)
      if data.payload.requestType == "HTTP" then
        onsysrequest_app2 = true
        if(onsysrequest_app1 == true) then self:FailTestCase("OnSystemRequest(HTTP) for application 1 already received") end
        if(data.binaryData ~= nil and data.binaryData ~= "") then
          ptu = json.decode(data.binaryData)
        end
      end
    end)
  :Times(Between(0,1))

  self.mobileSession:ExpectNotification("OnSystemRequest")
  :Do(function(_, data)
      print("SDL->MOB1: OnSystemRequest()", data.payload.requestType)
      if data.payload.requestType == "HTTP" then
        onsysrequest_app1 = true
        if(onsysrequest_app2 == true) then self:FailTestCase("OnSystemRequest(HTTP) for application 2 already received") end
        if(data.binaryData ~= nil and data.binaryData ~= "") then
          ptu = json.decode(data.binaryData)
        end
      end
    end)
  :Times(Between(0,1))

  commonTestCases:DelayedExp(10000)
end

function Test:ValidatePTS()
  if(onsysrequest_app1 == false and onsysrequest_app2 == false) then
    self:FailTestCase("OnSystemRequest , requestType: HTTP is not received at all")
  end

  if(ptu == nil or ptu =="") then
    self:FailTestCase("Binary data is empty")
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test
