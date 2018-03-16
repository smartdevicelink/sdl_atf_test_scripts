---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PolicyTableUpdate] Requirements for HMILevel of the application(s)
-- taking part in Policy Update
--
-- Description:
-- Policies Manager must randomly select the application through which to send the policy table packet
-- and request an update to its local policy table only through apps with HMI status of BACKGROUND, LIMITED, and FULL.
-- If there are no mobile apps with any of these statuses, the system must use an app with an HMI Level of NONE.
--
-- Preconditions:
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- There are registered 4 apps each with different HMILevel
-- app_1: NONE, app_2: LIMITED, app_3: BACKGROUND, app_4: FULL
-- Performed steps:
-- PTU is requested
-- SDL->HMI:SDL.OnStatusUpdate(UPDATE_NEEDED)
--
-- Expected result:
-- SDL chooses randomly between the app_2, app_3, app_4 to send OnSystemRequest
-- app_1 doesn't take part in PTU (except of the case when app_1 is the only application being run on SDL)
---------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local mobileSession = require("mobile_session")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local testCasesForPolicyTable = require("user_modules/shared_testcases/testCasesForPolicyTable")
local commonTestCases = require("user_modules/shared_testcases/commonTestCases")
local commonPreconditions = require ('user_modules/shared_testcases/commonPreconditions')

--[[ Local Variables ]]
local hmiLevels = { }

--[[ Local Functions ]]
local function SetTimeout()
  local pathToFile = commonPreconditions:GetPathToSDL() .. 'sdl_preloaded_pt.json'
  local file = io.open(pathToFile, "r")
  local json_data = file:read("*all")
  file:close()
  local json = require("modules/json")
  local data = json.decode(json_data)
  if data.policy_table.functional_groupings["DataConsent-2"] then
    data.policy_table.functional_groupings["DataConsent-2"] = {rpcs = json.null}
  end
  data.policy_table.module_config.timeout_after_x_seconds = 120
  data = json.encode(data)
  file = io.open(pathToFile, "w")
  file:write(data)
  file:close()
end

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()
commonPreconditions:BackupFile("sdl_preloaded_pt.json")
SetTimeout()

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

Test = require("connecttest")
require('cardinalities')
require("user_modules/AppTypes")

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

-- Start 3 additional mobile sessions
for i = 2, 4 do
  Test["Precondition_StartSession_" .. i] = function(self)
    self["mobileSession" .. i] = mobileSession.MobileSession(self, self.mobileConnection)
    self["mobileSession" .. i]:StartService(7)
  end
end

-- Register 3 additional apps
for i = 2, 4 do
  Test["Precondition_RegisterApp_" .. i] = function(self)
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
function Test:Precondition_ActivateApp_2()
  local requestId1 = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["App_2"] })
  EXPECT_HMIRESPONSE(requestId1)

  EXPECT_NOTIFICATION("OnHMIStatus", {}):Times(0)
  self["mobileSession2"]:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  :Do(function(_,data)
      hmiLevels[1] = tostring("NONE")
      hmiLevels[2] = tostring(data.payload.hmiLevel)
    end)

  self["mobileSession3"]:ExpectNotification("OnHMIStatus"):Times(0)
  self["mobileSession4"]:ExpectNotification("OnHMIStatus"):Times(0)
end

function Test:Precondition_ActivateApp_3()
  local requestId1 = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["App_3"]})
  EXPECT_HMIRESPONSE(requestId1)

  EXPECT_NOTIFICATION("OnHMIStatus", {}):Times(0)

  self["mobileSession2"]:ExpectNotification("OnHMIStatus", {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  :Do(function(_,data) hmiLevels[2] = tostring(data.payload.hmiLevel) end)
  self["mobileSession3"]:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  :Do(function(_,data) hmiLevels[3] = tostring(data.payload.hmiLevel) end)
  self["mobileSession4"]:ExpectNotification("OnHMIStatus"):Times(0)
end

function Test:Precondition_ActivateApp_4()
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

for time = 1, 5 do
  function Test:TestStep_CheckOnSystemRequest_AppLevel()
    print("Check OnSystemRequest sent to application. Time: "..time.."/10")
    local received_onsystemrequest = 0
    -- local requestId = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
    -- EXPECT_HMIRESPONSE(requestId)
    -- :Do(function()
    self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", { requestType = "HTTP", fileName = "PolicyTableUpdate" })

    EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "HTTP"}):Times(0)
    :Do(function()
        self:FailTestCase("ERROR: OnSystemRequest is received for App_1, hmilevel:NONE")
      end)

    self["mobileSession2"]:ExpectNotification("OnSystemRequest", {requestType = "HTTP"}):Times(AnyNumber())
    :Do(function()
        received_onsystemrequest = received_onsystemrequest + 1
        print("OnSystemRequset received for App_2: hmilevel: LIMITED")
      end)

    self["mobileSession3"]:ExpectNotification("OnSystemRequest", {requestType = "HTTP"}):Times(AnyNumber())
    :Do(function()
        received_onsystemrequest = received_onsystemrequest + 1
        print("OnSystemRequset received for App_3: hmilevel: BACKGROUND")
      end)

    self["mobileSession4"]:ExpectNotification("OnSystemRequest", {requestType = "HTTP"}):Times(AnyNumber())
    :Do(function()
        received_onsystemrequest = received_onsystemrequest + 1
        print("OnSystemRequset received for App_4: hmilevel: FULL")
      end)
    -- end)

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
testCasesForPolicyTable:Restore_preloaded_pt()
function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test
