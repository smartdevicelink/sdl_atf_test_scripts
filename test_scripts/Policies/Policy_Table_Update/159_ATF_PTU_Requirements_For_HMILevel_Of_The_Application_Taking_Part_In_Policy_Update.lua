---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PolicyTableUpdate] Requirements for HMILevel of the application(s) taking part in Policy Update
--
-- Description:
-- Policies Manager must randomly select the application through which to send the policy table packet
-- and request an update to its local policy table only through apps with HMI status of BACKGROUND, LIMITED, and FULL.
-- If there are no mobile apps with any of these statuses, the system must use an app with an HMI Level of NONE.
--
-- Preconditions:
-- 1. Register 4 apps and set different HMILevel for each
-- app_1: NONE, app_2: LIMITED, app_3: BACKGROUND, app_4: FULL
-- Steps:
-- 1. Trigger PTU
-- 2. Verify which app was selected to send OnSystemRequest() notification
--
-- Expected result:
-- SDL choose between the app_2, app_3, app_4 randomly to send OnSystemRequest
-- app_1 doesn't take part in PTU (except of the case when app_1 is the only application being run on SDL)
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local mobileSession = require("mobile_session")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local testCasesForPolicyTable = require("user_modules/shared_testcases/testCasesForPolicyTable")
local commonTestCases = require("user_modules/shared_testcases/commonTestCases")
local utils = require ('user_modules/utils')

--[[ Local Variables ]]
local hmiLevels = { }

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()

--[[ General Settings for configuration ]]
for i = 1, 4 do
  config["application" .. i].registerAppInterfaceParams.appName = "App_" .. i
end

config.application2.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }
config.application3.registerAppInterfaceParams.appHMIType = { "DEFAULT" }
config.application4.registerAppInterfaceParams.appHMIType = { "MEDIA" }

config.application1.registerAppInterfaceParams.isMediaApplication = false
config.application2.registerAppInterfaceParams.isMediaApplication = false
config.application3.registerAppInterfaceParams.isMediaApplication = false
config.application4.registerAppInterfaceParams.isMediaApplication = true

--[[ General Settings for configuration ]]
Test = require("connecttest")
require("user_modules/AppTypes")

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
-- Start 3 additional mobile sessions
for i = 2, 4 do
  Test["TestStep_StartSession_" .. i] = function(self)
    self["mobileSession" .. i] = mobileSession.MobileSession(self, self.mobileConnection)
    self["mobileSession" .. i]:StartService(7)
  end
end

-- Register 3 additional apps
for i = 2, 4 do

  Test["TestStep_RegisterApp_" .. i] = function(self)
    EXPECT_HMICALL("BasicCommunication.UpdateAppList")
    :Do(function(_, d)
        self.hmiConnection:SendResponse(d.id, d.method, "SUCCESS", { })
      end)
    local corId = self["mobileSession" .. i]:SendRPC("RegisterAppInterface", config["application" .. i].registerAppInterfaceParams)
    self["mobileSession" .. i]:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })

    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",{application = { appName = "App_".. i }})
    :Do(function(_,data)
        self.applications["App_"..i] = data.params.application.appID
      end)

    self["mobileSession"..i]:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    :Do(function(_,data)
        hmiLevels[i] = tostring(data.payload.hmiLevel)
      end)

  end
end

--Set particular HMILevel for each app
function Test:TestStep_ActivateApp_2()
  local requestId1 = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["App_2"] })
  EXPECT_HMIRESPONSE(requestId1)
  :Do(function(_, data1)
      if data1.result.isSDLAllowed ~= true then
        local requestId2 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
          { language = "EN-US", messageCodes = { "DataConsent" } })
        EXPECT_HMIRESPONSE(requestId2)
        :Do(function(_, _)
            self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
              { allowed = true, source = "GUI", device = { id = utils.getDeviceMAC(), name = utils.getDeviceName() } })
          end)
      end
    end)
  EXPECT_HMICALL("BasicCommunication.ActivateApp")
  :Do(function(_,data) self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {}) end)

  EXPECT_NOTIFICATION("OnHMIStatus", {}):Times(0)
  self["mobileSession2"]:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  :Do(function(_,data)
      hmiLevels[1] = tostring("NONE")
      hmiLevels[2] = tostring(data.payload.hmiLevel)
    end)

  self["mobileSession3"]:ExpectNotification("OnHMIStatus"):Times(0)
  self["mobileSession4"]:ExpectNotification("OnHMIStatus"):Times(0)
end

function Test:TestStep_ActivateApp_3()
  local requestId1 = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["App_3"]})
  EXPECT_HMIRESPONSE(requestId1)

  EXPECT_NOTIFICATION("OnHMIStatus", {}):Times(0)
  self["mobileSession2"]:ExpectNotification("OnHMIStatus", {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  :Do(function(_,data) hmiLevels[2] = tostring(data.payload.hmiLevel) end)
  self["mobileSession3"]:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  :Do(function(_,data) hmiLevels[3] = tostring(data.payload.hmiLevel) end)
  self["mobileSession4"]:ExpectNotification("OnHMIStatus"):Times(0)
end

function Test:TestStep_ActivateApp_4()
  local requestId1 = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["App_4"]})
  EXPECT_HMIRESPONSE(requestId1)

  -- App_1: NONE
  EXPECT_NOTIFICATION("OnHMIStatus", {}):Times(0)
  -- App_2: LIMITED
  self["mobileSession2"]:ExpectNotification("OnHMIStatus"):Times(0)
  -- APP_3: BACKGROUND
  self["mobileSession3"]:ExpectNotification("OnHMIStatus", {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  :Do(function(_,data) hmiLevels[3] = tostring(data.payload.hmiLevel) end)
  -- APP_4: FULL
  self["mobileSession4"]:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  :Do(function(_,data) hmiLevels[4] = tostring(data.payload.hmiLevel) end)
end

function Test.ShowHMILevels()
  print("--- HMILevels (app: level) -----------------------")
  for k, v in pairs(hmiLevels) do
    print(k .. ": " .. v)
  end
  print("--------------------------------------------------")
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

for time = 1, 10 do
  function Test:TestStep_CheckOnSystemRequest_AppLevel()
    print("Check OnSystemRequest sent to application. Time: "..time.."/10")
    local received_onsystemrequest = 0
    local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
        { policyType = "module_config", property = "endpoints" })
    EXPECT_HMIRESPONSE(requestId)
    :Do(function()
        self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", { requestType = "PROPRIETARY", fileName = "PolicyTableUpdate" })

        EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "PROPRIETARY"}):Times(0)
        :Do(function()
            self:FailTestCase("ERROR: OnSystemRequest is received for App_1, hmilevel:NONE")
          end)

        self["mobileSession2"]:ExpectNotification("OnSystemRequest", {requestType = "PROPRIETARY"}):Times(AnyNumber())
        :Do(function()
            received_onsystemrequest = received_onsystemrequest + 1
            print("OnSystemRequset received for App_2: hmilevel: LIMITED")
          end)

        self["mobileSession3"]:ExpectNotification("OnSystemRequest", {requestType = "PROPRIETARY"}):Times(AnyNumber())
        :Do(function()
            received_onsystemrequest = received_onsystemrequest + 1
            print("OnSystemRequset received for App_3: hmilevel: BACKGROUND")
          end)

        self["mobileSession4"]:ExpectNotification("OnSystemRequest", {requestType = "PROPRIETARY"}):Times(AnyNumber())
        :Do(function()
            received_onsystemrequest = received_onsystemrequest + 1
            print("OnSystemRequset received for App_4: hmilevel: FULL")
          end)
      end)

    local function check_result()
      if (received_onsystemrequest > 1) then
        self:FailTestCase("ERROR: OnSystemRequest is received more than one applications")
      elseif( received_onsystemrequest == 0) then
        self:FailTestCase("ERROR: OnSystemRequest is not received at all")
      end
    end
    commonTestCases:DelayedExp(11000)
    RUN_AFTER(check_result,10000)
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
