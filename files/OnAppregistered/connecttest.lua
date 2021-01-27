require('atf.util')
local module         = require('testbase')
local mobile         = require("mobile_connection")
local tcp            = require("tcp_connection")
local file_connection = require("file_connection")
local mobile_session = require("mobile_session")
local websocket      = require('websocket_connection')
local hmi_connection = require('hmi_connection')
local events         = require("events")
local expectations   = require('expectations')
local functionId     = require('function_id')
local Event = events.Event

local Expectation = expectations.Expectation
local SUCCESS = expectations.SUCCESS
local FAILED = expectations.FAILED

module.hmiConnection = hmi_connection.Connection(websocket.WebSocketConnection(config.hmiUrl, config.hmiPort))
local tcpConnection = tcp.Connection(config.mobileHost, config.mobilePort)
local fileConnection = file_connection.FileConnection("mobile.out", tcpConnection)
module.mobileConnection = mobile.MobileConnection(fileConnection)
event_dispatcher:AddConnection(module.hmiConnection)
event_dispatcher:AddConnection(module.mobileConnection)

function module.hmiConnection:EXPECT_HMIRESPONSE(id)
  local event = events.Event()
  event.matches = function(self, data) return data.id == id end
  local ret = Expectation("HMI response " .. id, self)
  ret.event = event
  event_dispatcher:AddEvent(module.hmiConnection, event, ret)
  module:AddExpectation(ret)
  return ret
end

function EXPECT_HMIRESPONSE(id)
  return module.hmiConnection:EXPECT_HMIRESPONSE(id)
end

function EXPECT_HMINOTIFICATION(name)
  local event = events.Event()
  event.matches = function(self, data) return data.method == name end
  local ret = Expectation("HMI notification " .. name, module.hmiConnection)
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
                   return compareValues(arguments, data.params, "params")
                end)
  end
  ret.event = event
  event_dispatcher:AddEvent(module.hmiConnection, event, ret)
  module:AddExpectation(ret)
  return ret
end

function EXPECT_NOTIFICATION(func, ...)
  return module.mobileSession:ExpectNotification(func, ...)
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
                   return compareValues(arguments, data.payload, "payload")
                 end)
  end
  ret.event = event
  event_dispatcher:AddEvent(module.mobileConnection, event, ret)
  module.expectations_list:Add(ret)
  return ret
end

module.timers = { }

function RUN_AFTER(func, timeout)
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
  return module.mobileSession:ExpectResponse(correlationId, ...)
end

function EXPECT_ANY_SESSION_RESPONSE(correlationId, ...)
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
                   return compareValues(arguments, data.payload, "payload")
                 end)
  end
  ret.event = event
  event_dispatcher:AddEvent(module.mobileConnection, event, ret)
  module.expectations_list:Add(ret)
  return ret
end

function EXPECT_ANY()
  return module.mobileSession:ExpectAny()
end

function EXPECT_EVENT(event, name)
  local ret = Expectation(name, module.mobileConnection)
  ret.event = event
  event_dispatcher:AddEvent(module.mobileConnection, event, ret)
  module:AddExpectation(ret)
  return ret
end

function RAISE_EVENT(event, data)
  event_dispatcher:RaiseEvent(module.mobileConnection, event, data)
end

function EXPECT_HMIEVENT(event, name)
  local ret = Expectation(name, module.hmiConnection)
  ret.event = event
  event_dispatcher:AddEvent(module.hmiConnection, event, ret)
  module:AddExpectation(ret)
  return ret
end

function module:InitHMI()
  local function registerComponent(name, subscriptions)
    local rid = module.hmiConnection:SendRequest("MB.registerComponent", { componentName = name })
    local exp = EXPECT_HMIRESPONSE(rid)
    if subscriptions then
      for _, s in ipairs(subscriptions) do
        exp:Do(function()
                 local rid = module.hmiConnection:SendRequest("MB.subscribeTo", { propertyName = s })
                 EXPECT_HMIRESPONSE(rid)
               end)
      end
    end
  end


  EXPECT_HMIEVENT(events.connectedEvent, "Connected websocket")
    :Do(function()
          registerComponent("Buttons", {"Buttons.OnButtonSubscription"})
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
            "BasicCommunication.OnResumeAudioSource"
          })
          registerComponent("UI",
          {
            "UI.OnRecordStart"
          })
          registerComponent("VehicleInfo")
          registerComponent("Navigation")
        end)
  self.hmiConnection:Connect()
end

function module:InitHMI_onReady()
  local function ExpectRequest(name, mandatory, params)
    local event = events.Event()
    event.level = 2
    event.matches = function(self, data) return data.method == name end
    return
    EXPECT_HMIEVENT(event, name)
      :Times(mandatory and 1 or AnyNumber())
      :Do(function(_, data)
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", params)
          end)
  end

  local function ExpectNotification(name, mandatory)
    local event = events.Event()
    event.level = 2
    event.matches = function(self, data) return data.method == name end
    return
    EXPECT_HMIEVENT(event, name)
      :Times(mandatory and 1 or AnyNumber())
  end

  ExpectRequest("BasicCommunication.MixingAudioSupported",
                true,
                { attenuatedSupported = true })
  ExpectRequest("BasicCommunication.GetSystemInfo", false,
  {
    ccpu_version = "ccpu_version",
    language = "EN-US",
    wersCountryCode = "wersCountryCode"
  })
  ExpectRequest("UI.GetLanguage", false, { language = "EN-US" })
  ExpectRequest("UI.ChangeRegistration", false, { }):Pin()
  ExpectRequest("TTS.SetGlobalProperties", false, { }):Pin()
  ExpectRequest("BasicCommunication.UpdateDeviceList", false, { }):Pin()
  ExpectRequest("VR.ChangeRegistration", false, { }):Pin()
  ExpectRequest("TTS.ChangeRegistration", false, { }):Pin()
  ExpectRequest("VR.GetSupportedLanguages", false, {
    languages =
    {
      "EN-US","ES-MX","FR-CA","DE-DE","ES-ES","EN-GB","RU-RU","TR-TR","PL-PL",
      "FR-FR","IT-IT","SV-SE","PT-PT","NL-NL","ZH-TW","JA-JP","AR-SA","KO-KR",
      "PT-BR","CS-CZ","DA-DK","NO-NO"
    }
  }):Pin()
  ExpectRequest("TTS.GetSupportedLanguages", false, {
    languages =
    {
      "EN-US","ES-MX","FR-CA","DE-DE","ES-ES","EN-GB","RU-RU","TR-TR","PL-PL",
      "FR-FR","IT-IT","SV-SE","PT-PT","NL-NL","ZH-TW","JA-JP","AR-SA","KO-KR",
      "PT-BR","CS-CZ","DA-DK","NO-NO"
    }
  }):Pin()
  ExpectRequest("TTS.GetSupportedLanguages", false, {
    languages =
    {
      "EN-US","ES-MX","FR-CA","DE-DE","ES-ES","EN-GB","RU-RU","TR-TR","PL-PL",
      "FR-FR","IT-IT","SV-SE","PT-PT","NL-NL","ZH-TW","JA-JP","AR-SA","KO-KR",
      "PT-BR","CS-CZ","DA-DK","NO-NO"
    }
  }):Pin()
  ExpectRequest("VehicleInfo.GetVehicleType", false, {
    vehicleType =
    {
      make = "Ford",
      model = "Fiesta",
      modelYear = "2013",
      trim = "SE"
    }
  }):Pin()
  ExpectRequest("VehicleInfo.GetVehicleData", false, { vin = "52-452-52-752" }):Pin()

  local function button_capability(name, shortPressAvailable, longPressAvailable, upDownAvailable)
    return
    {
      name = name,
      shortPressAvailable = shortPressAvailable == nil and true or shortPressAvailable,
      longPressAvailable = longPressAvailable == nil and true or longPressAvailable,
      upDownAvailable = upDownAvailable == nil and true or upDownAvailable
    }
  end
  local buttons_capabilities =
  {
    capabilities =
    {
      button_capability("PRESET_0"),
      button_capability("PRESET_1"),
      button_capability("PRESET_2"),
      button_capability("PRESET_3"),
      button_capability("PRESET_4"),
      button_capability("PRESET_5"),
      button_capability("PRESET_6"),
      button_capability("PRESET_7"),
      button_capability("PRESET_8"),
      button_capability("PRESET_9"),
      button_capability("OK", true, false, true),
      button_capability("PLAY_PAUSE"),
      button_capability("SEEKLEFT"),
      button_capability("SEEKRIGHT"),
      button_capability("TUNEUP"),
      button_capability("TUNEDOWN"),
      -- button_capability("CUSTOM_BUTTON")
    },
    presetBankCapabilities = { onScreenPresetsAvailable = true }
  }
  ExpectRequest("Buttons.GetCapabilities", true, buttons_capabilities):Pin()
  ExpectRequest("VR.GetCapabilities", false, { vrCapabilities = { "TEXT" } }):Pin()
  ExpectRequest("TTS.GetCapabilities", false, {
    speechCapabilities = { "TEXT", "PRE_RECORDED" },
    prerecordedSpeechCapabilities =
    {
        "HELP_JINGLE",
        "INITIAL_JINGLE",
        "LISTEN_JINGLE",
        "POSITIVE_JINGLE",
        "NEGATIVE_JINGLE"
    }
  }):Pin()

  local function text_field(name, characterSet, width, rows)
    return
    {
      name = name,
      characterSet = characterSet or "UTF_8",
      width = width or 500,
      rows = rows or 1
    }
  end
  local function image_field(name, width, heigth)
    return
    {
      name = name,
      imageTypeSupported =
      {
        "GRAPHIC_BMP",
        "GRAPHIC_JPEG",
        "GRAPHIC_PNG"
      },
      imageResolution =
      {
        resolutionWidth = width or 64,
        resolutionHeight = height or 64
      }
    }

  end

  ExpectRequest("UI.GetCapabilities", false, {
    displayCapabilities =
    {
      displayType = "GEN2_8_DMA",
      displayName = "GENERIC_DISPLAY",
      textFields =
      {
          text_field("mainField1"),
          text_field("mainField2"),
          text_field("mainField3"),
          text_field("mainField4"),
          text_field("statusBar"),
          text_field("mediaClock"),
          text_field("mediaTrack"),
          text_field("alertText1"),
          text_field("alertText2"),
          text_field("alertText3"),
          text_field("scrollableMessageBody"),
          text_field("initialInteractionText"),
          text_field("navigationText1"),
          text_field("navigationText2"),
          text_field("ETA"),
          text_field("totalDistance"),
          text_field("audioPassThruDisplayText1"),
          text_field("audioPassThruDisplayText2"),
          text_field("sliderHeader"),
          text_field("sliderFooter"),
          text_field("menuName"),
          text_field("secondaryText"),
          text_field("tertiaryText"),
          text_field("timeToDestination"),
          text_field("turnText"),
          text_field("menuTitle")
      },
      imageFields =
      {
        image_field("softButtonImage"),
        image_field("choiceImage"),
        image_field("choiceSecondaryImage"),
        image_field("vrHelpItem"),
        image_field("turnIcon"),
        image_field("menuIcon"),
        image_field("cmdIcon"),
        image_field("showConstantTBTIcon"),
        image_field("showConstantTBTNextTurnIcon")
      },
      mediaClockFormats =
      {
          "CLOCK1",
          "CLOCK2",
          "CLOCK3",
          "CLOCKTEXT1",
          "CLOCKTEXT2",
          "CLOCKTEXT3",
          "CLOCKTEXT4"
      },
      graphicSupported = true,
      imageCapabilities = { "DYNAMIC", "STATIC" },
      templatesAvailable = { "TEMPLATE" },
      screenParams =
      {
        resolution = { resolutionWidth = 800, resolutionHeight = 480 },
        touchEventAvailable =
        {
          pressAvailable = true,
          multiTouchAvailable = true,
          doublePressAvailable = false
        }
      },
      numCustomPresetsAvailable = 10
    },
    audioPassThruCapabilities =
    {
      samplingRate = "44KHZ",
      bitsPerSample = "8_BIT",
      audioType = "PCM"
    },
    hmiZoneCapabilities = "FRONT",
    softButtonCapabilities =
    {
      shortPressAvailable = true,
      longPressAvailable = true,
      upDownAvailable = true,
      imageSupported = true
    }
  }):Pin()

  ExpectRequest("VR.IsReady", true, { available = true })
  ExpectRequest("TTS.IsReady", true, { available = true })
  ExpectRequest("UI.IsReady", true, { available = true })
  ExpectRequest("Navigation.IsReady", true, { available = true })
  ExpectRequest("VehicleInfo.IsReady", true, { available = true })

  self.applications = { }
  ExpectRequest("BasicCommunication.UpdateAppList", false, { })
    :Pin()
    :Do(function(_, data)
          self.applications = { }
          for _, app in pairs(data.params.applications) do
            self.applications[app.appName] = app.appID
          end
        end)

  self.hmiConnection:SendNotification("BasicCommunication.OnReady")

end

function module:ConnectMobile()
  -- Connected expectation
  self.mobileSession = mobile_session.MobileSession(
    self.expectations_list,
    self.mobileConnection,
    config.application1.registerAppInterfaceParams)
  self.mobileSession:ExpectEvent(events.connectedEvent, "Connection started")
  self.mobileConnection:Connect()
end
function module:StartSession()
  self.mobileSession:Start()
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = {
                                                                  appName = "Test Application",
                                                                requestType = 
                                                                {
                                                                  "PROPRIETARY"
                                                                }
                                                                }
                                                              })
  :ValidIf(function(self, data)
    -- body
    if #data.params.application.requestType == 1 then
      return true
    else
      return false
    end
  end)

  EXPECT_HMICALL("BasicCommunication.UpdateAppList")
    :Do(function(_, data)
          self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
          self.applications = { }
          for _, app in pairs(data.params.applications) do
            self.applications[app.appName] = app.appID
          end
        end)
end

return module
