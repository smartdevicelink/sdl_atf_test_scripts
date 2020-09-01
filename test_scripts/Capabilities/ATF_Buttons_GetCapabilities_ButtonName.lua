Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')
local module = require('testbase')

--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
require('user_modules/AppTypes')

---------------------------------------------------------------------------------------------
------------------------------------ Common Variables ---------------------------------------
---------------------------------------------------------------------------------------------

--List of button names
local ButtonNames = {
						"PRESET_0",
						"PRESET_1",
						"PRESET_2",
						"PRESET_3",
						"PRESET_4",
						"PRESET_5",
						"PRESET_6",
						"PRESET_7",
						"PRESET_8",
						"PRESET_9",
						"OK",
						"PLAY_PAUSE",
						"SEEKLEFT",
						"SEEKRIGHT",
						"TUNEUP",
						"TUNEDOWN",
						"CUSTOM_BUTTON",
						"SEARCH"
					}

					
---------------------------------------------------------------------------------------------
--------------------------------------- Common functions ------------------------------------
---------------------------------------------------------------------------------------------
 
 
--Create button capability function
local function button_capability(name, shortPressAvailable, longPressAvailable, upDownAvailable)
	
	return
	{
		name = name,
		shortPressAvailable = shortPressAvailable == nil and true or shortPressAvailable,
		longPressAvailable = longPressAvailable == nil and true or longPressAvailable,
		upDownAvailable = upDownAvailable == nil and true or upDownAvailable
	}
end

 
 
---------------------------------------------------------------------------------------------
---------------------------------------- Common steps ---------------------------------------
--------------------------------------------------------------------------------------------- 

--Stop SDL
function stopSDL()

	Test["StopSDL"] = function(self)

		--run StopSDL function
		StopSDL()		
	end
end	

--Start SDL
function startSDL()

	Test["StartSDL"] = function(self)
		--run StartSDL function
		StartSDL(config.pathToSDL, config.ExitOnCrash)
	end
end	

--Start HMI
function initHMI()

	Test["InitHMI"] = function(self)
		self:initHMI()
	end
end

--HMI sends Buttons.GetCapabilities response with specific value of Capabilities parameter
local function HMI_Send_Button_GetCapabilities_Response(Input_capabilities)

	Test["HMISendsButtonGetCapabilitiesResponse"] = function(self)

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
			  "PT-BR","CS-CZ","DA-DK","NO-NO"
			}
		  })
		ExpectRequest("TTS.GetSupportedLanguages", true, {
			languages =
			{
			  "EN-US","ES-MX","FR-CA","DE-DE","ES-ES","EN-GB","RU-RU","TR-TR","PL-PL",
			  "FR-FR","IT-IT","SV-SE","PT-PT","NL-NL","ZH-TW","JA-JP","AR-SA","KO-KR",
			  "PT-BR","CS-CZ","DA-DK","NO-NO"
			}
		  })
		ExpectRequest("UI.GetSupportedLanguages", true, {
			languages =
			{
			  "EN-US","ES-MX","FR-CA","DE-DE","ES-ES","EN-GB","RU-RU","TR-TR","PL-PL",
			  "FR-FR","IT-IT","SV-SE","PT-PT","NL-NL","ZH-TW","JA-JP","AR-SA","KO-KR",
			  "PT-BR","CS-CZ","DA-DK","NO-NO"
			}
		  })
		ExpectRequest("VehicleInfo.GetVehicleType", true, {
			vehicleType =
			{
			  make = "Ford",
			  model = "Fiesta",
			  modelYear = "2013",
			  trim = "SE"
			}
		  })
		ExpectRequest("VehicleInfo.GetVehicleData", true, { vin = "52-452-52-752" })

		local buttons_capabilities =
		{
			capabilities = Input_capabilities,
			presetBankCapabilities = { onScreenPresetsAvailable = true }
		}
		
		ExpectRequest("Buttons.GetCapabilities", true, buttons_capabilities)
		
		ExpectRequest("VR.GetCapabilities", true, { vrCapabilities = { "TEXT" } })
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

		ExpectRequest("VR.IsReady", true, { available = true })
		ExpectRequest("TTS.IsReady", true, { available = true })
		ExpectRequest("UI.IsReady", true, { available = true })
		ExpectRequest("Navigation.IsReady", true, { available = true })
		ExpectRequest("VehicleInfo.IsReady", true, { available = true })

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

		self.hmiConnection:SendNotification("BasicCommunication.OnReady")
	  
			
	end
end	

--Start Mobile and Add New Session
function connectMobileStartSession()

	Test["ConnectMobileStartSession"] = function(self)

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
end	

--Mobile register application and verify ButtonCapabilities parameter
local function MobileRegisterAppAndVerifyButtonCapabilities(Input_ButtonsCapabilities)

	Test["MobileRegisterAppInterfaceAndVerifyButtonCapabilities"] = function(self)

		--Mobile: sends RegisterAppInterface request
		local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

		--Mobile: Verify RegisterAppInterface response
		EXPECT_RESPONSE(correlationId, { success = true, buttonCapabilities = Input_ButtonsCapabilities})
		:Do(function(_,data)
				--commonFunctions:printTable(data.payload.buttonCapabilities)
		end)	
	end
end

 
--Success test case
local function SuccessTestCase(Input_capabilities)
	
	--Precondition:
	startSDL()	
	
	--Step 1: initiate HMI
	initHMI()
	
	--Step 2: HMI sends Button.GetCapabilities response
	HMI_Send_Button_GetCapabilities_Response(Input_capabilities)
	
	--Step 3: Mobile starts session
	connectMobileStartSession()
	
	--Step 4: Mobile register an application and verify ButtonCapabilities parameter in RegisterAppInterface response
	MobileRegisterAppAndVerifyButtonCapabilities(Input_capabilities)
	  
	--Postcondition
	stopSDL()	

end


---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

--Stop SDL
stopSDL()	



-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK I----------------------------------------
-------------------------------- Check positive cases of response -----------------------------
-----------------------------------------------------------------------------------------------

--Requirement id in JAMA or JIRA: 	
	--SDLAQ-N_CRS-148: ButtonName
	--Description: Defines the hard (physical) and soft (touchscreen) buttons available from SYNC
					--OK
					--PLAY_PAUSE
					--SEEKLEFT
					--SEEKRIGHT
					--TUNEUP
					--TUNEDOWN
					--PRESET_0
					--PRESET_1
					--PRESET_2
					--PRESET_3
					--PRESET_4
					--PRESET_5
					--PRESET_6
					--PRESET_7
					--PRESET_8
					--PRESET_9
					--CUSTOM_BUTTON
					--SEARCH

	--Verification criteria: 
		--1. SDL receives the list of button names supported by HMI via response to Buttons.GetCapabilities from HMI:
		--2. SDL sends the list of button names supported by HMI to mobile app IN CASE SDL has received this information from HMI via response to Buttons.GetCapabilities (the case when SDL does not receive buttons capabilities from HMI or receives just partial values -> is covered by the requirement of SDLAQ-CRS-2678: The order of capabilities processing).
		
-----------------------------------------------------------------------------------------------
--Begin Test suit buttonCapabilities

	--Begin Test case buttonCapabilities.01
	--Description: HMI sends Buttons.GetCapabilities response with all button names

		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test case: HMI sends Buttons.GetCapabilities with all button names")	
		
		--Test data: Create capabilities for Buttons.GetCapabilities response
		local capabilities =
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
					button_capability("CUSTOM_BUTTON"),
					button_capability("SEARCH")
				}

		--Execute success case
		SuccessTestCase(capabilities)
		
	--End Test case buttonCapabilities.01
	---------------------------------------------------------------------------------------------
	--Begin Test case buttonCapabilities.02
	--Description: HMI sends Buttons.GetCapabilities response with some button names

		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test case: HMI sends Buttons.GetCapabilities with some button names")	
		
		--Test data: Create capabilities for Buttons.GetCapabilities response
		local capabilities =
				{
					button_capability("PRESET_1"),
					button_capability("PRESET_2"),
					button_capability("PRESET_3"),
					button_capability("PRESET_4"),
					button_capability("PRESET_5"),
					button_capability("PRESET_6"),
					button_capability("OK", true, false, true),
					button_capability("SEEKLEFT"),
					button_capability("SEEKRIGHT")
				}

		--Execute success case
		SuccessTestCase(capabilities)
		
	--End Test case buttonCapabilities.02
	---------------------------------------------------------------------------------------------

	--Begin Test case buttonCapabilities.03
	--Description: HMI sends Buttons.GetCapabilities response with one button

		for i = 1, #ButtonNames do
			--Print new line to separate new test case
			commonFunctions:newTestCasesGroup("Test case: HMI sends Buttons.GetCapabilities with one button - \"".. ButtonNames[i] .. "\"")	
			
			--Test data: Create capabilities for Buttons.GetCapabilities response
			local capabilities = {button_capability(ButtonNames[i])}
			
			--Execute success case
			SuccessTestCase(capabilities)
			
		end

	--End Test case buttonCapabilities.03	
	---------------------------------------------------------------------------------------------

--End Test suit buttonCapabilities


-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK II---------------------------------------
-------------------------------- Check negative cases of response -----------------------------
-----------------------------------------------------------------------------------------------

--The case when SDL does not receive buttons capabilities from HMI or receives just partial values
-- -> is covered by the requirement of SDLAQ-CRS-2678: The order of capabilities processing

	
