local ATF = require('ATF')
require('atf.util')
local module = require('testbase')
local mobile = require("mobile_connection")
local mobile_adapter_controller = require("mobile_adapter/mobile_adapter_controller")
local file_connection = require("file_connection")
local mobile_session = require("mobile_session")
local hmi_connection = require('hmi_connection')
local events = require("events")
local expectations = require('expectations')
local functionId = require('function_id')
local SDL = require('SDL')
local exit_codes = require('exit_codes')
local load_schema = require('load_schema')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local hmi_values = require("user_modules/hmi_values")
local mob_schema = load_schema.mob_schema
local hmi_schema = load_schema.hmi_schema
local hmi_adapter_controller = require("hmi_adapter/hmi_adapter_controller")
local Event = events.Event

local Expectation = expectations.Expectation
local SUCCESS = expectations.SUCCESS
local FAILED = expectations.FAILED
local utils = require("user_modules/utils")

--- HMI connection
module.hmiConnection = hmi_connection.Connection(hmi_adapter_controller.getHmiAdapter({connection = ATF.remoteConnection}))

--- Default mobile connection
module.getDefaultMobileAdapter = mobile_adapter_controller.getDefaultAdapter

local mobileAdapter = module.getDefaultMobileAdapter()
local fileConnection = file_connection.FileConnection("mobile.out", mobileAdapter)
module.mobileConnection = mobile.MobileConnection(fileConnection)

event_dispatcher:AddConnection(module.hmiConnection)
event_dispatcher:AddConnection(module.mobileConnection)

--- Notification counter
module.notification_counter = 1
module.sdlBuildOptions = SDL.buildOptions

function module.hmiConnection:EXPECT_HMIRESPONSE(id, args)
  local event = events.Event()
  event.matches = function(self, data)
    return  data["method"] == nil and data.id == id
  end
  local ret = Expectation("HMI response " .. id, self)
  ret:ValidIf(function(self, data)
      local arguments
      if self.occurences > #args then
        arguments = args[#args]
      else
        arguments = args[self.occurences]
      end
      xmlReporter.AddMessage("EXPECT_HMIRESPONSE", {["Id"] = tostring(id),["Type"] = "EXPECTED_RESULT"},arguments)
      xmlReporter.AddMessage("EXPECT_HMIRESPONSE", {["Id"] = tostring(id),["Type"] = "AVALIABLE_RESULT"},data)
      local func_name = data.method
      local results_args = arguments
      if(table2str(arguments):match('result')) then
        results_args = arguments.result
      elseif(table2str(arguments):match('error')) then
        results_args = arguments.error
      end
      if func_name == nil and type(data.result) == 'table' then
        func_name = data.result.method
      elseif func_name == nil and type(data.error) == 'table' then
        print_table(data)
        func_name = data.error.data.method
      end
      local _res, _err
      _res = true
      if not (table2str(arguments):match('error')) then
        _res, _err = hmi_schema:Validate(func_name, load_schema.response, data.params)
      end
      if (not _res) then
        return _res,_err
      end
      if func_name and results_args and data.result then
        return compareValues(results_args, data.result, "result")
      elseif func_name and results_args and data.error then
        return compareValues(results_args, data.error, "error")
      else
        return compareValues(results_args, data.params, "params")
      end
    end)
  ret.event = event
  event_dispatcher:AddEvent(module.hmiConnection, event, ret)
  module:AddExpectation(ret)
  return ret
end

function EXPECT_HMIRESPONSE(id,...)
  local args = table.pack(...)
  return module.hmiConnection:EXPECT_HMIRESPONSE(id, args)
end

function EXPECT_HMINOTIFICATION(name,...)
  local args = table.pack(...)
  local event = events.Event()
  event.matches = function(self, data) return data.method == name end
  local ret = Expectation("HMI notification " .. name, module.hmiConnection)
  if #args > 0 then
    ret:ValidIf(function(self, data)
        local arguments
        if self.occurences > #args then
          arguments = args[#args]
        else
          arguments = args[self.occurences]
        end
        local correlation_id = module.notification_counter
        module.notification_counter = module.notification_counter + 1
        xmlReporter.AddMessage("EXPECT_HMINOTIFICATION", {["Id"] = correlation_id, ["name"] = tostring(name),["Type"] = "EXPECTED_RESULT"},arguments)
        xmlReporter.AddMessage("EXPECT_HMINOTIFICATION", {["Id"] = correlation_id, ["name"] = tostring(name),["Type"] = "AVALIABLE_RESULT"},data)
        local _res, _err = hmi_schema:Validate(name, load_schema.notification, data.params)
        if (not _res) then return _res,_err end
        return compareValues(arguments, data.params, "params")
      end)
  end
  ret.event = event
  event_dispatcher:AddEvent(module.hmiConnection, event, ret)
  module:AddExpectation(ret)
  return ret
end

function EXPECT_HMICALL(methodName, ...)
  local args = table.pack(...)
  -- TODO: Avoid copy-paste
  local event = events.Event()
  event.matches =
  function(self, data) return data.method == methodName end
  local ret = Expectation("HMI call " .. methodName, module.hmiConnection)
  if #args > 0 then
    ret:ValidIf(function(self, data)
        local arguments
        if self.occurences > #args then
          arguments = args[#args]
        else
          arguments = args[self.occurences]
        end
        xmlReporter.AddMessage("EXPECT_HMICALL", {["Id"] = data.id, ["name"] = tostring(methodName),["Type"] = "EXPECTED_RESULT"},arguments)
        xmlReporter.AddMessage("EXPECT_HMICALL", {["Id"] = data.id, ["name"] = tostring(methodName),["Type"] = "AVALIABLE_RESULT"},data.params)
        _res, _err = hmi_schema:Validate(methodName, load_schema.request, data.params)
        if (not _res) then return _res,_err end
        return compareValues(arguments, data.params, "params")
      end)
  end
  ret.event = event
  event_dispatcher:AddEvent(module.hmiConnection, event, ret)
  module:AddExpectation(ret)
  return ret
end

function EXPECT_NOTIFICATION(func,...)
  local args = table.pack(...)
  local args_count = 1
  if #args > 0 then
    local arguments = {}
    if #args > 1 then
      for args_count = 1, #args do
        if(type( args[args_count])) == 'table' then
          table.insert(arguments, args[args_count])
        end
      end
    else
      arguments = args
    end
    return module.mobileSession:ExpectNotification(func,arguments)
  end
  return module.mobileSession:ExpectNotification(func,args)

end

function EXPECT_ANY_SESSION_NOTIFICATION(funcName, ...)
  local args = table.pack(...)
  local event = events.Event()
  event.matches = function(_, data)
    return data.rpcFunctionId == functionId[funcName]
  end
  local ret = Expectation(funcName .. " notification", module.mobileConnection)
  if #args > 0 then
    ret:ValidIf(function(self, data)
        local arguments
        if self.occurences > #args then
          arguments = args[#args]
        else
          arguments = args[self.occurences]
        end
        local _res, _err = mob_schema:Validate(funcName, load_schema.notification, data.payload)
        xmlReporter.AddMessage("EXPECT_ANY_SESSION_NOTIFICATION", {["name"] = tostring(funcName),["Type"]= "EXPECTED_RESULT"}, arguments)
        xmlReporter.AddMessage("EXPECT_ANY_SESSION_NOTIFICATION", {["name"] = tostring(funcName),["Type"]= "AVALIABLE_RESULT"}, data.payload)
        if (not _res) then return _res,_err end
        return compareValues(arguments, data.payload, "payload")
      end)
  end
  ret.event = event
  event_dispatcher:AddEvent(module.mobileConnection, event, ret)
  module.expectations_list:Add(ret)
  return ret
end

module.timers = { }

function RUN_AFTER(func, timeout, funcName)
  func_name_str = "noname"
  if funcName then
    func_name_str = funcName
  end
  xmlReporter.AddMessage(debug.getinfo(1, "n").name, func_name_str,
    {["functionLine"] = debug.getinfo(func, "S").linedefined, ["Timeout"] = tostring(timeout)})
  local d = qt.dynamic()
  d.timeout = function(self)
    func()
    module.timers[self] = nil
  end
  local timer = timers.Timer()
  module.timers[timer] = true
  qt.connect(timer, "timeout()", d, "timeout()")
  timer:setSingleShot(true)
  timer:start(timeout)
end

function EXPECT_RESPONSE(correlationId, ...)
  xmlReporter.AddMessage(debug.getinfo(1, "n").name, "EXPECTED_RESULT", ... )
  return module.mobileSession:ExpectResponse(correlationId, ...)
end

function EXPECT_ANY_SESSION_RESPONSE(correlationId, ...)
  xmlReporter.AddMessage(debug.getinfo(1, "n").name, {["CorrelationId"] = tostring(correlationId)})
  local args = table.pack(...)
  local event = events.Event()
  event.matches = function(_, data)
    return data.rpcCorrelationId == correlationId
  end
  local ret = Expectation("response to " .. correlationId, module.mobileConnection)
  if #args > 0 then
    ret:ValidIf(function(self, data)
        local arguments
        if self.occurences > #args then
          arguments = args[#args]
        else
          arguments = args[self.occurences]
        end
        xmlReporter.AddMessage("EXPECT_ANY_SESSION_RESPONSE", "EXPECTED_RESULT", arguments)
        xmlReporter.AddMessage("EXPECT_ANY_SESSION_RESPONSE", "AVALIABLE_RESULT", data.payload)
        return compareValues(arguments, data.payload, "payload")
      end)
  end
  ret.event = event
  event_dispatcher:AddEvent(module.mobileConnection, event, ret)
  module.expectations_list:Add(ret)
  return ret
end

function EXPECT_ANY()
  xmlReporter.AddMessage(debug.getinfo(1, "n").name, '')
  return module.mobileSession:ExpectAny()
end

function EXPECT_EVENT(event, name)
  local ret = Expectation(name, module.mobileConnection)
  ret.event = event
  event_dispatcher:AddEvent(module.mobileConnection, event, ret)
  module:AddExpectation(ret)
  return ret
end

function RAISE_EVENT(event, data, eventName)
  event_str = "noname"
  if eventName then
    event_str = eventName
  end
  xmlReporter.AddMessage(debug.getinfo(1, "n").name, event_str)
  event_dispatcher:RaiseEvent(module.mobileConnection, data)
end

function EXPECT_HMIEVENT(event, name)
  local ret = Expectation(name, module.hmiConnection)
  ret.event = event
  event_dispatcher:AddEvent(module.hmiConnection, event, ret)
  module:AddExpectation(ret)
  return ret
end

function StartSDL(SDLPathName, ExitOnCrash)
  return SDL:StartSDL(SDLPathName, config.SDL, ExitOnCrash)
end

function StopSDL()
  event_dispatcher:ClearEvents()
  module.expectations_list:Clear()
  return SDL:StopSDL()
end

function module:runSDL()
  event_dispatcher:ClearEvents()
  module.expectations_list:Clear()
  if config.autorunSDL ~= true then
    SDL.autoStarted = false
    return
  end
  local result, errmsg = SDL:StartSDL(config.pathToSDL, config.SDL, config.ExitOnCrash)
  if not result then
    quit(exit_codes.aborted)
  end
  SDL.autoStarted = true
end

function module:initHMI()
  local exp_waiter = commonFunctions:createMultipleExpectationsWaiter(module, "HMI initialization")
  local function registerComponent(name, subscriptions)
    local rid = module.hmiConnection:SendRequest("MB.registerComponent", { componentName = name })
    local exp = EXPECT_HMIRESPONSE(rid)
    exp_waiter:AddExpectation(exp)
    if subscriptions then
      for _, s in ipairs(subscriptions) do
        exp:Do(function(_, data)
            local rid = module.hmiConnection:SendRequest("MB.subscribeTo", { propertyName = s })
            local exp = EXPECT_HMIRESPONSE(rid)
            exp_waiter:AddExpectation(exp)
          end)
      end
    end
  end

  local web_socket_connected_event = EXPECT_HMIEVENT(events.connectedEvent, "Connected websocket")
  :Do(function()
      registerComponent("Buttons")
      registerComponent("TTS")
      registerComponent("VR")
      registerComponent("BasicCommunication",
        {
          "BasicCommunication.OnPutFile",
          "SDL.OnStatusUpdate",
          "SDL.OnAppPermissionChanged",
          "BasicCommunication.OnSDLPersistenceComplete",
          "BasicCommunication.OnFileRemoved",
          "BasicCommunication.OnAppRegistered",
          "BasicCommunication.OnAppUnregistered",
          "BasicCommunication.PlayTone",
          "BasicCommunication.OnSDLClose",
          "SDL.OnSDLConsentNeeded",
          "BasicCommunication.OnResumeAudioSource",
          "BasicCommunication.OnSystemTimeReady",
          "BasicCommunication.OnSystemCapabilityUpdated",
          "BasicCommunication.OnServiceUpdate",
          "BasicCommunication.OnAppPropertiesChange",
          "BasicCommunication.OnAppCapabilityUpdated"
        })
      registerComponent("UI",
        {
          "UI.OnRecordStart"
        })
      registerComponent("VehicleInfo")
      registerComponent("RC",
        {
          "RC.OnRCStatus"
        })
      registerComponent("Navigation",
        {
          "Navigation.OnAudioDataStreaming",
          "Navigation.OnVideoDataStreaming"
        })
      registerComponent("AppService",
        {
          "AppService.OnAppServiceData"
        })
    end)
  exp_waiter:AddExpectation(web_socket_connected_event)

  self.hmiConnection:Connect()
  return exp_waiter.expectation
end

--[[ @initHMI_onReady: the function is HMI's onReady response
--! @parameters:
--! @hmi_table - hmi_table of hmi specification values, default one is specified in "user_modules/hmi_values"
--! @is_cache_used - true if it's expected SDL will use HMI capabilities cache, otherwise false
--! @example: self:initHMI_onReady(local_hmi_table) ]]
function module:initHMI_onReady(hmi_table, is_cache_used)

  if is_cache_used == nil and SDL.HMICapCache.file() ~= nil then
    is_cache_used = SDL.HMICapCache.get() ~= nil
  end

  local exp_waiter = commonFunctions:createMultipleExpectationsWaiter(module, "HMI on ready")

  local function ExpectRequest(name, hmi_table_element)
    if hmi_table_element.occurrence == 0 then
      EXPECT_HMICALL(name, hmi_table_element.params)
      :Times(0)
      commonTestCases:DelayedExp(3000)
      return
    end
    local event = events.Event()
    event.level = 1
    event.matches = function(self, data)
      return data.method == name
    end

    local delay = hmi_table_element.delay or 0
    local occurrence = hmi_table_element.occurrence
    if occurrence == nil then
      occurrence = hmi_table_element.mandatory and 1 or AnyNumber()
    end
    local exp = EXPECT_HMIEVENT(event, name)
    :Times(occurrence)
    :Do(function(_, data)
        xmlReporter.AddMessage("hmi_connection","SendResponse",
        {
          ["methodName"] = tostring(name),
          ["mandatory"] = hmi_table_element.mandatory,
          ["params"] = hmi_table_element.params
        })
        local function sendHMIResponse()
          self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", hmi_table_element.params)
        end
        RUN_AFTER(sendHMIResponse, delay)
      end)
    if hmi_table_element.mandatory then
      exp_waiter:AddExpectation(exp)
    end
    if hmi_table_element.pinned then
      exp:Pin()
    end
   return exp
  end

  local hmi_table_internal
  if type(hmi_table) == "table" then
    hmi_table_internal = utils.cloneTable(hmi_table)
  else
    hmi_table_internal = hmi_values.getDefaultHMITable()
  end

  local bc_update_app_list
  if hmi_table_internal.BasicCommunication then
    bc_update_app_list = hmi_table_internal.BasicCommunication.UpdateAppList
    hmi_table_internal.BasicCommunication.UpdateAppList = nil
    local bc_update_device_list = hmi_table_internal.BasicCommunication.UpdateDeviceList
    if SDL.buildOptions.webSocketServerSupport == "ON" and bc_update_device_list then
      bc_update_device_list.mandatory = true
      if not bc_update_device_list.occurrence then bc_update_device_list.occurrence = AtLeast(1) end
    end
  end

  if is_cache_used == true then
    hmi_table_internal.UI.GetCapabilities = nil
    hmi_table_internal.VR.GetCapabilities = nil
    hmi_table_internal.TTS.GetCapabilities = nil
    hmi_table_internal.RC.GetCapabilities = nil
    hmi_table_internal.Buttons.GetCapabilities = nil
    hmi_table_internal.VR.GetLanguage = nil
    hmi_table_internal.UI.GetLanguage = nil
    hmi_table_internal.TTS.GetLanguage = nil
    hmi_table_internal.VR.GetSupportedLanguages = nil
    hmi_table_internal.UI.GetSupportedLanguages = nil
    hmi_table_internal.TTS.GetSupportedLanguages = nil
    hmi_table_internal.VehicleInfo.GetVehicleType = nil
  end

  for k_module, v_module in pairs(hmi_table_internal) do
    if type(v_module) ~= "table" then
      break
    end
    for k_request, v_request in pairs(v_module) do
      local request_name = k_module .. "." .. k_request
      ExpectRequest(request_name, v_request)
    end
  end

  if type(bc_update_app_list) == "table" then
    ExpectRequest("BasicCommunication.UpdateAppList", bc_update_app_list)
    :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      self.applications = {}
      for _, app in pairs(data.params.applications) do
        self.applications[app.appName] = app.appID
      end
    end)
  end

  self.hmiConnection:SendNotification("BasicCommunication.OnReady")
  return exp_waiter.expectation
end

function module:connectMobile()
  -- Disconnected expectation
  EXPECT_EVENT(events.disconnectedEvent, "Disconnected")
  :Pin()
  :Times(AnyNumber())
  :Do(function()
      print("Disconnected!!!")
    end)
  local ret = EXPECT_EVENT(events.connectedEvent, "Connected")
  self.mobileConnection:Connect()
  return ret
end

function module:startSession()
  self.mobileSession = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    config.application1.registerAppInterfaceParams)
  self.mobileSession:Start()
  local mobile_connected = EXPECT_HMICALL("BasicCommunication.UpdateAppList")
  mobile_connected:Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
      self.applications = { }
      for _, app in pairs(data.params.applications) do
        self.applications[app.appName] = app.appID
      end
    end)
  return mobile_connected
end

return module
