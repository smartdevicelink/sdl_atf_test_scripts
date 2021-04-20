---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [General] Policies performance requirement
--
-- Communication of Policy manager and mobile device must not make discernible difference in system operation.
-- Execution of any other operation between SDL and mobile app is possible and has no discernibly more latency.
--(Assumption: here is assumed that mobile app sends PTS(Policy Table Snapshot) and receives PTU(Policy Table Update) from backend in separate thread,
-- i.e. mobile app is not blocked for other operations while waiting response from backend for updated Policy Table)
--
-- Description:
-- 1. SDL started PTU
-- 2. Mobile waiting response from backend, in that time sent RPC
-- Expected result
-- SDL must correctly finish the PTU
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local mobile_session = require("mobile_session")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local json = require("modules/json")
local utils = require ('user_modules/utils')

--[[ Local Variables ]]
local app_id = config.application1.registerAppInterfaceParams.fullAppID
local sequence = { }
local ptu_table
local HMIAppId

--[[ Local Functions ]]
local function timestamp()
  local f = io.popen("date +%H:%M:%S.%3N")
  local o = f:read("*all")
  f:close()
  return (o:gsub("\n", ""))
end

local function log(event, ...)
  table.insert(sequence, { ts = timestamp(), e = event, p = {...} })
end

local function show_log()
  print("--- Sequence -----------------------------------------------")
  for k, v in pairs(sequence) do
    local s = string.format("%03d", k) .. ": " .. v.ts .. ": " .. v.e
    for _, val in pairs(v.p) do
      if val then s = s .. ": " .. val end
    end
    print(s)
  end
  print("------------------------------------------------------------")
end

local function ptsToTable(pts_f)
  local f = io.open(pts_f, "r")
  local content = f:read("*all")
  f:close()
  return json.decode(content)
end

local function updatePTU(ptu)
  if ptu.policy_table.consumer_friendly_messages.messages then
    ptu.policy_table.consumer_friendly_messages.messages = nil
  end
  ptu.policy_table.device_data = nil
  ptu.policy_table.module_meta = nil
  ptu.policy_table.usage_and_error_counts = nil
  ptu.policy_table.app_policies[app_id] = { keep_context = false, steal_focus = false, priority = "NONE", default_hmi = "NONE" }
  ptu.policy_table.app_policies[app_id]["groups"] = { "Base-4", "Base-6" }
  ptu.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  ptu.policy_table.module_config.preloaded_pt = nil
  ptu.policy_table.vehicle_data = nil
end

local function storePTUInFile(ptu, ptu_file_name)
  local f = io.open(ptu_file_name, "w")
  f:write(json.encode(ptu))
  f:close()
end

local function ptu(self)
  local policy_file_name = "PolicyTableUpdate"
  local policy_file_path = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")
  local ptu_file_name = os.tmpname()
  local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  log("HMI->SDL: RQ: SDL.GetPolicyConfigurationData")
  EXPECT_HMIRESPONSE(requestId)
  :Do(
    function()
      log("SDL->HMI: RS: SDL.GetPolicyConfigurationData")
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", { requestType = "PROPRIETARY", fileName = policy_file_name })
      log("HMI->SDL: N: BC.OnSystemRequest")
      updatePTU(ptu_table)
      storePTUInFile(ptu_table, ptu_file_name)

      self.mobileSession:ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
      :Do(
        function()
          log("SDL->MOB: N: OnSystemRequest")
          local corIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", { requestType = "PROPRIETARY", fileName = policy_file_name }, ptu_file_name)
          log("MOB->SDL: RQ: SystemRequest")

          local CorIdAlert = self.mobileSession:SendRPC("Alert",
            {
              alertText1 = "alertText1",
              softButtons =
              {
                {
                  type = "IMAGE",
                  image =
                  {
                    value = "icon.png",
                    imageType = "STATIC",
                  },
                  softButtonID = 1171,
                  systemAction = "KEEP_CONTEXT",
                }
              }
            }
          )
          log("MOB->SDL: RQ: Alert")
          EXPECT_RESPONSE(CorIdAlert, {success = false, resultCode = "DISALLOWED" })
          log("SDL->MOB: RS: Alert")

          EXPECT_HMICALL("BasicCommunication.SystemRequest")
          :Do(
            function(_, d)
              log("SDL->HMI: RQ: BC.SystemRequest")
              self.hmiConnection:SendResponse(d.id, "BasicCommunication.SystemRequest", "SUCCESS", { })
              log("HMI->SDL: RS: SUCCESS: BC.SystemRequest")
              self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = policy_file_path .. "/" .. policy_file_name })
              log("HMI->SDL: N: SDL.OnReceivedPolicyUpdate")
            end)
          self.mobileSession:ExpectResponse(corIdSystemRequest, { success = true, resultCode = "SUCCESS"})
          log("SDL->MOB: RS: SUCCESS: SystemRequest")
        end)
    end)
  os.remove(ptu_file_name)
end

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require("user_modules/connecttest_resumption")
require("user_modules/AppTypes")

function Test:ConnectMobile()
  self:connectMobile()
end

function Test:StartSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

function Test:RAI()
  local corId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
  log("MOB->SDL: RQ: RegisterAppInterface")

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application1.registerAppInterfaceParams.appName } })
  :Do(
    function(_, d1)
      log("SDL->HMI: N: BC.OnAppRegistered")
      HMIAppId = d1.params.application.appID
      EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
      :Times(0)
    end)
  self.mobileSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
  :Do(
    function()
      log("SDL->MOB: RS: RegisterAppInterface")
      self.mobileSession:ExpectNotification("OnHMIStatus", { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
      :Do(
        function(_ ,d)
          log("SDL->MOB: N: OnHMIStatus", d.payload.hmiLevel)
        end)
      self.mobileSession:ExpectNotification("OnPermissionsChange")
      :Do(
        function()
          log("SDL->MOB: N: OnPermissionsChange")
        end)
      :Times(1)
    end)
end

function Test:Activate_App()
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status = "UPDATE_NEEDED" }, { status = "UPDATING" }, { status = "UP_TO_DATE" })
  :Do(function(_, d2)
      log("SDL->HMI: N: SDL.OnStatusUpdate", d2.params.status)
    end)
  :Times(3)
  local requestId1 = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = HMIAppId })
  log("HMI->SDL: RQ: SDL.ActivateApp")
  EXPECT_HMIRESPONSE(requestId1)
  :Do(
    function(_, d1)
      log("SDL->HMI: RS: SDL.ActivateApp")
      if d1.result.isSDLAllowed ~= true then
        log("I: SDL is NOT allowed, activation required")
        local requestId2 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", { language = "EN-US", messageCodes = { "DataConsent" } })
        log("HMI->SDL: RQ: SDL.GetUserFriendlyMessage")
        EXPECT_HMIRESPONSE(requestId2)
        :Do(
          function()
            log("SDL->HMI: RS: SDL.GetUserFriendlyMessage")
            self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", { allowed = true, source = "GUI", device = { id = utils.getDeviceMAC(), name = utils.getDeviceName() } })
            log("HMI->SDL: N: SDL.OnAllowSDLFunctionality")
            EXPECT_HMICALL("BasicCommunication.ActivateApp")
            :Do(
              function(_, d2)
                log("SDL->HMI: RQ: BC.ActivateApp")
                self.hmiConnection:SendResponse(d2.id,"BasicCommunication.ActivateApp", "SUCCESS", { })
                log("HMI->SDL: RS: BC.ActivateApp")
                self.mobileSession:ExpectNotification("OnHMIStatus", { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
                :Do(
                  function(_ ,d3)
                    log("SDL->MOB: N: OnHMIStatus", d3.payload.hmiLevel)
                  end)
              end)
          end)
      end
    end)
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :Do(
    function(_, d)
      log("SDL->HMI: RQ: BC.PolicyUpdate")
      ptu_table = ptsToTable(d.params.file)
      self.hmiConnection:SendResponse(d.id, d.method, "SUCCESS", { })
      log("HMI->SDL: RS: BC.PolicyUpdate")
      ptu(self)
      self.mobileSession:ExpectNotification("OnPermissionsChange")
      :Do(
        function()
          log("SDL->MOB: N: OnPermissionsChange")
        end)
      :Times(1)
    end)
end

function Test:CheckStatus()
  local reqId = self.hmiConnection:SendRequest("SDL.GetStatusUpdate")
  log("HMI->SDL: RQ: SDL.GetStatusUpdate")

  EXPECT_HMIRESPONSE(reqId, { status = "UP_TO_DATE" })
  :Do(
    function()
      log("HMI->SDL: RS: UP_TO_DATE: SDL.GetStatusUpdate")
    end)
end

function Test.Test_ShowSequence()
  show_log()
end

function Test.Postconditions_StopSDL()
  StopSDL()
end

return Test
