---------------------------------------------------------------------------------------------
-- Script verifies PTU sequence
-- Supported PROPRIETARY, EXTERNAL_PROPRIETARY and HTTP flows
---------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local mobile_session = require("mobile_session")
local json = require("modules/json")
local atf_logger = require("atf_logger")
local sdl = require("SDL")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local utils = require ('user_modules/utils')
local commonTestCases = require("user_modules/shared_testcases/commonTestCases")

--[[ General configuration parameters ]]
config.mobileHost = "127.0.0.1"
config.defaultProtocolVersion = 2

--[[ Local Variables ]]
local flowType = {
  PROPRIETARY = 1,
  EXTERNAL_PROPRIETARY = 2,
  HTTP = 3
}

--[[ Local Functions ]]
local function preconditions()
  -- Stop SDL if process is still running
  commonFunctions:SDLForceStop()
  -- Remove Local Policy Update
  commonSteps:DeletePolicyTable()
  -- Delete log files
  commonSteps:DeleteLogsFiles()
end

-- Allow device from HMI
local function allowSDL(self)
  -- sending notification OnAllowSDLFunctionality from HMI to allow connected device
  self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {
    allowed = true,
    source = "GUI",
    device = {
      id = utils.getDeviceMAC(),
      name = utils.getDeviceName()
    }
  })
  commonTestCases:DelayedExp(500)
end

-- Start SDL and HMI, establish connection between SDL and HMI, open mobile connection via TCP
local function start(self)
  self:runSDL()
  commonFunctions:waitForSDLStart(self)
  :Do(function()
      self:initHMI(self)
      :Do(function()
          commonFunctions:userPrint(35, "HMI initialized")
          self:initHMI_onReady()
          :Do(function()
              commonFunctions:userPrint(35, "HMI is ready")
              self:connectMobile()
              :Do(function()
                  commonFunctions:userPrint(35, "Mobile connected")
                  allowSDL(self)
                end)
            end)
        end)
    end)
end

-- Loging messages in terminal
local function log(...)
  local str = "[" .. atf_logger.formated_time(true) .. "]"
  for i, p in pairs({...}) do
    local delimiter = "\t"
    if i == 1 then delimiter = " " end
    str = str .. delimiter .. p
  end
  commonFunctions:userPrint(35, str)
end

-- Convert snapshot form json to table
-- @tparam file pts_f snapshot file
local function ptsToTable(pts_f)
  local f = io.open(pts_f, "r")
  local content = f:read("*all")
  f:close()
  return json.decode(content)
end

-- Creation policy table from snapshot
-- @tparam table ptu snapshot table
local function getPTUFromPTS(ptu)
  -- remove messages in consumer_friendly_messages
  ptu.policy_table.consumer_friendly_messages.messages = nil
  -- remove device_data
  ptu.policy_table.device_data = nil
  -- remove module_meta
  ptu.policy_table.module_meta = nil
  -- remove usage_and_error_counts
  ptu.policy_table.usage_and_error_counts = nil
  -- write empty struct in "DataConsent-2".rpcs
  ptu.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  -- remove preloaded_pt
  ptu.policy_table.module_config.preloaded_pt = nil
  -- remove preloaded_date
  ptu.policy_table.module_config.preloaded_date = nil
  -- Create structure in app_policies related to registered application
  ptu.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID] = {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE"
  }
  -- Added permissions for registered app from "Base-4", "Base-6" groups
  ptu.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID]["groups"] = {
    "Base-4", "Base-6"
  }
  -- remove vehicle_data
  ptu.policy_table.vehicle_data = nil
end

-- Save created PT in file
-- @tparam table ptu PT table
-- @tparam string ptu_file_name file name
local function storePTUInFile(ptu, ptu_file_name)
  local f = io.open(ptu_file_name, "w")
  f:write(json.encode(ptu))
  f:close()
end

-- Check that PT is sent as binary data in OnSystem request
-- @tparam table bin_data binary data
-- @tparam number pFlow number of floe type from flowType
local function checkIfPTSIsSentAsBinary(bin_data, pFlow, self)
  -- decode binary data to table depending on policy flow
  local pt = nil
  if bin_data ~= nil and string.len(bin_data) > 0 then
    if flowType[pFlow] == flowType.PROPRIETARY then
      pt = json.decode(bin_data).HTTPRequest.body
    elseif flowType[pFlow] == flowType.EXTERNAL_PROPRIETARY or flowType[pFlow] == flowType.HTTP then
      pt = bin_data
    end
    pt = json.decode(pt)
  end
  -- Check presence of policy_table in decoded PT
  if pt == nil or not pt.policy_table then
    self:FailTestCase("PTS was not sent to Mobile as binary data in payload of OnSystemRequest")
  end
end

-- Policy table update with Proprietary flow
-- @tparam table ptu_table PT table
-- @tparam string pFlow policy flow
local function ptuProprietary(ptu_table, self, pFlow)
  -- Get path to snapshot
  local pts_file_name = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath") .. "/"
  .. commonFunctions:read_parameter_from_smart_device_link_ini("PathToSnapshot")
  -- create ptu_file_name as tmp file
  local ptu_file_name = os.tmpname()
  -- Send GetPolicyConfigurationData request from HMI to SDL
  local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  log("HMI->SDL: RQ: SDL.GetPolicyConfigurationData")
  -- Expect response GetPolicyConfigurationData on HMI side
  EXPECT_HMIRESPONSE(requestId)
  :Do(function()
      log("SDL->HMI: RS: SDL.GetPolicyConfigurationData")
      -- After receiving GetPolicyConfigurationData response send OnSystemRequest notification from HMI
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
        { requestType = "PROPRIETARY", fileName = pts_file_name })
      log("HMI->SDL: N: BC.OnSystemRequest")
      -- Prepare PT for update
      getPTUFromPTS(ptu_table)
      -- Save created PT for update in tmp file
      storePTUInFile(ptu_table, ptu_file_name)
      -- Expect receiving of OnSystemRequest notification with snapshot on mobile side
      self.mobileSession:ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
      :Do(function(_, d)
          -- After receiving OnSystemRequest notification on mobile side check that
          -- data in notification was sent as binary data
          checkIfPTSIsSentAsBinary(d.binaryData, pFlow, self)
          log("SDL->MOB: N: OnSystemRequest")
          -- Send SystemRequest request with PT for update from mobile side
          local corIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
            { requestType = "PROPRIETARY" }, ptu_file_name)
          log("MOB->SDL: RQ: SystemRequest")
          -- Expect SystemRequest request on HMI side
          EXPECT_HMICALL("BasicCommunication.SystemRequest")
          :Do(function(_, dd)
              log("SDL->HMI: RQ: BC.SystemRequest")
              -- Send SystemRequest response form HMI with resultCode SUCCESS
              self.hmiConnection:SendResponse(dd.id, dd.method, "SUCCESS", { })
              log("HMI->SDL: RS: SUCCESS: BC.SystemRequest")
              -- Send OnReceivedPolicyUpdate notification from HMI
              self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
                { policyfile = dd.params.fileName })
              log("HMI->SDL: N: SDL.OnReceivedPolicyUpdate")
            end)
          -- Expect SystemRequest response with resultCode SUCCESS on mobile side
          self.mobileSession:ExpectResponse(corIdSystemRequest, { success = true, resultCode = "SUCCESS"})
          -- remove tmp PT file after receiving SystemRequest response on mobile side
          :Do(function() os.remove(ptu_file_name) end)
          log("SDL->MOB: RS: SUCCESS: SystemRequest")
        end)
    end)
end

-- Policy table update with HTTP flow
-- @tparam table ptu_table PT table
local function ptuHttp(ptu_table, self)
  -- name for PT for SystemRequest
  local policy_file_name = "PolicyTableUpdate"
  -- tmp file name for PT file
  local ptu_file_name = os.tmpname()
  -- Prepare PT for update
  getPTUFromPTS(ptu_table)
  -- Save created PT for update in tmp file
  storePTUInFile(ptu_table, ptu_file_name)
  -- Send SystemRequest form mobile app with created PT
  local corId = self.mobileSession:SendRPC("SystemRequest",
    { requestType = "HTTP", fileName = policy_file_name }, ptu_file_name)
  log("MOB->SDL: RQ: SystemRequest")
  -- Expect successful SystemRequest response on mobile side
  self.mobileSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
  :Do(function()
      log("SDL->MOB: RS: SUCCESS: SystemRequest")
    end)
  -- remove tmp PT file
  os.remove(ptu_file_name)
end

-- Expect 3 OnStatusUpdate notification on HMI side during PTU
local function expOnStatusUpdate()
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate",
    { status = "UPDATE_NEEDED" }, { status = "UPDATING" }, {status = "UP_TO_DATE" })
  :Do(function(_, d)
      log("SDL->HMI: N: SDL.OnStatusUpdate", d.params.status)
    end)
  :Times(3)
end

-- Fail test cases by incorrect PTU
-- @tparam string pRequestName request name of RPC that is failed expectations
local function failInCaseIncorrectPTU(pRequestName, self)
  self:FailTestCase(pRequestName .. " was sent more than once (PTU update was incorrect)")
end

-- Registration of application with policy table update
local function raiPTU(self)
  expOnStatusUpdate() -- temp solution due to issue in SDL:
  -- SDL.OnStatusUpdate(UPDATE_NEEDED) notification is sent before BC.OnAppRegistered (EXTERNAL_PROPRIETARY flow)

  -- creation mobile session
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  -- open RPC service in created session
  self.mobileSession:StartService(7)
  :Do(function()
      -- Send RegisterAppInterface request from mobile application
      local corId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      log("MOB->SDL: RQ: RegisterAppInterface")
      -- Expect OnAppRegistered on HMI side from SDL
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
        { application = { appName = config.application1.registerAppInterfaceParams.appName } })
      :Do(function()
          log("SDL->HMI: N: BC.OnAppRegistered")
        end)
      -- Expect RegisterAppInterface response on mobile side with resultCode SUCCESS
      self.mobileSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          if sdl.buildOptions.extendedPolicy == "PROPRIETARY"
          or sdl.buildOptions.extendedPolicy == "EXTERNAL_PROPRIETARY" then
            -- Expect PolicyUpdate request on HMI side
            EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
            :Do(function(e, d)
                if e.occurences == 1 then -- SDL send BC.PolicyUpdate more than once if PTU update was incorrect
                  log("SDL->HMI: RQ: BC.PolicyUpdate")
                  -- Create PT form snapshot
                  local ptu_table = ptsToTable(d.params.file)
                  -- Sending PolicyUpdate request from HMI with resultCode SUCCESS
                  self.hmiConnection:SendResponse(d.id, d.method, "SUCCESS", { })
                  log("HMI->SDL: RS: BC.PolicyUpdate")
                  -- PTU proprietary flow
                  ptuProprietary(ptu_table, self, sdl.buildOptions.extendedPolicy)
                else
                  failInCaseIncorrectPTU("BC.PolicyUpdate", self)
                end
              end)
          elseif sdl.buildOptions.extendedPolicy == "HTTP" then
            -- Expect OnSystemRequest notification on mobile side
            self.mobileSession:ExpectNotification("OnSystemRequest")
            :Do(function(e, d)
                log("SDL->MOB: N: OnSystemRequest", e.occurences, d.payload.requestType)
                if d.payload.requestType == "HTTP" then
                  if e.occurences <= 2 then -- SDL send OnSystemRequest more than once if PTU update was incorrect
                    -- Check data in receives OnSystemRequest notification on mobile side
                    checkIfPTSIsSentAsBinary(d.binaryData, sdl.buildOptions.extendedPolicy, self)
                    if d.binaryData then
                      -- Create PT form binary data
                      local ptu_table = json.decode(d.binaryData)
                      -- PTU HTTP flow
                      ptuHttp(ptu_table, self)
                    end
                  else
                    failInCaseIncorrectPTU("OnSystemRequest", self)
                  end
                end
              end)
            :Times(2)
          end
          log("SDL->MOB: RS: RegisterAppInterface")
          -- Expect OnHMIStatus with hmiLevel NONE on mobile side form SDL
          self.mobileSession:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          :Do(function(_, d)
              log("SDL->MOB: N: OnHMIStatus", d.payload.hmiLevel)
            end)
          -- Expect OnPermissionsChange on mobile side form SDL
          self.mobileSession:ExpectNotification("OnPermissionsChange")
          :Do(function()
              log("SDL->MOB: N: OnPermissionsChange")
            end)
          :Times(2)
        end)
    end)
end

-- Check update status
local function checkPTUStatus(self)
  -- Send GetStatusUpdate form HMI to SDL
  local reqId = self.hmiConnection:SendRequest("SDL.GetStatusUpdate")
  log("HMI->SDL: RQ: SDL.GetStatusUpdate")
  -- Expect GetStatusUpdate response from SDL to HMI with update status
  EXPECT_HMIRESPONSE(reqId, { result = { status = "UP_TO_DATE" }})
  :Do(function(_, d)
      log("HMI->SDL: RS: SDL.GetStatusUpdate", tostring(d.result.status))
    end)
end

-- Pring in terminal build options(RC status and policy slow)
local function printSDLConfig()
  commonFunctions:printTable(sdl.buildOptions)
end

local function postconditions()
  StopSDL()
end

--[[ Scenario ]]
runner.Title("Preconditions")
-- Stop SDL if process is still running, delete local policy table and log files
runner.Step("Clean environment", preconditions)
-- Start SDL and HMI, establish connection between SDL and HMI, open mobile connection via TCP
runner.Step("Start SDL, HMI, connect Mobile", start)
-- Pring in terminal build options(RC status and policy slow)
runner.Step("SDL Configuration", printSDLConfig)

runner.Title("Test")
-- create mobile session, register application, perform PTU wit PT
runner.Step("RAI, PTU", raiPTU)
-- Check that PTU is performed successful
runner.Step("Check Status", checkPTUStatus)

runner.Title("Postconditions")
runner.Step("Stop SDL", postconditions)
