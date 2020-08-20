--------------------------------------------------------------------------------
-- Preconditions before ATF start
--------------------------------------------------------------------------------
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
--------------------------------------------------------------------------------
--Precondition: preparation connecttest_VehicleTypeIn_RAI_Response.lua
commonPreconditions:Connecttest_without_ExitBySDLDisconnect_WithoutOpenConnectionRegisterApp("connecttest_onScreen_Presets_Available.lua")


commonPreconditions:Connecttest_InitHMI_onReady_call("connecttest_onScreen_Presets_Available.lua")

Test = require('user_modules/connecttest_onScreen_Presets_Available')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
require('user_modules/AppTypes')
local bOnScreenPresetsAvailable = true
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--local storagePath = config.SDLStoragePath..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"
local SDLConfig = require('user_modules/shared_testcases/SmartDeviceLinkConfigurations')
local storagePath = config.pathToSDL .. SDLConfig:GetValue("AppStorageFolder") .. "/" .. tostring(config.application1.registerAppInterfaceParams.fullAppID .. "_" .. tostring(config.deviceMAC) .. "/")
local resultCodes = {
			{resultCode = "SUCCESS", success =  true},
			{resultCode = "INVALID_DATA", success =  false},
			{resultCode = "OUT_OF_MEMORY", success =  false},
			{resultCode = "TOO_MANY_PENDING_REQUESTS", success =  false},
			{resultCode = "APPLICATION_NOT_REGISTERED", success =  false},
			{resultCode = "GENERIC_ERROR", success =  false},
			{resultCode = "REJECTED", success =  false},
			{resultCode = "DISALLOWED", success =  false},
			{resultCode = "UNSUPPORTED_RESOURCE", success =  false},
			{resultCode = "ABORTED", success =  false}
		}		

---------------------------------------------------------------------------------------------
--------------------------------------- Common functions ------------------------------------
---------------------------------------------------------------------------------------------

function DelayedExp(timeout)
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, timeout)
end
 
function Test:initHMI_onReady(bOnScreenPresetsAvailable)
	local function ExpectRequest(name, mandatory, params)
	local event = events.Event()
		event.level = 2
		event.matches = function (self, data)return data.method == name end
		return
		EXPECT_HMIEVENT(event, name)
		:	Times(mandatory and 1 or AnyNumber())
		:Do(function (_, data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", params)
		end)
	end

	local function ExpectNotification(name, mandatory)
		local event = events.Event()
		event.level = 2
		event.matches = function (self, data)return data.method == name end
		return
		EXPECT_HMIEVENT(event, name)
		:Times(mandatory and 1 or AnyNumber())
	end

	ExpectRequest("BasicCommunication.MixingAudioSupported",
	true, {
		attenuatedSupported = true
	})
	ExpectRequest("BasicCommunication.GetSystemInfo", false, {
		ccpu_version = "ccpu_version",
		language = "EN-US",
		wersCountryCode = "wersCountryCode"
	})
	ExpectRequest("UI.GetLanguage", true, {
		language = "EN-US"
	})
	ExpectRequest("VR.GetLanguage", true, {
		language = "EN-US"
	})
	ExpectRequest("TTS.GetLanguage", true, {
		language = "EN-US"
	})
	ExpectRequest("UI.ChangeRegistration", false, {}):Pin()
	ExpectRequest("TTS.SetGlobalProperties", false, {}):Pin()
	ExpectRequest("BasicCommunication.UpdateDeviceList", false, {}):Pin()
	ExpectRequest("VR.ChangeRegistration", false, {}):Pin()
	ExpectRequest("TTS.ChangeRegistration", false, {}):Pin()
	ExpectRequest("VR.GetSupportedLanguages", true, {
		languages = {
			"EN-US",
			"ES-MX",
			"FR-CA",
			"DE-DE",
			"ES-ES",
			"EN-GB",
			"RU-RU",
			"TR-TR",
			"PL-PL",
			"FR-FR",
			"IT-IT",
			"SV-SE",
			"PT-PT",
			"NL-NL",
			"ZH-TW",
			"JA-JP",
			"AR-SA",
			"KO-KR",
			"PT-BR",
			"CS-CZ",
			"DA-DK",
			"NO-NO",
			"NL-BE",
			"EL-GR",
			"HU-HU",
			"FI-FI",
			"SK-SK"
		}
	}):Pin()
	ExpectRequest("TTS.GetSupportedLanguages", true, {
		languages = {
			"EN-US",
			"ES-MX",
			"FR-CA",
			"DE-DE",
			"ES-ES",
			"EN-GB",
			"RU-RU",
			"TR-TR",
			"PL-PL",
			"FR-FR",
			"IT-IT",
			"SV-SE",
			"PT-PT",
			"NL-NL",
			"ZH-TW",
			"JA-JP",
			"AR-SA",
			"KO-KR",
			"PT-BR",
			"CS-CZ",
			"DA-DK",
			"NO-NO",
			"NL-BE",
			"EL-GR",
			"HU-HU",
			"FI-FI",
			"SK-SK"
		}
	}):Pin()
	ExpectRequest("UI.GetSupportedLanguages", true, {
		languages = {
			"EN-US",
			"ES-MX",
			"FR-CA",
			"DE-DE",
			"ES-ES",
			"EN-GB",
			"RU-RU",
			"TR-TR",
			"PL-PL",
			"FR-FR",
			"IT-IT",
			"SV-SE",
			"PT-PT",
			"NL-NL",
			"ZH-TW",
			"JA-JP",
			"AR-SA",
			"KO-KR",
			"PT-BR",
			"CS-CZ",
			"DA-DK",
			"NO-NO",
			"NL-BE",
			"EL-GR",
			"HU-HU",
			"FI-FI",
			"SK-SK"
		}
	}):Pin()
	ExpectRequest("VehicleInfo.GetVehicleType", false, {
		vehicleType = {
			make = "Ford",
			model = "Fiesta",
			modelYear = "2013",
			trim = "SE"
		}
	}):Pin()
	ExpectRequest("VehicleInfo.GetVehicleData", true, {
		vin = "52-452-52-752"
	})

	local function button_capability(name, shortPressAvailable, longPressAvailable, upDownAvailable)
	return {
		name = name,
		shortPressAvailable = shortPressAvailable == nil and true or shortPressAvailable,
		longPressAvailable = longPressAvailable == nil and true or longPressAvailable,
		upDownAvailable = upDownAvailable == nil and true or upDownAvailable
	}
	end
	local buttons_capabilities = {
		capabilities = {
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
		presetBankCapabilities = {
			onScreenPresetsAvailable = bOnScreenPresetsAvailable
		}
	}
	ExpectRequest("Buttons.GetCapabilities", true, buttons_capabilities):Pin()
	ExpectRequest("VR.GetCapabilities", true, {
		vrCapabilities = {
			"TEXT"
		}
	}):Pin()
	ExpectRequest("TTS.GetCapabilities", true, {
		speechCapabilities = {
			"TEXT"
		},
		prerecordedSpeechCapabilities = {
			"HELP_JINGLE",
			"INITIAL_JINGLE",
			"LISTEN_JINGLE",
			"POSITIVE_JINGLE",
			"NEGATIVE_JINGLE"
		}
	}):Pin()

	local function text_field(name, characterSet, width, rows)
	return {
		name = name,
		characterSet = characterSet or "UTF_8",
		width = width or 500,
		rows = rows or 1
	}
	end
	local function image_field(name, width, heigth)
	return {
		name = name,
		imageTypeSupported = {
			"GRAPHIC_BMP",
			"GRAPHIC_JPEG",
			"GRAPHIC_PNG"
		},
		imageResolution = {
			resolutionWidth = width or 64,
			resolutionHeight = height or 64
		}
	}

	end

	ExpectRequest("UI.GetCapabilities", true, {
		displayCapabilities = {
			displayType = "GEN2_8_DMA",
			displayName = "GENERIC_DISPLAY",
			textFields = {
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
				text_field("menuTitle"),
				text_field("locationName"),
				text_field("locationDescription"),
				text_field("addressLines"),
				text_field("phoneNumber"),
				text_field("turnText"),
			},
			imageFields = {
				image_field("softButtonImage"),
				image_field("choiceImage"),
				image_field("choiceSecondaryImage"),
				image_field("vrHelpItem"),
				image_field("turnIcon"),
				image_field("menuIcon"),
				image_field("cmdIcon"),
				image_field("showConstantTBTIcon"),
				image_field("showConstantTBTNextTurnIcon"),
				image_field("locationImage")
			},
			mediaClockFormats = {
				"CLOCK1",
				"CLOCK2",
				"CLOCK3",
				"CLOCKTEXT1",
				"CLOCKTEXT2",
				"CLOCKTEXT3",
				"CLOCKTEXT4"
			},
			graphicSupported = true,
			imageCapabilities = {
				"DYNAMIC",
				"STATIC"
			},
			templatesAvailable = {
				"TEMPLATE"
			},
			screenParams = {
				resolution = {
					resolutionWidth = 800,
					resolutionHeight = 480
				},
				touchEventAvailable = {
					pressAvailable = true,
					multiTouchAvailable = true,
					doublePressAvailable = false
				}
			},
			numCustomPresetsAvailable = 10
		},
		audioPassThruCapabilities = {
			samplingRate = "44KHZ",
			bitsPerSample = "8_BIT",
			audioType = "PCM"
		},
		hmiZoneCapabilities = "FRONT",
		softButtonCapabilities = {
			shortPressAvailable = true,
			longPressAvailable = true,
			upDownAvailable = true,
			imageSupported = true
		}
	}):Pin()

	ExpectRequest("VR.IsReady", true, {
		available = true
	})
	ExpectRequest("TTS.IsReady", true, {
		available = true
	})
	ExpectRequest("UI.IsReady", true, {
		available = true
	})
	ExpectRequest("Navigation.IsReady", true, {
		available = true
	})
	ExpectRequest("VehicleInfo.IsReady", true, {
		available = true
	})

	self.applications = {}
	ExpectRequest("BasicCommunication.UpdateAppList", false, {})
	: Pin()
	: Do(function (_, data)
		self.applications = {}
		for _, app in pairs(data.params.applications)do
		self.applications[app.appName] = app.appID
		end
	end)
	
	self.hmiConnection:SendNotification("BasicCommunication.OnReady")
end

function Test:connectMobileStartSession()
	local tcpConnection = tcp.Connection(config.mobileHost, config.mobilePort)
	local fileConnection = file_connection.FileConnection("mobile.out", tcpConnection)
	self.mobileConnection = mobile.MobileConnection(fileConnection)
	self.mobileSession= mobile_session.MobileSession(
	self,
	self.mobileConnection)
	event_dispatcher:AddConnection(self.mobileConnection)
	self.mobileSession:ExpectEvent(events.connectedEvent, "Connection started")
	self.mobileConnection:Connect()
	self.mobileSession:StartService(7)	
end

--Create UI expected result based on parameters from the request
function Test:createUIParameters(Request)

	local param =  {}

	param["alignment"] =  Request["alignment"]
	param["customPresets"] =  Request["customPresets"]
	
	--Convert showStrings parameter
	local j = 0
	for i = 1, 4 do	
		if Request["mainField" .. i] ~= nil then
			j = j + 1
			if param["showStrings"] == nil then
				param["showStrings"] = {}			
			end
			param["showStrings"][j] = {
				fieldName = "mainField" .. i,
				fieldText = Request["mainField" .. i]
			}
		end
	end
	
	--mediaClock
	if Request["mediaClock"] ~= nil then
		j = j + 1
		if param["showStrings"] == nil then
			param["showStrings"] = {}			
		end		
		param["showStrings"][j] = {
			fieldName = "mediaClock",
			fieldText = Request["mediaClock"]
		}
	end
	
	--mediaTrack
	if Request["mediaTrack"] ~= nil then
		j = j + 1
		if param["showStrings"] == nil then
			param["showStrings"] = {}			
		end				
		param["showStrings"][j] = {
			fieldName = "mediaTrack",
			fieldText = Request["mediaTrack"]
		}
	end
	
	--statusBar
	if Request["statusBar"] ~= nil then
		j = j + 1
		if param["showStrings"] == nil then
			param["showStrings"] = {}			
		end				
		param["showStrings"][j] = {
			fieldName = "statusBar",
			fieldText = Request["statusBar"]
		}
	end

	

	param["graphic"] =  Request["graphic"]
	if param["graphic"] ~= nil and 
		param["graphic"].imageType ~= "STATIC" and
		param["graphic"].value ~= nil and
		param["graphic"].value ~= "" then
			param["graphic"].value = storagePath ..param["graphic"].value
	end	
	
	param["secondaryGraphic"] =  Request["secondaryGraphic"]
	if param["secondaryGraphic"] ~= nil and 
		param["secondaryGraphic"].imageType ~= "STATIC" and
		param["secondaryGraphic"].value ~= nil and
		param["secondaryGraphic"].value ~= "" then
			param["secondaryGraphic"].value = storagePath ..param["secondaryGraphic"].value
	end	
	
	--softButtons
	if Request["softButtons"]  ~= nil then
		param["softButtons"] =  Request["softButtons"]
		for i = 1, #param["softButtons"] do
		
			--if type = TEXT, image = nil, else type = IMAGE, text = nil
			if param["softButtons"][i].type == "TEXT" then			
				param["softButtons"][i].image =  nil

			elseif param["softButtons"][i].type == "IMAGE" then			
				param["softButtons"][i].text =  nil
			end
			
			
			
			--if image.imageType ~=STATIC, add app folder to image value 
			if param["softButtons"][i].image ~= nil and 
				param["softButtons"][i].image.imageType ~= "STATIC" then
				
				param["softButtons"][i].image.value = storagePath ..param["softButtons"][i].image.value
			end
			
		end
	end
	
		
	return param
	
	

end

local function ActivationApp(self, appID, session)			
	--hmi side: sending SDL.ActivateApp request
	local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = appID})
	EXPECT_HMIRESPONSE(RequestId)
	:Do(function(_,data)
		if
			data.result.isSDLAllowed ~= true then
			local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
			
			--hmi side: expect SDL.GetUserFriendlyMessage message response
			EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
			:Do(function(_,data)						
				--hmi side: send request SDL.OnAllowSDLFunctionality
				self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})

				--hmi side: expect BasicCommunication.ActivateApp request
				EXPECT_HMICALL("BasicCommunication.ActivateApp")
				:Do(function(_,data)
					--hmi side: sending BasicCommunication.ActivateApp response
					self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
				end)
				:Times(2)
			end)

		end
	end)
	
	--mobile side: expect notification
	session:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"}) 
end

function Test:show(successValue, resultCodeValue)	
	--mobile side: request parameters
	local RequestParams = 
	{				
		mainField1 ="Show1",
		mainField2 ="Show2",
		mainField3 ="Show3",
		mainField4 ="Show4",
		alignment ="CENTERED",
		statusBar ="statusBar",
		mediaClock ="00:00:01",
		mediaTrack ="mediaTrack",								
		customPresets = 
		{ 
			"Preset1",
			"Preset2",
			"Preset3",
		}, 
	}			

	--mobile side: sending Show request
	local cid = self.mobileSession:SendRPC("Show", RequestParams)

	UIParams = self:createUIParameters(RequestParams)
	
	--hmi side: expect UI.Show request
	EXPECT_HMICALL("UI.Show", UIParams)
	:Do(function(_,data)
		if resultCodeValue == "SUCCESS" then
			--hmi side: sending UI.Show response
			self.hmiConnection:SendResponse(data.id, data.method, resultCodeValue, {})
		else
			--hmi side: sending UI.Show response
			self.hmiConnection:SendError(data.id, data.method, resultCodeValue, "")
		end
	end)

	--mobile side: expect Show response
	EXPECT_RESPONSE(cid, { success = successValue, resultCode = resultCodeValue })				
end

-- Precondition: removing user_modules/connecttest_onScreen_Presets_Available.lua
function Test:Precondition_remove_user_connecttest()
  os.execute( "rm -f ./user_modules/connecttest_onScreen_Presets_Available.lua" )
end

-----------------------------------------------------------------------------------------

--Begin Test case suite
--Description: 
			--Custom presets availability should be sent by HMI during start up as a parameter PresetBankCapabilities.
			--PresetBankCapabilities should contain information about on-screen preset availability for use.

	--Requirement id in JAMA: SDLAQ-CRS-910, SDLAQ-CRS-2678

    --Verification criteria: 
		--PresetCapabilities data is obtained as "onScreenPresetsAvailable: true" from HMI by SDL during SDL starting in case HMI supports custom presets.
		--PresetCapabilities data is obtained as "onScreenPresetsAvailable: false" from HMI by SDL during SDL starting in case HMI supports custom presets.
		--In case SDL does not receive the value of 'presetBankCapabilities' via GetCapabilities_response from HMI -> SDL must use the default value from HMI_capabilities.json file

	--Print new line to separate new test cases
	commonFunctions:newTestCasesGroup("Test case: PresetCapabilities data is obtained as onScreenPresetsAvailable: true")
	
	--Begin Test case 01
	--Description: PresetCapabilities data is obtained as "onScreenPresetsAvailable: true"	
		function Test:InitHMI_onReady()
		  self:initHMI_onReady(bOnScreenPresetsAvailable)

		  DelayedExp(2000)
		end

		function Test:ConnectMobileStartSession()
			self:connectMobileStartSession()
		end

		function Test:RegisterAppInterface_OnScreenPresetsAvailableTrue()
			--mobile side: RegisterAppInterface request 
			local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",config.application1.registerAppInterfaceParams)
			

			--hmi side: expected  BasicCommunication.OnAppRegistered
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
			{
				application = 
				{
					appName = config.application1.registerAppInterfaceParams.appName
				}
			})
			:Do(function(_,data)
				self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
			end)
			
			--mobile side: RegisterAppInterface response 
			EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS", presetBankCapabilities = {onScreenPresetsAvailable = bOnScreenPresetsAvailable}})
			:Timeout(2000)

			--mobile side: expect notification
			EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"}) 

		end
		
		function Test:Precondition_ActivateApp()			
			ActivationApp(self, self.applications[config.application1.registerAppInterfaceParams.appName], self.mobileSession)
		end
		
		for i =1, #resultCodes do
			Test["Show_resultCode_" .. resultCodes[i].resultCode] = function(self)
				self:show(resultCodes[i].success, resultCodes[i].resultCode)
			end
		end
	--End Test case 01
	
	-----------------------------------------------------------------------------------------
	--Print new line to separate new test cases
	commonFunctions:newTestCasesGroup("Test case: PresetCapabilities data is obtained as onScreenPresetsAvailable: false")
		
	--Begin Test case 02
	--Description: PresetCapabilities data is obtained as "onScreenPresetsAvailable: false"
		function Test:StopSDL()
		  StopSDL()
		end

		function Test:StartSDL()
		  StartSDL(config.pathToSDL, config.ExitOnCrash)
		end

		function Test:InitHMI2()
		  self:initHMI()
		end

		function Test:InitHMI_onReady2()
			bOnScreenPresetsAvailable = false
			self:initHMI_onReady(bOnScreenPresetsAvailable)

			DelayedExp(2000)
		end

		function Test:ConnectMobileStartSession2()
			self:connectMobileStartSession()
		end

		function Test:RegisterAppInterface_OnScreenPresetsAvailableFalse() 

			--mobile side: RegisterAppInterface request 
			local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",config.application1.registerAppInterfaceParams)
			

			--hmi side: expected  BasicCommunication.OnAppRegistered
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
			{
				application = 
				{
					appName = config.application1.registerAppInterfaceParams.appName
				}
			})
			:Do(function(_,data)
				self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
			end)
			
			--mobile side: RegisterAppInterface response 
			EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS", presetBankCapabilities = { onScreenPresetsAvailable = bOnScreenPresetsAvailable}})
			:Timeout(2000)

			--mobile side: expect notification
			EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"}) 
		end
		
		function Test:Precondition_ActivateApp()			
			ActivationApp(self, self.applications[config.application1.registerAppInterfaceParams.appName], self.mobileSession)
		end
		
		for i =1, #resultCodes do
			Test["Show_resultCode_" .. resultCodes[i].resultCode] = function(self)
				self:show(resultCodes[i].success, resultCodes[i].resultCode)
			end
		end
	--End Test case 02
	
	-----------------------------------------------------------------------------------------
	--Print new line to separate new test cases
	commonFunctions:newTestCasesGroup("Test case: OnScreenPresetsAvailable data is not send")    
	
	--Begin Test case 03
	--Description: OnScreenPresetsAvailable data is not send
		function Test:StopSDL()
		  StopSDL()
		end

		function Test:StartSDL()
		  StartSDL(config.pathToSDL, config.ExitOnCrash)
		end

		function Test:InitHMI3()
		  self:initHMI()
		end

		function Test:InitHMI_onReady3_WithOutOnScreenPresetsAvailable()
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
			ExpectRequest("UI.GetLanguage", true, { language = "EN-US" })
			ExpectRequest("VR.GetLanguage", true, { language = "EN-US" })
			ExpectRequest("TTS.GetLanguage", true, { language = "EN-US" })
			ExpectRequest("UI.ChangeRegistration", false, { }):Pin()
			ExpectRequest("TTS.SetGlobalProperties", false, { }):Pin()
			ExpectRequest("BasicCommunication.UpdateDeviceList", false, { }):Pin()
			ExpectRequest("VR.ChangeRegistration", false, { }):Pin()
			ExpectRequest("TTS.ChangeRegistration", false, { }):Pin()
			ExpectRequest("VR.GetSupportedLanguages", true, {
				languages =
				{
					"EN-US","ES-MX","FR-CA","DE-DE","ES-ES","EN-GB","RU-RU","TR-TR","PL-PL",
					"FR-FR","IT-IT","SV-SE","PT-PT","NL-NL","ZH-TW","JA-JP","AR-SA","KO-KR",
					"PT-BR","CS-CZ","DA-DK","NO-NO","NL-BE","EL-GR","HU-HU","FI-FI","SK-SK"
				}
			}):Pin()
			ExpectRequest("TTS.GetSupportedLanguages", true, {
				languages =
				{
					"EN-US","ES-MX","FR-CA","DE-DE","ES-ES","EN-GB","RU-RU","TR-TR","PL-PL",
					"FR-FR","IT-IT","SV-SE","PT-PT","NL-NL","ZH-TW","JA-JP","AR-SA","KO-KR",
					"PT-BR","CS-CZ","DA-DK","NO-NO","NL-BE","EL-GR","HU-HU","FI-FI","SK-SK"
				}
			}):Pin()
			ExpectRequest("UI.GetSupportedLanguages", true, {
				languages =
				{
					"EN-US","ES-MX","FR-CA","DE-DE","ES-ES","EN-GB","RU-RU","TR-TR","PL-PL",
					"FR-FR","IT-IT","SV-SE","PT-PT","NL-NL","ZH-TW","JA-JP","AR-SA","KO-KR",
					"PT-BR","CS-CZ","DA-DK","NO-NO","NL-BE","EL-GR","HU-HU","FI-FI","SK-SK"
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
			ExpectRequest("VehicleInfo.GetVehicleData", true, { vin = "52-452-52-752" })

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
					button_capability("TUNEDOWN")
				},			
			}
			ExpectRequest("Buttons.GetCapabilities", true, buttons_capabilities):Pin()
			ExpectRequest("VR.GetCapabilities", true, { vrCapabilities = { "TEXT" } }):Pin()
			ExpectRequest("TTS.GetCapabilities", true, {
				speechCapabilities = { "TEXT"},
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
						text_field("menuTitle"),
						text_field("locationName"),
						text_field("locationDescription"),
						text_field("addressLines"),
						text_field("phoneNumber"),
						text_field("turnText"),
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
						image_field("showConstantTBTNextTurnIcon"),
						image_field("locationImage")
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

		DelayedExp(2000)
		end

		function Test:ConnectMobileStartSession3()
			self:connectMobileStartSession()
		end

		function Test:RegisterAppInterface_OnScreenPresetsAvailableDefault()
			--mobile side: RegisterAppInterface request 
			local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",config.application1.registerAppInterfaceParams)
			

			--hmi side: expected  BasicCommunication.OnAppRegistered
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
			{
				application = 
				{
					appName = config.application1.registerAppInterfaceParams.appName
				}
			})
			:Do(function(_,data)
				self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
			end)
			
			--mobile side: RegisterAppInterface response 
			EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS", presetBankCapabilities = {onScreenPresetsAvailable = true} })
			:Timeout(2000)

			--mobile side: expect notification
			EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"}) 

		end
		
		function Test:Precondition_ActivateApp()			
			ActivationApp(self, self.applications[config.application1.registerAppInterfaceParams.appName], self.mobileSession)
		end
		
		for i =1, #resultCodes do
			Test["Show_resultCode_" .. resultCodes[i].resultCode] = function(self)
				self:show(resultCodes[i].success, resultCodes[i].resultCode)
			end
		end
		
		function Test:StopSDL()
		  StopSDL()
		end
	--End Test case 03	
--End Test case suite
