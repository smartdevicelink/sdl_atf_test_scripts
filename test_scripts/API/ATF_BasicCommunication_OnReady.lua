Test = require('connecttest')

require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
require('user_modules/AppTypes')

---------------------------------------------------------------------------------------------
-------------------------------------------Common function-----------------------------------
---------------------------------------------------------------------------------------------
-- HMI sends BasicCommunication.OnReady notification with InvalidJson, does NOT send and wrongtype
function Test:initHMI_BasicCommunication_OnReady_Invalid(case)
    critical(true)
    local function ExpectRequest(name, mandatory, params)
      xmlReporter.AddMessage(debug.getinfo(1, "n").name, tostring(name))
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
      xmlReporter.AddMessage(debug.getinfo(1, "n").name, tostring(name))
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
	  :Times(0)
    ExpectRequest("BasicCommunication.GetSystemInfo", false,
      {
        ccpu_version = "ccpu_version",
        language = "EN-US",
        wersCountryCode = "wersCountryCode"
      })
	  :Times(0)
    ExpectRequest("UI.GetLanguage", true, { language = "EN-US" })
	:Times(0)
    ExpectRequest("VR.GetLanguage", true, { language = "EN-US" })
	:Times(0)
    ExpectRequest("TTS.GetLanguage", true, { language = "EN-US" })
	:Times(0)
    ExpectRequest("UI.ChangeRegistration", false, { }):Pin()
	:Times(0)
    ExpectRequest("TTS.SetGlobalProperties", false, { }):Pin()
	:Times(0)
    ExpectRequest("BasicCommunication.UpdateDeviceList", false, { }):Pin()
	:Times(0)
    ExpectRequest("VR.ChangeRegistration", false, { }):Pin()
	:Times(0)
    ExpectRequest("TTS.ChangeRegistration", false, { }):Pin()
	:Times(0)
    ExpectRequest("VR.GetSupportedLanguages", true, {
        languages =
        {
          "EN-US","ES-MX","FR-CA","DE-DE","ES-ES","EN-GB","RU-RU","TR-TR","PL-PL",
          "FR-FR","IT-IT","SV-SE","PT-PT","NL-NL","ZH-TW","JA-JP","AR-SA","KO-KR",
          "PT-BR","CS-CZ","DA-DK","NO-NO"
        }
      })
	  :Times(0)
    ExpectRequest("TTS.GetSupportedLanguages", true, {
        languages =
        {
          "EN-US","ES-MX","FR-CA","DE-DE","ES-ES","EN-GB","RU-RU","TR-TR","PL-PL",
          "FR-FR","IT-IT","SV-SE","PT-PT","NL-NL","ZH-TW","JA-JP","AR-SA","KO-KR",
          "PT-BR","CS-CZ","DA-DK","NO-NO"
        }
      })
	  :Times(0)
    ExpectRequest("UI.GetSupportedLanguages", true, {
        languages =
        {
          "EN-US","ES-MX","FR-CA","DE-DE","ES-ES","EN-GB","RU-RU","TR-TR","PL-PL",
          "FR-FR","IT-IT","SV-SE","PT-PT","NL-NL","ZH-TW","JA-JP","AR-SA","KO-KR",
          "PT-BR","CS-CZ","DA-DK","NO-NO"
        }
      })
	  :Times(0)
    ExpectRequest("VehicleInfo.GetVehicleType", true, {
        vehicleType =
        {
          make = "Ford",
          model = "Fiesta",
          modelYear = "2013",
          trim = "SE"
        }
      })
	  :Times(0)
    ExpectRequest("VehicleInfo.GetVehicleData", true, { vin = "52-452-52-752" })
	:Times(0)

    local function button_capability(name, shortPressAvailable, longPressAvailable, upDownAvailable)
      xmlReporter.AddMessage(debug.getinfo(1, "n").name, tostring(name))
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
        button_capability("TUNEDOWN")
      },
      presetBankCapabilities = { onScreenPresetsAvailable = true }
    }
    ExpectRequest("Buttons.GetCapabilities", true, buttons_capabilities)
	:Times(0)
    ExpectRequest("VR.GetCapabilities", true, { vrCapabilities = { "TEXT" } })
	:Times(0)
    ExpectRequest("TTS.GetCapabilities", true, {
        speechCapabilities = { "TEXT", "PRE_RECORDED" },
        prerecordedSpeechCapabilities =
        {
          "HELP_JINGLE",
          "INITIAL_JINGLE",
          "LISTEN_JINGLE",
          "POSITIVE_JINGLE",
          "NEGATIVE_JINGLE"
        }
      })
	  :Times(0)

    local function text_field(name, characterSet, width, rows)
      xmlReporter.AddMessage(debug.getinfo(1, "n").name, tostring(name))
      return
      {
        name = name,
        characterSet = characterSet or "UTF_8",
        width = width or 500,
        rows = rows or 1
      }
    end
    local function image_field(name, width, heigth)
      xmlReporter.AddMessage(debug.getinfo(1, "n").name, tostring(name))
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

    ExpectRequest("UI.GetCapabilities", true, {
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
            text_field("navigationText"),
            text_field("audioPassThruDisplayText1"),
            text_field("audioPassThruDisplayText2"),
            text_field("sliderHeader"),
            text_field("sliderFooter"),
            text_field("notificationText"),
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
      })
	  :Times(0)

    ExpectRequest("VR.IsReady", true, { available = true })
	:Times(0)
    ExpectRequest("TTS.IsReady", true, { available = true })
	:Times(0)
    ExpectRequest("UI.IsReady", true, { available = true })
	:Times(0)
    ExpectRequest("Navigation.IsReady", true, { available = true })
	:Times(0)
    ExpectRequest("VehicleInfo.IsReady", true, { available = true })
	:Times(0)

    self.applications = { }
    ExpectRequest("BasicCommunication.UpdateAppList", false, { })
    :Pin()
    :Do(function(_, data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
        self.applications = { }
        for _, app in pairs(data.params.applications) do
          self.applications[app.appName] = app.appID
        end
      end)
	
	if (case == "Wrong Type") then
		--HMI send BasicCommunication.OnReady notification with wrongtype: method=1234
		self.hmiConnection:Send('{"jsonrpc":"2.0","method":1234}')
	elseif (case == "Invalid Json") then
		--HMI send BasicCommunication.OnReady notification with invalidJson. Missing ":" symbol
		self.hmiConnection:Send('{"jsonrpc":"2.0","method""BasicCommunication.OnReady"}')
	else
		--Do NOT send BasicCommunication.OnReady notification
	end
	
	commonTestCases:DelayedExp(1000)
	
end
-- Stop SDL, start SDL, HMI initialization with specified modes, create mobile connection.
local function RestartSDL_InitHMI_ConnectMobile(self, Description, Params, case)

	--Stop SDL
	Test["BC_StopSDL"] = function(self)
		StopSDL()
	end
	
	--Start SDL
	Test["BC_StartSDL"] = function(self)
		StartSDL(config.pathToSDL, config.ExitOnCrash)
	end
	
	--InitHMI
	Test["BC_InitHMI"] = function(self)
		self:initHMI()
	end

	Test["BC_initHMI_" .. Description] = function(self)
		self:initHMI_BasicCommunication_OnReady_Invalid(case)
	end
	
	--ConnectMobile
	Test["BC_ConnectMobile"] = function(self)
		self:connectMobile()
	end
	
	--StartSession
	Test["BC_StartSession"] = function(self)
		self.mobileSession= mobile_session.MobileSession(
			self,
			self.mobileConnection)
		self.mobileSession:StartService(7)
	end
	
end
	


---------------------------------------------------------------------------------------------
-----------------------------------------I TEST BLOCK----------------------------------------
--------CommonRequestCheck: Check notification BasicCommunication.OnReady from HMI-----------
---------------------------------------------------------------------------------------------	

	--Description: TC's checks processing 
		--HMI sends BasicCommunication.OnReady
		--HMI does NOT send BasicCommunication.OnReady
		--HMI sends InvalidJson BasicCommunication.OnReady
		--HMI sends WrongType BasicCommunication.OnReady

		--Requirement id in JAMA: 
				--APPLINK-24441: https://adc.luxoft.com/svn/APPLINK/doc/technical/HOW-TOs_and_Guidelines/FORD.SmartDeviceLink.SDL_Integration_Guidelines.docx
				
		----------------------------------------------------------------------------------------------		
		
		local TestData = {
			{description = "HMI sends BasicCommunication.OnReady", 				parameter = {"BasicCommunication.OnReady"},								case = "HMI sends valid OnReady"},
			{description = "HMI does NOT send BasicCommunication.OnReady", 		parameter = {},															case = "Do Not send"},
			{description = "HMI sends InvalidJson BasicCommunication.OnReady", 	parameter = {'{"jsonrpc":"2.0","method""BasicCommunication.OnReady"}'},	case = "Invalid Json"},
			{description = "HMI sends WrongType BasicCommunication.OnReady", 	parameter = {'{"jsonrpc":"2.0","method":1234}'},						case = "Wrong Type"}
			
		}

		----------------------------------------------------------------------------------------------				
				
		--Description: 
		--Main executing
		--i=1 already running when start script in file: "/modules/connecttest" file when InitHMI function executing
		for i=2, #TestData do
			
			--Print new line to separate new test cases group
			commonFunctions:newTestCasesGroup("-----------------------I." ..tostring(i).." [" ..TestData[i].description .. "]------------------------------")
			
			RestartSDL_InitHMI_ConnectMobile(self, TestData[i].description, TestData[i].parameter, TestData[i].case)
			
		end