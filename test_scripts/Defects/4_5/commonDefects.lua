---------------------------------------------------------------------------------------------------
-- RC common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
-- define MAC address mobile device
config.mobileHost = "127.0.0.1"
-- define 2nd version of SDL protocol by default
config.defaultProtocolVersion = 2
-- switch off schema validation for output messages against APIs
config.ValidateSchema = false

--[[ Required Shared libraries ]]
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local commonTestCases = require("user_modules/shared_testcases/commonTestCases")
local sdl = require("SDL")
local mobile_session = require("mobile_session")
local events = require("events")
local json = require("modules/json")
local utils = require ('user_modules/utils')

--[[ Local Variables ]]

-- table with data for Policy Table Update
local ptu_table = {}
-- table with HMI application identifiers
local hmiAppIds = {}
-- table for module
local commonDefect = {}

--[[ Module Constants ]]

-- default timeout
commonDefect.timeout = 2000
-- minimal timeout
commonDefect.minTimeout = 500

--[[ @getPTUFromPTS: create policy table update table (PTU)
--! @parameters:
--! tbl - table with policy table snapshot (PTS)
--! @return: table with PTU
--]]
local function getPTUFromPTS(tbl)
  tbl.policy_table.consumer_friendly_messages.messages = nil
  tbl.policy_table.device_data = nil
  tbl.policy_table.module_meta = nil
  tbl.policy_table.usage_and_error_counts = nil
  tbl.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  tbl.policy_table.module_config.preloaded_pt = nil
  tbl.policy_table.module_config.preloaded_date = nil
  tbl.policy_table.vehicle_data = nil
end

--[[ @DefaultStruct: provide default values for application required in PTU
--! @parameters: none
--! @return: table with data
--]]
function commonDefect.DefaultStruct()
  return {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = { "Base-4"},
  }
end

--[[ @updatePTU: update PTU with application data
--! @parameters:
--! tbl - table with data for policy table update
--! @return: none
--]]
local function updatePTU(tbl)
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID] = commonDefect.DefaultStruct()
end

--[[ @jsonFileToTable: convert .json file to table
--! @parameters:
--! file_name - file name
--! @return: table
--]]
local function jsonFileToTable(file_name)
  local f = io.open(file_name, "r")
  local content = f:read("*all")
  f:close()
  return json.decode(content)
end

--[[ @tableToJsonFile: convert table to .json file
--! @parameters:
--! tbl - table
--! file_name - file name
--! @return: none
--]]
local function tableToJsonFile(tbl, file_name)
  local f = io.open(file_name, "w")
  f:write(json.encode(tbl))
  f:close()
end

--[[ @ptu: perform policy table update
--! @parameters:
--! self - test object
--! ptu_update_func - additional function for update
--! @return: none
--]]
local function ptu(self, ptu_update_func)
  local function getAppsCount()
    local count = 0
    for _, _ in pairs(hmiAppIds) do
      count = count + 1
    end
    return count
  end

  local policy_file_name = "PolicyTableUpdate"
  local policy_file_path = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")
  local pts_file_name = commonFunctions:read_parameter_from_smart_device_link_ini("PathToSnapshot")
  local ptu_file_name = os.tmpname()
  local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  EXPECT_HMIRESPONSE(requestId)
  :Do(function()
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
        { requestType = "PROPRIETARY", fileName = pts_file_name })
      getPTUFromPTS(ptu_table)
      updatePTU(ptu_table)
      if ptu_update_func then
        ptu_update_func(ptu_table)
      end
      tableToJsonFile(ptu_table, ptu_file_name)

      local event = events.Event()
      event.matches = function(e1, e2) return e1 == e2 end
      EXPECT_EVENT(event, "PTU event")
      :Timeout(11000)

      for id = 1, getAppsCount() do
        local mobileSession = commonDefect.getMobileSession(self, id)
        mobileSession:ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
        :Do(function(_, d2)
            print("App ".. id .. " was used for PTU")
            RAISE_EVENT(event, event, "PTU event")
            local corIdSystemRequest = mobileSession:SendRPC("SystemRequest",
              { requestType = "PROPRIETARY", fileName = policy_file_name }, ptu_file_name)
            EXPECT_HMICALL("BasicCommunication.SystemRequest")
            :Do(function(_, d3)
                self.hmiConnection:SendResponse(d3.id, "BasicCommunication.SystemRequest", "SUCCESS", { })
                self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
                  { policyfile = policy_file_path .. "/" .. policy_file_name })
              end)
            mobileSession:ExpectResponse(corIdSystemRequest, { success = true, resultCode = "SUCCESS" })
            :Do(function() os.remove(ptu_file_name) end)
          end)
        :Times(AtMost(1))
      end
    end)
end

--[[ @getDeviceName: provides device name
--! @parameters: none
--! @return: device name
--]]
commonDefect.getDeviceName = utils.getDeviceName

--[[ @getDeviceMAC: provides device MAC address
--! @parameters: none
--! @return: device MAC address
--]]
commonDefect.getDeviceMAC = utils.getDeviceMAC

--[[ @allow_sdl: sequence that allows SDL functionality
--! @parameters:
--! self - test object
--! @return: none
--]]
function commonDefect.allow_sdl(self)
  -- sending notification OnAllowSDLFunctionality from HMI to allow connected device
  self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {
    allowed = true,
    source = "GUI",
    device = {
      id = commonDefect.getDeviceMAC(),
      name = commonDefect.getDeviceName()
    }
  })
  commonDefect.delayedExp(commonDefect.minTimeout)
end

--[[ @preconditions: precondition steps
--! @parameters: none
--! @return: none
--]]
function commonDefect.preconditions()
  commonFunctions:SDLForceStop()
  commonSteps:DeletePolicyTable()
  commonSteps:DeleteLogsFiles()
end

--[[ @start: starting sequence: starting of SDL, initialization of HMI, connect mobile
--! @parameters:
--! self - test object
--! @return: none
--]]
function commonDefect.start(self)
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
                  commonDefect.allow_sdl(self)
                end)
            end)
        end)
    end)
end

--[[ @startWithoutMobile: starting sequence: starting of SDL, initialization of HMI
--! @parameters:
--! self - test object
--! @return: none
--]]
function commonDefect.startWithoutMobile(pHMIParams, self)
  self, pHMIParams = commonDefect.getSelfAndParams(pHMIParams, self)
  self:runSDL()
  commonFunctions:waitForSDLStart(self)
  :Do(function()
      self:initHMI(self)
      :Do(function()
          commonFunctions:userPrint(35, "HMI initialized")
          self:initHMI_onReady(pHMIParams)
          :Do(function()
              commonFunctions:userPrint(35, "HMI is ready")
            end)
        end)
    end)
end

--[[ @postconditions: postcondition steps
--! @parameters: none
--! @return: none
--]]
function commonDefect.postconditions()
  StopSDL()
end

--[[ @printSDLConfig: print information about SDL build options
--! @parameters: none
--! @return: none
--]]
function commonDefect.printSDLConfig()
  commonFunctions:printTable(sdl.buildOptions)
end

--[[ @ignitionOff: IGNITION_OFF sequence
--! @parameters:
--! self - test object
--! @return: none
--]]
function commonDefect.ignitionOff(self)
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
      sdl:DeleteFile()
      self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", { reason = "IGNITION_OFF" })
      self.mobileSession1:ExpectNotification("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
      EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")
      :Do(function()
          StopSDL()
        end)
    end)
end

--[[ @backupINIFile: backup SDL .ini file
--! @parameters: none
--! @return: none
--]]
function commonDefect.backupINIFile()
  commonPreconditions:BackupFile("smartDeviceLink.ini")
end

--[[ @restoreINIFile: restore SDL .ini file to an initial state
--! @parameters: none
--! @return: none
--]]
function commonDefect.restoreINIFile()
  commonPreconditions:RestoreFile("smartDeviceLink.ini")
end

--[[ @rai_ptu: register mobile application and perform PTU sequence for 1st application
--! @parameters:
--! ptu_update_func - additional function for update
--! self - test object
--! @return: none
--]]
function commonDefect.rai_ptu(ptu_update_func, self)
  self, ptu_update_func = commonDefect.getSelfAndParams(ptu_update_func, self)
  commonDefect.rai_ptu_n(1, ptu_update_func, self)
end

--[[ @rai_ptu_n: register mobile application and perform PTU sequence for N application
--! @parameters:
--! id - application number (1, 2, etc.)
--! ptu_update_func - additional function for update
--! self - test object
--! @return: none
--]]
function commonDefect.rai_ptu_n(id, ptu_update_func, self)
  self, id, ptu_update_func = commonDefect.getSelfAndParams(id, ptu_update_func, self)
  if not id then id = 1 end
  self["mobileSession" .. id] = mobile_session.MobileSession(self, self.mobileConnection)
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate",
    { status = "UPDATE_NEEDED" }, { status = "UPDATING" }, { status = "UP_TO_DATE" })
  :Times(3)
  self["mobileSession" .. id]:StartService(7)
  :Do(function()
      local corId = self["mobileSession" .. id]:SendRPC
      ("RegisterAppInterface", config["application" .. id].registerAppInterfaceParams)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
        { application = { appName = config["application" .. id].registerAppInterfaceParams.appName } })
      :Do(function(_, d1)
          hmiAppIds[config["application" .. id].registerAppInterfaceParams.fullAppID] = d1.params.application.appID
          EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
          :DoOnce(function(_, d2)
              self.hmiConnection:SendResponse(d2.id, d2.method, "SUCCESS", { })
              ptu_table = jsonFileToTable(d2.params.file)
              ptu(self, ptu_update_func)
            end)
        end)
      self["mobileSession" .. id]:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          self["mobileSession" .. id]:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          :Times(AtLeast(1))
          self["mobileSession" .. id]:ExpectNotification("OnPermissionsChange")
          :Times(AtLeast(1))
          EXPECT_HMICALL("VehicleInfo.GetVehicleData", { odometer = true })
        end)
    end)
end

--[[ @rai_ptu_n_without_OnPermissionsChange: register mobile application and perform PTU sequence for N application
--! 'OnPermissionsChange' notification is excluded from expectations
--! @parameters:
--! id - application number (1, 2, etc.)
--! ptu_update_func - additional function for update
--! self - test object
--! @return: none
--]]
function commonDefect.rai_ptu_n_without_OnPermissionsChange(id, ptu_update_func, self)
  self, id, ptu_update_func = commonDefect.getSelfAndParams(id, ptu_update_func, self)
  if not id then id = 1 end
  self["mobileSession" .. id] = mobile_session.MobileSession(self, self.mobileConnection)
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate",
    { status = "UPDATE_NEEDED" }, { status = "UPDATING" }, { status = "UP_TO_DATE" })
  :Times(3)
  self["mobileSession" .. id]:StartService(7)
  :Do(function()
      local corId = self["mobileSession" .. id]:SendRPC
      ("RegisterAppInterface", config["application" .. id].registerAppInterfaceParams)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
        { application = { appName = config["application" .. id].registerAppInterfaceParams.appName } })
      :Do(function(_, d1)
          hmiAppIds[config["application" .. id].registerAppInterfaceParams.fullAppID] = d1.params.application.appID
          EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
          :DoOnce(function(_, d2)
              self.hmiConnection:SendResponse(d2.id, d2.method, "SUCCESS", { })
              ptu_table = jsonFileToTable(d2.params.file)
              ptu(self, ptu_update_func)
            end)
        end)
      self["mobileSession" .. id]:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          self["mobileSession" .. id]:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          :Times(AtLeast(1))
          EXPECT_HMICALL("VehicleInfo.GetVehicleData", { odometer = true })
        end)
    end)
end

--[[ @UnsuccessPTU: perform PTU sequence with failed result
--! @parameters:
--! ptu_update_func - additional function for update
--! self - test object
--! @return: none
--]]
function commonDefect.unsuccessfulPTU(ptu_update_func, expec_func, self)
  expec_func()
  ptu(self, ptu_update_func)
end

--[[ @rai_n: register N mobile application without PTU sequence
--! @parameters:
--! id - application number (1, 2, etc.)
--! self - test object
--! @return: none
--]]
function commonDefect.rai_n(id, expect_dd, self)
  self, id, expect_dd = commonDefect.getSelfAndParams(id, expect_dd, self)
  if not id then id = 1 end
  if expect_dd == nil then expect_dd = true end
  self["mobileSession" .. id] = mobile_session.MobileSession(self, self.mobileConnection)
  self["mobileSession" .. id]:StartService(7)
  :Do(function()
      local corId = self["mobileSession" .. id]:SendRPC
      ("RegisterAppInterface", config["application" .. id].registerAppInterfaceParams)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
        { application = { appName = config["application" .. id].registerAppInterfaceParams.appName } })
      :Do(function(_, d1)
          hmiAppIds[config["application" .. id].registerAppInterfaceParams.fullAppID] = d1.params.application.appID
        end)
      self["mobileSession" .. id]:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          self["mobileSession" .. id]:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          :Times(AtLeast(1))
          self["mobileSession" .. id]:ExpectNotification("OnPermissionsChange")
          :Times(AtLeast(1))
          if expect_dd then
            self["mobileSession" .. id]:ExpectNotification("OnDriverDistraction", { state = "DD_OFF" })
          else
            self["mobileSession" .. id]:ExpectNotification("OnDriverDistraction"):Times(0)
          end
        end)
    end)
end

--[[ @delayedExp: delay test step for defined timeout
--! @parameters:
--! timeout - time of delay in milliseconds
--! @return: none
--]]
function commonDefect.delayedExp(timeout)
  if not timeout then timeout = commonDefect.timeout end
  commonTestCases:DelayedExp(timeout)
end

--[[ @unregisterApp: unregister application
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! self - test object
--! @return: none
--]]
function commonDefect.unregisterApp(pAppId, self)
  self, pAppId = commonDefect.getSelfAndParams(pAppId, self)
  if not pAppId then pAppId = 1 end
  local mobSession = commonDefect.getMobileSession(self, pAppId)
  local hmiAppId = commonDefect.getHMIAppId(pAppId)
  local cid = mobSession:SendRPC("UnregisterAppInterface",{})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { appID = hmiAppId, unexpectedDisconnect = false })
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end

--[[ @activate_app: activate application
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! self - test object
--! @return: none
--]]
function commonDefect.activate_app(pAppId, self)
  self, pAppId = commonDefect.getSelfAndParams(pAppId, self)
  if not pAppId then pAppId = 1 end
  local pHMIAppId = hmiAppIds[config["application" .. pAppId].registerAppInterfaceParams.fullAppID]
  local mobSession = commonDefect.getMobileSession(self, pAppId)
  local requestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = pHMIAppId })
  EXPECT_HMIRESPONSE(requestId)
  mobSession:ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
  commonTestCases:DelayedExp(commonDefect.minTimeout)
end

--[[ @putFile: perform PutFile sequence
--! @parameters:
--! pFileName - name of the file
--! self - test object
--! @return: none
--]]
function commonDefect.putFile(pFileName, self)
  self, pFileName = commonDefect.getSelfAndParams(pFileName, self)
  local cid = self.mobileSession1:SendRPC(
    "PutFile",
    {syncFileName = pFileName, fileType = "GRAPHIC_PNG", persistentFile = false, systemFile = false},
  "files/icon.png")

  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end

--[[ @getSelfAndParams: shifting parameters in order to move self at 1st position
--! @parameters:
--! ... - various parameters and self
--! @return: test object and other parameters
--]]
function commonDefect.getSelfAndParams(...)
  local out = { }
  local selfIdx = nil
  for i,v in pairs({...}) do
    if type(v) == "table" and v.isTest then
      table.insert(out, v)
      selfIdx = i
      break
    end
  end
  local idx = 2
  for i = 1, table.maxn({...}) do
    if i ~= selfIdx then
      out[idx] = ({...})[i]
      idx = idx + 1
    end
  end
  return table.unpack(out, 1, table.maxn(out))
end

--[[ @getHMIAppId: get HMI application identifier
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: application identifier
--]]
function commonDefect.getHMIAppId(pAppId)
  if not pAppId then pAppId = 1 end
  return hmiAppIds[config["application" .. pAppId].registerAppInterfaceParams.fullAppID]
end

--[[ @getMobileSession: get mobile session
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! self - test object
--! @return: mobile session
--]]
function commonDefect.getMobileSession(self, pAppId)
  if not pAppId then pAppId = 1 end
  return self["mobileSession" .. pAppId]
end

--[[ @ptu: perform policy table update
--! @parameters:
--! pUpdateFunction - additional function for update
--! self - test object
--! @return: mobile session
--]]
function commonDefect.ptu(pUpdateFunction, self)
  ptu(self, pUpdateFunction)
end

return commonDefect
