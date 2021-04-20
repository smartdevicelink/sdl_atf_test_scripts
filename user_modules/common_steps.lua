local utils = require ('user_modules/utils')
--------------------------------------------------------------------------------
-- This scripts contains common steps(Tests) that are used often in many scripts
--[[ Note: functions in this script are designed based on bellow data structure of mobile connection, sessions, applications, application's parameter and HMI app ID
self.mobile_connections = {
  connection1 = {
    session1 = {
      app_name1 = {
        register_application_parameters = {
          appName = "app_name1",
          appHMIType = {"NAVIGATION"},
          ...}
        hmi_app_id = 123,
        is_unregistered = true -- means application is unregistered, nil or false: application is not unregistered
      }
    },
    session2 = { ..
    }
  },
  connection2 = {
    session3 = { ...
    },
    ...
  }
}]]
--------------------------------------------------------------------------------
local CommonSteps = {}

-- COMMON FUNCTIONS FOR MOBILE CONNECTIONS
--------------------------------------------------------------------------------
-- Create mobile connection
-- @param mobile_connection_name: name to create mobile connection. If it is omitted, use default name "mobileConnection"
-- @param is_stoped_ATF_when_app_is_disconnected: true: stop ATF, false: ATF continues running.
--------------------------------------------------------------------------------
function CommonSteps:AddMobileConnection(test_case_name, mobile_connection_name)
  Test[test_case_name] = function(self)
    mobile_connection_name = mobile_connection_name or "mobileConnection"
    local mobileAdapter = self.getDefaultMobileAdapter()
    local fileConnection = file_connection.FileConnection("mobile_" .. mobile_connection_name .. ".out", mobileAdapter)
    self[mobile_connection_name] = mobile.MobileConnection(fileConnection)
    event_dispatcher:AddConnection(self[mobile_connection_name])
    self[mobile_connection_name]:Connect()
    common_functions:StoreConnectionData(mobile_connection_name, self)
    -- Wait for mobile connection is created completely.
    os.execute("sleep 1")
  end
end

-- COMMON FUNCTIONS FOR MOBILE SESSIONS
--------------------------------------------------------------------------------
-- Add new mobile session
-- @param test_case_name: Test name
-- @param mobile_connection_name: name of connection to create new session. If it is omitted, use default connection name "mobileConnection"
-- @param mobile_session_name: name of new session. If it is omitted, use default connection name "mobileSession"
-- @param is_not_started_rpc_service: true - does not start RPC service (7) after adding new session, otherwise start RPC(7) service
--------------------------------------------------------------------------------
function CommonSteps:AddMobileSession(test_case_name, mobile_connection_name, mobile_session_name, is_not_started_rpc_service)
  Test[test_case_name] = function(self)
    mobile_connection_name = mobile_connection_name or "mobileConnection"
    mobile_session_name = mobile_session_name or "mobileSession"
    -- If mobile connection name has not been stored, store it to use later in other functions
    if not common_functions:IsConnectionDataExist(mobile_connection_name, self) then
      common_functions:StoreConnectionData(mobile_connection_name, self)
    end
    -- Create mobile session on current connection.
    self[mobile_session_name] = mobile_session.MobileSession(self, self[mobile_connection_name])
    common_functions:StoreSessionData(mobile_connection_name, mobile_session_name, self)
    if not is_not_started_rpc_service then
      self[mobile_session_name]:StartService(7)
    end
  end
end
--------------------------------------------------------------------------------
-- Close mobile session of an application
-- @param test_case_name: Test name
-- @param mobile_session_name: name of session will be closed session
--------------------------------------------------------------------------------
function CommonSteps:CloseMobileSession_InternalUsed(app_name, self)
  local hmi_app_id = common_functions:GetHmiAppId(app_name, self)
  local mobile_connection_name, mobile_session_name = common_functions:GetMobileConnectionNameAndSessionName(app_name, self)
  self[mobile_session_name]:Stop()
  -- Remove data for this session after it is stopped.
  self.mobile_connections[mobile_connection_name][mobile_session_name] = nil
  -- If application is not unregistered on this session, verify SDL sends BasicCommunication.OnAppUnregistered notification to HMI
  if hmi_app_id then
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = hmi_app_id})
  end
end
--------------------------------------------------------------------------------
-- Close mobile session of an application
-- @param test_case_name: Test name
-- @param mobile_session_name: name of session will be closed session
--------------------------------------------------------------------------------
function CommonSteps:CloseMobileSession(test_case_name, mobile_session_name)
  Test[test_case_name] = function(self)
    mobile_session_name = mobile_session_name or "mobileSession"
    local app_name = common_functions:GetApplicationName(mobile_session_name, self)
    CommonSteps:CloseMobileSession_InternalUsed(app_name, self)
  end
end
--------------------------------------------------------------------------------
-- Close mobile session of an application
-- @param test_case_name: Test name
-- @param app_name: application name will be closed session
--------------------------------------------------------------------------------
function CommonSteps:CloseMobileSessionByAppName(test_case_name, app_name)
  Test[test_case_name] = function(self)
    CommonSteps:CloseMobileSession_InternalUsed(app_name, self)
  end
end

-- COMMON FUNCTIONS FOR SERVICES
--------------------------------------------------------------------------------
-- Start service
-- @param test_case_name: Test name
-- @param mobile_session_name: name of mobile session to start service
-- @param service_id: id of service: RPC: 7, audio: 10, video: 11, ..; if service_id is omitted, this function starts default service (RPC: 7)
--------------------------------------------------------------------------------
function CommonSteps:StartService(test_case_name, mobile_session_name, service_id)
  Test[test_case_name] = function(self)
    self[mobile_session_name]:StartService(service_id or 7)
  end
end

-- COMMON STEPS FOR APPLICATIONS
--------------------------------------------------------------------------------
-- Register application
-- @param test_case_name: Test name
-- @param mobile_session_name: mobile session
-- @param application_parameters: parameters are used to register application.
-- If it is omitted, use default application parameter config.application1.registerAppInterfaceParams
-- @param expected_on_hmi_status: value to verify OnHMIStatus notification.
-- If this parameter is omitted, this function will check default HMI status {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}
-- @param expected_response: expected response for RegisterAppIterface request.
-- If expected_response parameter is omitted, this function will check default response {success = true, resultCode = "SUCCESS"}
--------------------------------------------------------------------------------
function CommonSteps:RegisterApplication(test_case_name, mobile_session_name, application_parameters, expected_response, expected_on_hmi_status)
  Test[test_case_name] = function(self)
    mobile_session_name = mobile_session_name or "mobileSession"
    application_parameters = application_parameters or config.application1.registerAppInterfaceParams
    local app_name = application_parameters.appName
    common_functions:StoreApplicationData(mobile_session_name, app_name, application_parameters, _, self)

    local CorIdRAI = self[mobile_session_name]:SendRPC("RegisterAppInterface", application_parameters)
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = {appName = app_name}})
    :Do(function(_,data)
        common_functions:StoreHmiAppId(app_name, data.params.application.appID, self)
      end)
    expected_response = expected_response or {success = true, resultCode = "SUCCESS"}
    self[mobile_session_name]:ExpectResponse(CorIdRAI, expected_response)
    expected_on_hmi_status = expected_on_hmi_status or {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}
    self[mobile_session_name]:ExpectNotification("OnHMIStatus", expected_on_hmi_status)
    :Do(function(_,data)
        common_functions:StoreHmiStatus(app_name, data.payload, self)
      end)
  end
end
--------------------------------------------------------------------------------
-- Unregister application
-- @param test_case_name: Test name
-- @param app_name: name of application is unregistered
--------------------------------------------------------------------------------
function CommonSteps:UnregisterApp(test_case_name, app_name)
  Test[test_case_name] = function(self)
    local mobile_connection_name, mobile_session_name = common_functions:GetMobileConnectionNameAndSessionName(app_name, self)
    local cid = self[mobile_session_name]:SendRPC("UnregisterAppInterface",{})
    self[mobile_session_name]:ExpectResponse(cid, {success = true, resultCode = "SUCCESS"})
    common_functions:SetApplicationStatusIsUnRegistered(app_name, self)
  end
end
--------------------------------------------------------------------------------
-- Activate application
-- @param test_case_name: Test name
-- @param app_name: app name is activated
-- @param expected_level: HMI level should be changed to. If expected_level omitted, activate application to "FULL".
-- @param expected_on_hmi_status_for_other_applications: if it is omitted, this step does not verify OnHMIStatus for other application.
-- In case checking OnHMIStatus for other applications, use below structure to input for this parameter.
--[[{
app_name_2 = {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"},
app_name_3 = {hmiLevel = "NONE", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"},
app_name_n = {hmiLevel = "BACKGROUND", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"}
--}]]
--------------------------------------------------------------------------------
function CommonSteps:ActivateApplication(test_case_name, app_name, expected_level, expected_on_hmi_status_for_other_applications)
  Test[test_case_name] = function(self)
    expected_level = expected_level or "FULL"
    app_name = app_name or config.application1.registerAppInterfaceParams.appName
    local hmi_app_id = common_functions:GetHmiAppId(app_name, self)
    local audio_streaming_state = "NOT_AUDIBLE"
    if common_functions:IsMediaApp(app_name, self) then
      audio_streaming_state = "AUDIBLE"
    end
    local mobile_connect_name, mobile_session_name = common_functions:GetMobileConnectionNameAndSessionName(app_name, self)
    --local cid = self.hmiConnection:SendRequest("SDL.ActivateApp", {appID = hmi_app_id, level = expected_level})
    local cid = self.hmiConnection:SendRequest("SDL.ActivateApp", {appID = hmi_app_id})
    EXPECT_HMIRESPONSE(cid)
    :Do(function(_,data)
      -- if application is disallowed, HMI has to send SDL.OnAllowSDLFunctionality notification to allow before activation
      -- If isSDLAllowed is false, consent for sending policy table through specified device is required.
      if data.result.isSDLAllowed ~= true then
        self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = utils.getDeviceMAC(), name = utils.getDeviceName()}})
        EXPECT_HMICALL("BasicCommunication.ActivateApp")
        :Do(function(_,data)
            self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
          end)
      end
    end) -- :Do(function(_,data)

    self[mobile_session_name]:ExpectNotification("OnHMIStatus", {hmiLevel = expected_level, audioStreamingState = audio_streaming_state, systemContext = "MAIN"})
    -- Verify OnHMIStatus for other applications
    if expected_on_hmi_status_for_other_applications then
      for k_app_name, v in pairs(expected_on_hmi_status_for_other_applications) do
        local mobile_connection_name, mobile_session_name = common_functions:GetMobileConnectionNameAndSessionName(k_app_name, self)
        self[mobile_session_name]:ExpectNotification("OnHMIStatus", v)
        :Do(function(_,data)
            -- Store OnHMIStatus notification to use later
            common_functions:StoreHmiStatus(app_name, data.payload, self)
          end)
      end -- for k_app_name, v
    end -- if expected_on_hmi_status_for_other_applications then
  end
end
--------------------------------------------------------------------------------
-- Change hmiLevel to LIMITED
-- @param test_case_name: Test name
-- @param app_name: name of application is changed to limited
--------------------------------------------------------------------------------
function CommonSteps:ChangeHMIToLimited(test_case_name, app_name)
  Test[test_case_name] = function(self)
    local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
      {
        appID = common_functions:GetHmiAppId(app_name, self)
      })
    local mobile_connection_name, mobile_session_name = common_functions:GetMobileConnectionNameAndSessionName(app_name, self)
    self[mobile_session_name]:ExpectNotification("OnHMIStatus", {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
    :Do(function(_,data)
        -- Store OnHMIStatus notification to use later
        common_functions:StoreHmiStatus(app_name, data.payload, self)
      end)
  end
end
--------------------------------------------------------------------------------
-- Change hmiLevel to LIMITED
-- @param test_case_name: Test name
-- @param app_name: name of application is changed to limited
--------------------------------------------------------------------------------
function CommonSteps:ChangeHmiLevelToNone(test_case_name, app_name)
  Test[test_case_name] = function(self)
    local hmi_app_id = common_functions:GetHmiAppId(app_name, self)
    self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {appID = hmi_app_id, reason = "USER_EXIT"})
    local mobile_connection_name, mobile_session_name = common_functions:GetMobileConnectionNameAndSessionName(app_name, self)
    self[mobile_session_name]:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    :Do(function(_,data)
        -- Store OnHMIStatus notification to use later
        common_functions:StoreHmiStatus(app_name, data.payload, self)
      end)
  end
end

-- COMMON FUNCTIONS FOR HMI
--------------------------------------------------------------------------------
-- Initialize HMI
-- @param test_case_name: Test name
--------------------------------------------------------------------------------
function CommonSteps:InitializeHmi(test_case_name)
  Test[test_case_name] = function(self)
    self:initHMI()
  end
end
--------------------------------------------------------------------------------
-- HMI responds OnReady request from SDL
-- @param test_case_name: Test name
--------------------------------------------------------------------------------
function CommonSteps:HmiRespondOnReady(test_case_name)
  Test[test_case_name] = function(self)
    self:initHMI_onReady()
  end
end
--------------------------------------------------------------------------------
-- Ignition Off
-- @param test_case_name: Test name
--------------------------------------------------------------------------------
function CommonSteps:IgnitionOff(test_case_name)
  Test[test_case_name] = function(self)
    local sdl = require('SDL')
    if sdl:CheckStatusSDL() == sdl.RUNNING then
      self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
      EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
      :Do(function()
          self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", { reason = "IGNITION_OFF" })
          StopSDL()
        end)
      end
  end
end

--------------------------------------------------------------------------------
-- Ignition On: Start SDL, start HMI and add a mobile connection.
-- @param test_case_name: Test name
--------------------------------------------------------------------------------
function CommonSteps:IgnitionOn(test_case_name)
  CommonSteps:KillAllSdlProcesses(test_case_name .. "_KillAllSdlProcessesIfExist")
  CommonSteps:StartSDL(test_case_name .. "_StartSDL")
  CommonSteps:InitializeHmi(test_case_name.."_InitHMI")
  CommonSteps:HmiRespondOnReady(test_case_name.."_InitHMI_onReady")
  CommonSteps:AddMobileConnection(test_case_name.."_ConnectMobile", "mobileConnection")
end

-- COMMON FUNCTIONS FOR SDL
--------------------------------------------------------------------------------
-- Start SDL
-- @param test_case_name: Test name
--------------------------------------------------------------------------------
function CommonSteps:StartSDL(test_case_name)
  Test[test_case_name] = function(self)
    StartSDL(config.pathToSDL, config.ExitOnCrash)
  end
end
--------------------------------------------------------------------------------
-- Stop SDL
-- @param test_case_name: Test name
--------------------------------------------------------------------------------
function CommonSteps:StopSDL(test_case_name)
  Test[test_case_name] = function(self)
    StopSDL()
  end
end

-- COMMON FUNCTIONS FOR POST-CONDITION
--------------------------------------------------------------------------------
-- make reserve copy of file (FileName) in /bin folder
-- @param test_case_name: Test name
-- @param file_name: file in /bin folder to backup
--------------------------------------------------------------------------------
function CommonSteps:BackupFile(test_case_name, file_name)
  Test[test_case_name] = function(self)
    os.execute(" cp " .. config.pathToSDL .. file_name .. " " .. config.pathToSDL .. file_name .. "_origin" )
  end
end

--------------------------------------------------------------------------------
-- make reserve copy of file (FileName) in /bin folder
-- @param test_case_name: Test name
-- @param file_name: file in /bin folder to backup
--------------------------------------------------------------------------------
function CommonSteps:SetValuesInIniFile(test_case_name, find_expression, parameter_name, value_to_update)
  Test[test_case_name] = function(self)
    common_functions:SetValuesInIniFile(find_expression, parameter_name, value_to_update)
  end
end

--------------------------------------------------------------------------------
-- Restore smartDeviceLink.ini File
-- @param test_case_name: Test name
-- @param file_name: if it is omitted, restore "smartDeviceLink.ini"
--------------------------------------------------------------------------------
function CommonSteps:RestoreIniFile(test_case_name, file_name)
  Test[test_case_name] = function(self)
    file_name = file_name or "smartDeviceLink.ini"
    os.execute(" cp " .. config.pathToSDL .. file_name .. "_origin " .. config.pathToSDL .. file_name )
  end
end
--------------------------------------------------------------------------------
-- Precondition steps:
-- @param test_case_name: Test name
-- @param number_of_precondition_steps: Number from 1 to 7:
-- 1: Include step StartSDL
-- 2: Include step StartSDL and InitHMI
-- 3: Include steps StartSDL, InitHMI and InitHMI_OnReady
-- 4: Include steps StartSDL, InitHMI, InitHMI_OnReady and AddMobileConnection
-- 5: Include steps StartSDL, InitHMI, InitHMI_OnReady, AddMobileConnection and AddMobileSession
-- 6: Include steps StartSDL, InitHMI, InitHMI_OnReady, AddMobileConnection, AddMobileSession and RegisterApp
-- 7: Include steps StartSDL, InitHMI, InitHMI_OnReady, AddMobileConnection, AddMobileSession, RegisterApp and ActivateApp
--------------------------------------------------------------------------------
function CommonSteps:PreconditionSteps(test_case_name, number_of_precondition_steps)
  local mobile_connection_name = "mobileConnection"
  local mobile_session_name = "mobileSession"
  local app = config.application1.registerAppInterfaceParams
  CommonSteps:KillAllSdlProcesses(test_case_name .. "_KillAllSdlProcessesIfExist")
  if number_of_precondition_steps >= 1 then
    CommonSteps:StartSDL(test_case_name .. "_StartSDL")
  end
  if number_of_precondition_steps >= 2 then
    CommonSteps:InitializeHmi(test_case_name .. "_InitHMI")
  end
  if number_of_precondition_steps >= 3 then
    CommonSteps:HmiRespondOnReady(test_case_name .. "_InitHMI_onReady")
  end
  if number_of_precondition_steps >= 4 then
    CommonSteps:AddMobileConnection(test_case_name .. "_AddDefaultMobileConnection_" .. mobile_connection_name, mobile_connection_name)
  end
  if number_of_precondition_steps >= 5 then
    CommonSteps:AddMobileSession(test_case_name .. "_AddDefaultMobileConnect_" .. mobile_session_name, mobile_connection_name, mobile_session_name)
  end
  if number_of_precondition_steps >= 6 then
    CommonSteps:RegisterApplication(test_case_name .. "_Register_App", mobile_session_name)
  end
  if number_of_precondition_steps >= 7 then
    CommonSteps:ActivateApplication(test_case_name .. "_Activate_App", app.appName)
  end
end

--------------------------------------------------------------------------------
-- Kill all SDL processes
-- @param test_case_name: is optional
--------------------------------------------------------------------------------
function CommonSteps:KillAllSdlProcesses(test_case_name)
  test_case_name = test_case_name or "KillAllSDLProcesses"
  Test[test_case_name] = function(self)
    common_functions:KillAllSdlProcesses()
    if common_functions:IsFileExist("sdl.pid") then
      os.remove("sdl.pid")
    end
  end
end

-- Print some empty line on ATF console and a message to help log on ATF console is split between some step
function CommonSteps:AddNewTestCasesGroup(ParameterOrMessage)
  NewTestSuiteNumber = NewTestSuiteNumber or 0
  NewTestSuiteNumber = NewTestSuiteNumber + 1
  local message = ""
  --Print new lines to separate test cases group in test report
  if ParameterOrMessage == nil then
    message = "Test Suite For Parameter:"
  elseif type(ParameterOrMessage)=="table" then
    local Parameter = ParameterOrMessage
    for i = 1, #Parameter do
      if type(Parameter[i]) == "number" then
        message = message .. "[" .. tostring(Parameter[i]) .. "]"
      else
        if message == "" then
          message = tostring(Parameter[i])
        else
          local len = string.len(message)
          if string.sub(message, len -1, len) == "]" then
            message = message .. tostring(Parameter[i])
          else
            message = message .. "." .. tostring(Parameter[i])
          end
        end
      end
    end
    message = "Test Suite For Parameter: " .. message
  else
    message = ParameterOrMessage
  end

  Test["Suite_" .. tostring(NewTestSuiteNumber)] = function(self)
    local length = 80
    local spaces = length - string.len(message)
    local line1 = message
    local line2 = string.rep("-", length)
    print("\27[33m" .. line2 .. "\27[0m")
    print("")
    print("")
    print("\27[33m" .. line1 .. "\27[0m")
    print("\27[33m" .. line2 .. "\27[0m")
  end
end

--------------------------------------------------------------------------------
-- Put file to HMI
-- @param test_case_name: is optional
-- @param file_name: new file name for HMI side
--------------------------------------------------------------------------------
function CommonSteps:PutFile(test_case_name, file_name)
  test_case_name = test_case_name or "PutFile_" .. tostring(file_name)
  Test[test_case_name] = function(self)
    local CorIdPutFile = self.mobileSession:SendRPC(
      "PutFile",
      {
        syncFileName = file_name,
        fileType = "GRAPHIC_PNG",
        persistentFile = false,
        systemFile = false,
      }, "files/icon.png")

    EXPECT_RESPONSE(CorIdPutFile, { success = true, resultCode = "SUCCESS"})
  end
end

--11. Check file existence
function CommonSteps:FileExisted(name)
   	local f=io.open(name,"r")

   	if f ~= nil then
   		io.close(f)
   		return true
   	else
   		return false
   	end
end


function CommonSteps:Sleep(test_case_name, sec)
   Test[test_case_name] = function(self)
    os.execute("sleep " .. sec)
  end
end

function CommonSteps:RemoveFileInSdlBinFolder(test_case_name, file_name)
  Test[test_case_name] = function(self)
    if common_functions:IsFileExist(config.pathToSDL .. file_name) then
      os.remove(config.pathToSDL .. file_name)
    end
  end
end
-- Execute query to insert/ update/ delete data to LPT
function CommonSteps:ModifyLocalPolicyTable(test_case_name, sql_query)
  Test[test_case_name] = function(self)
    local policy_file = config.pathToSDL .. "storage/policy.sqlite"
    local policy_file_temp = "/tmp/policy.sqlite"
    os.execute("cp " .. policy_file .. " " .. policy_file_temp)
    ful_sql_query = "sqlite3 " .. policy_file_temp .. " \"" .. sql_query .. "\""
    handler = io.popen(ful_sql_query, 'r')
    handler:close()
    os.execute("sleep 1")
    os.execute("cp " .. policy_file_temp .. " " .. policy_file)
    os.execute("rm -rf " .. policy_file_temp)
  end
end
return CommonSteps
