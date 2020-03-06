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
-- SDL is built with "-DEXTENDED_POLICY: PROPRIETARY" flag
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
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "PROPRIETARY" } } })

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local mobileSession = require("mobile_session")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")

--[[ Local Variables ]]
local expectedResult = {2, 3, 4} -- Expected Ids of applications
local actualResult = { } -- Actual Ids of applications
local sequence = { }
local hmiLevels = { }

--[[ Local Functions ]]
local function log(item)
  sequence[#sequence + 1] = item
end

local function contains(t, item)
  for _, v in pairs(t) do
    if v == item then
      return true
    end
  end
  return false
end

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require("connecttest")
require("user_modules/AppTypes")

--[[ Specific Notifications ]]
EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
:Do(function(_, d)
    log("SDL->HMI: SDL.OnStatusUpdate(" .. d.params.status .. ")")
  end)
:Times(AnyNumber())
:Pin()

EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
:Do(function()
    log("SDL->HMI: BC.PolicyUpdate")
  end)
:Times(AnyNumber())
:Pin()

EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
:Do(function(_, d)
    log("SDL->HMI: BC.OnAppRegistered('".. d.params.application.appName .. "')")
  end)
:Times(AnyNumber())
:Pin()

--[[ General Settings for configuration ]]
for i = 1, 4 do
  config["application" .. i].registerAppInterfaceParams.appName = "App_" .. i
end
config.application3.registerAppInterfaceParams.appHMIType = { "DEFAULT" }
config.application4.registerAppInterfaceParams.appHMIType = { "DEFAULT" }
config.application2.registerAppInterfaceParams.isMediaApplication = false
config.application2.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
-- Start 3 additional mobile sessions
for i = 2, 4 do
  Test["StartSession_" .. i] = function(self)
    self["mobileSession" .. i] = mobileSession.MobileSession(self, self.mobileConnection)
    self["mobileSession" .. i]:StartService(7)
  end
end

-- Register 3 additional apps
for i = 2, 4 do
  Test["RegisterApp_" .. i] = function(self)
    EXPECT_HMICALL("BasicCommunication.UpdateAppList")
    :Do(function(_, d)
        self.hmiConnection:SendResponse(d.id, d.method, "SUCCESS", { })
        self.applications = { }
        for _, app in pairs(d.params.applications) do
          self.applications[app.appName] = app.appID
        end
      end)
    local corId = self["mobileSession" .. i]:SendRPC("RegisterAppInterface", config["application" .. i].registerAppInterfaceParams)
    self["mobileSession" .. i]:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
  end
end

function Test:RegisterOnHMIStatusNotifications()
  self.mobileSession:ExpectNotification("OnHMIStatus")
  :Do(function(_, d)
      log("SDL->MOB: OnHMIStatus, App_1('".. tostring(d.payload.hmiLevel) .. "')")
      hmiLevels[1] = tostring(d.payload.hmiLevel)
    end)
  :Times(AnyNumber())
  :Pin()
  for i = 2, 4 do
    self["mobileSession" .. i]:ExpectNotification("OnHMIStatus")
    :Do(function(_, d)
        log("SDL->MOB: OnHMIStatus, App_" .. i .. "('".. tostring(d.payload.hmiLevel) .. "')")
        hmiLevels[i] = tostring(d.payload.hmiLevel)
      end)
    :Times(AnyNumber())
    :Pin()
  end
end

-- Set particular HMILevel for each app
for i = 2, 4 do
  function Test:ActivateApps()
    local requestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["App_" .. i] })
    EXPECT_HMIRESPONSE(requestId)
  end
end

function Test.ShowHMILevels()
  if hmiLevels[1] == nil then
    hmiLevels[1] = "NONE"
  end
  print("--- HMILevels (app: level) -----------------------")
  for k, v in pairs(hmiLevels) do
    print(k .. ": " .. v)
  end
  print("--------------------------------------------------")
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:RegisterOnSystemRequestNotifications()
  self.mobileSession:ExpectNotification("OnSystemRequest")
  :Do(function()
      log("SDL->MOB: OnSystemRequest, App_1()")
      actualResult[#actualResult + 1] = 1
    end)
  :Times(AnyNumber())
  :Pin()
  for i = 2, 4 do
    self["mobileSession" .. i]:ExpectNotification("OnSystemRequest")
    :Do(function()
        log("SDL->MOB: OnSystemRequest, App_" .. i)
        actualResult[#actualResult + 1] = i
      end)
    :Times(AnyNumber())
    :Pin()
  end
end

function Test:StartPTU()
  local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  log("HMI->SDL: SDL.GetPolicyConfigurationData")
  EXPECT_HMIRESPONSE(requestId)
  :Do(function()
      log("SDL->HMI: SDL.GetPolicyConfigurationData")
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", { requestType = "PROPRIETARY", fileName = "PolicyTableUpdate" })
      log("HMI->SDL: BC.OnSystemRequest")
      requestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", { language = "EN-US", messageCodes = { "StatusUpToDate" } })
      log("HMI->SDL: SDL.GetUserFriendlyMessage")
      EXPECT_HMIRESPONSE(requestId)
      log("SDL->HMI: SDL.GetUserFriendlyMessage")
    end)
end

function Test.ShowSequence()
  print("--- Sequence -------------------------------------")
  for k, v in pairs(sequence) do
    print(k .. ": " .. v)
  end
  print("--------------------------------------------------")
end

function Test:ValidateResult()
  if #actualResult ~= 1 then
    local msg = table.concat({"Expected 1 occurance of OnSystemRequest, got: ", tostring(#actualResult)})
    self:FailTestCase(msg)
  else
    if not contains(expectedResult, actualResult[1]) then
      local msg = table.concat({
        "Expected OnSystemRequest() from Apps: ", table.concat(expectedResult, ", "),
        ", got: ", tostring(actualResult[1])
        })
      self:FailTestCase(msg)
    else
      print(table.concat({"OnSystemRequest was sent through application '", actualResult[1], "'"}))
    end
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
