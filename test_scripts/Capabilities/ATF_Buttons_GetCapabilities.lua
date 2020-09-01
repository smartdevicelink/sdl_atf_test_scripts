Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')
local module = require('testbase')

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
require('user_modules/AppTypes')
--UPDATED with Automated Preconditions:
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2
local storagePath = config.pathToSDL .. "storage/" ..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"
---------------------------------------------------------------------------------------------
------------------------------------ Common Variables And Functions -------------------------
---------------------------------------------------------------------------------------------
--Set list of button for media/non-media application
local ButtonNames_NoCUSTOM_BUTTON
local ButtonNames_NoCUSTOM_BUTTON_OK
if config.application1.registerAppInterfaceParams.isMediaApplication then

	ButtonNames_NoCUSTOM_BUTTON = {"OK","PLAY_PAUSE","SEEKLEFT","SEEKRIGHT", "TUNEUP", "TUNEDOWN","PRESET_0", "PRESET_1", "PRESET_2", "PRESET_3", "PRESET_4", "PRESET_5", "PRESET_6", "PRESET_7", "PRESET_8", "PRESET_9", "SEARCH"}
										
	ButtonNames_NoCUSTOM_BUTTON_OK = {"PLAY_PAUSE","SEEKLEFT","SEEKRIGHT", "TUNEUP", "TUNEDOWN", "PRESET_0", "PRESET_1", "PRESET_2", "PRESET_3", "PRESET_4", "PRESET_5", "PRESET_6", "PRESET_7", "PRESET_8", "PRESET_9", "SEARCH"}
	
	-- group of media buttons, this group  should be updated with PRESETS 0-9 due to APPLINK-14516 (APPLINK-14503)
	MediaButtons = 
					{
						"PLAY_PAUSE",
						"SEEKLEFT",
						"SEEKRIGHT",
						"TUNEUP",
						"TUNEDOWN",
						-- "PRESET_0",
						-- "PRESET_1",
						-- "PRESET_2",
						-- "PRESET_3",
						-- "PRESET_4",
						-- "PRESET_5",
						-- "PRESET_6",
						-- "PRESET_7",
						-- "PRESET_8",
						-- "PRESET_9"
					}			
else --Non-media app

	ButtonNames_NoCUSTOM_BUTTON = {"OK", "PRESET_0", "PRESET_1", "PRESET_2", "PRESET_3", "PRESET_4", "PRESET_5", "PRESET_6", "PRESET_7", "PRESET_8", "PRESET_9","SEARCH"}
										
	ButtonNames_NoCUSTOM_BUTTON_OK = {"PRESET_0", "PRESET_1", "PRESET_2", "PRESET_3", "PRESET_4", "PRESET_5", "PRESET_6", "PRESET_7", "PRESET_8", "PRESET_9", "SEARCH"}		
end

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

-- Input capabilities used with Buttons.Getcapabilities response timeout 
local Input_Timeoutcapabilities = 
{
    capabilities =
    {
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
  	},
  	presetBankCapabilities = { onScreenPresetsAvailable = true }
}

--Parameters taken from hmi_capabilities.json(GetCapabilities) when wrong input capabilities are received from Buttons.GetCapabilities
local Input_ButtonsCapabilities_RAI =
{
    buttoncapabilities =
    {
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
  	},
  	presetBankCapabilities = { onScreenPresetsAvailable = true }
  }

--Invalid parameters to be sent from HMI
local Input_Invalidcapabilities =
		{
		    capabilities =
		    {
		       	{
		  	  		button_capability("INVALID")
		  		},
		  	},
		  	presetBankCapabilities = { onScreenPresetsAvailable = true } 
		  }

 -- DefaultTimeout in smartDeviceLink.ini
local iTimeout = 10000

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
      	registerComponent("Buttons", 
				      		{"Buttons.OnButtonSubscription"
				      		}
				      	)
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
				          		"BasicCommunication.OnReady",
				          		"SDL.OnSDLConsentNeeded",
				          		"BasicCommunication.OnResumeAudioSource"
				        	}
				          )
        registerComponent("UI",
					        {
					          "UI.OnRecordStart"
					        }
					     )
      	registerComponent("VehicleInfo")
      	registerComponent("Navigation")
    	end)
  	self.hmiConnection:Connect()
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

--HMI sends Buttons.GetCapabilities response with specific value of Capabilities parameter
local function HMI_Send_Button_GetCapabilities_Response(Input_capabilities)

	Test["HMISendsButtonGetCapabilitiesResponse"] = function(self)

		critical(true)
		
		local function ExpectRequest(name, mandatory, params)

			local SDL_Request = name
			--print("ExpectRequest: name = "..SDL_Request)  	
		  	xmlReporter.AddMessage(debug.getinfo(1, "n").name, tostring(name))
		  	local event = events.Event()
		  	event.level = 2

		  	event.matches = function(self, data) 
		  						return data.method == name 
							end
					  
			return	EXPECT_HMIEVENT(event, name)
					:Times(mandatory and 1 or AnyNumber())
					:Do(function(_, data)
						--print("SDL_Request: "..SDL_Request.. " EXPECT_HMIEVENT = "..data.method)
			  			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", params)
					end)
		end

		local function ExpectNotification(name, mandatory)
		  	xmlReporter.AddMessage(debug.getinfo(1, "n").name, tostring(name))
		  	
		  	local event = events.Event()
		  	event.level = 2
		  	event.matches = function(self, data) 
		  					return data.method == name 
		  					end
		  	--print("ExpectNotification: data.method = "..data.method)

		  	return  EXPECT_HMIEVENT(event, name)
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
		ExpectRequest("Buttons.GetCapabilities", true, buttons_capabilities) :Pin()

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

--HMI does not send Buttons.GetCapabilities response due to timeout 

local function HMI_Send_Button_GetCapabilities_Response_Timeout(Input_Timeoutcapabilities)

	Test["HMISendsButtonGetCapabilitiesResponse_Timeout"] = function(self)

		critical(true)
		
		local function ExpectRequest(name, mandatory, params)
			local SDL_Request = name
			--print("ExpectRequest: name = "..name)	  	
		  	--xmlReporter.AddMessage(debug.getinfo(1, "n").Buttons.GetCapabilities, tostring(Buttons.GetCapabilities))
		  	local event = events.Event()
		  	event.level = 2		  
			
			 if(name == "Buttons.GetCapabilities") then									
				EXPECT_HMIEVENT(event,name)
				:Times(1)
				:Do(function(_, data)										
						--print("HMI response of "..SDL_Request.. " is not sent by HMI ")
					end)	
			else
			--All other requests
				event.matches = function(self, data) 
		  							return data.method == name
								end		
		
				return	EXPECT_HMIEVENT(event, name)
					:Times(mandatory and 1 or AnyNumber())
					:Do(function(_, data)
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", params)							
						--print("SDL_Request: "..SDL_Request.. " EXPECT_HMIEVENT = "..data.method)
 					end)	
			end	
		end
		local function ExpectNotification(name, mandatory)
		  	xmlReporter.AddMessage(debug.getinfo(1, "n").name, tostring(name))	  	 	
		  	local event = events.Event()
		  	event.level = 2
		  	event.matches = function(self, data) 
		  					return data.method == name 
		  					end
			--print("ExpectNotification: data.method = "..data.method)
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
		  })
		ExpectRequest("TTS.GetSupportedLanguages", true, {
			languages =
			{
			  "EN-US","ES-MX","FR-CA","DE-DE","ES-ES","EN-GB","RU-RU","TR-TR","PL-PL",
			  "FR-FR","IT-IT","SV-SE","PT-PT","NL-NL","ZH-TW","JA-JP","AR-SA","KO-KR",
			  "PT-BR","CS-CZ","DA-DK","NO-NO","NL-BE","EL-GR","HU-HU","FI-FI","SK-SK"
			}
		  })
		ExpectRequest("UI.GetSupportedLanguages", true, {
			languages =
			{
			  "EN-US","ES-MX","FR-CA","DE-DE","ES-ES","EN-GB","RU-RU","TR-TR","PL-PL",
			  "FR-FR","IT-IT","SV-SE","PT-PT","NL-NL","ZH-TW","JA-JP","AR-SA","KO-KR",
			  "PT-BR","CS-CZ","DA-DK","NO-NO","NL-BE","EL-GR","HU-HU","FI-FI","SK-SK"
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
		    presetBankCapabilities = { onScreenPresetsAvailable = true }
		  }
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
	          text_field("menuTitle"),
	          text_field("locationName"),
	          text_field("locationDescription"),
	          text_field("addressLines"),
	          text_field("phoneNumber")
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
		--ExpectRequest("Buttons.GetCapabilities", true, buttons_capabilities)--:Times(1) --Check if timeout occurs 

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

--HMI sends Buttons.GetCapabilities response with specific invalid value of Capabilities parameter

local function HMI_Send_Button_GetCapabilities_Response_Invalid()

	Test["HMISendsButtonGetCapabilitiesResponse_Invalid"] = function(self)

		critical(true)
		
		local function ExpectRequest(name, mandatory, params)
			local SDL_Request = name
			--print("ExpectRequest: name = "..name)	  	
		  	--xmlReporter.AddMessage(debug.getinfo(1, "n").Buttons.GetCapabilities, tostring(Buttons.GetCapabilities))
		  	local event = events.Event()
		  	event.level = 2		  
			if(name == "Buttons.GetCapabilities") then			
				self.hmiConnection:SendResponse(data.id, "Buttons.GetCapabilities", "UNSUPPORTED_RESOURCE", {presetBankCapabilities = { onScreenPresetsAvailable = true } } )				
			else
				--All other requests
				event.matches = function(self, data) 
		  							return data.method == name
								end		
		
				return	EXPECT_HMIEVENT(event, name)
					:Times(mandatory and 1 or AnyNumber())
					:Do(function(_, data)

						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", params)								
						--print("SDL_Request: "..SDL_Request.. " EXPECT_HMIEVENT = "..data.method)
					end)	
			end	
		end

		local function ExpectNotification(name, mandatory)
		  	xmlReporter.AddMessage(debug.getinfo(1, "n").name, tostring(name))	  	
		  	local event = events.Event()
		  	event.level = 2
		  	event.matches = function(self, data) 
		  					return data.method == name 
		  					end
			--print("ExpectNotification: data.method = "..data.method)
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
		  })
		ExpectRequest("TTS.GetSupportedLanguages", true, {
			languages =
			{
			  "EN-US","ES-MX","FR-CA","DE-DE","ES-ES","EN-GB","RU-RU","TR-TR","PL-PL",
			  "FR-FR","IT-IT","SV-SE","PT-PT","NL-NL","ZH-TW","JA-JP","AR-SA","KO-KR",
			  "PT-BR","CS-CZ","DA-DK","NO-NO","NL-BE","EL-GR","HU-HU","FI-FI","SK-SK"
			}
		  })
		ExpectRequest("UI.GetSupportedLanguages", true, {
			languages =
			{
			  "EN-US","ES-MX","FR-CA","DE-DE","ES-ES","EN-GB","RU-RU","TR-TR","PL-PL",
			  "FR-FR","IT-IT","SV-SE","PT-PT","NL-NL","ZH-TW","JA-JP","AR-SA","KO-KR",
			  "PT-BR","CS-CZ","DA-DK","NO-NO","NL-BE","EL-GR","HU-HU","FI-FI","SK-SK"
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
		    presetBankCapabilities = { onScreenPresetsAvailable = true }
		  }
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
	          text_field("menuTitle"),
	          text_field("locationName"),
	          text_field("locationDescription"),
	          text_field("addressLines"),
	          text_field("phoneNumber")
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
		ExpectRequest("Buttons.GetCapabilities", true, buttons_capabilities)

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


--Mobile registers application and verification ButtonCapabilities parameter in positive case 

local function MobileRegisterAppAndVerifyButtonCapabilities(Input_ButtonsCapabilities)

	Test["MobileRegisterAppInterfaceAndVerifyButtonCapabilities"] = function(self)

		--Mobile: sends RegisterAppInterface request
		local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

		--Mobile: Verify RegisterAppInterface response
		EXPECT_RESPONSE(correlationId, { success = true, buttonCapabilities = Input_ButtonsCapabilities})
		:Do(function(_,data)
		end)	
	end
end

--Mobile registers application and verification ButtonCapabilities parameter when Timeout occurs 

local function MobileRegisterAppAndVerifyButtonCapabilitiesTimeout ()

	Test["MobileRegisterAppAndVerifyButtonCapabilitiesTimeout"] = function(self)

		--Mobile: sends RegisterAppInterface request
		local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

		--Mobile: Verify RegisterAppInterface response
		EXPECT_RESPONSE(correlationId, { 
											success = true,
											buttoncapabilities = Input_ButtonsCapabilities_RAI
											
										})
		:Do(function(_,data)
		end)
	end
end

--Mobile registers application and verification ButtonCapabilities parameter when invalid parameters were sent

local function MobileRegisterAppAndVerifyButtonCapabilitiesInvalid ()

	Test["MobileRegisterAppAndVerifyButtonCapabilitiesInvalid"] = function(self)

		--Mobile: sends RegisterAppInterface request
		local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

		--Mobile: Verify RegisterAppInterface response
		EXPECT_RESPONSE(correlationId, { 
											success = true,
											buttonCapabilities = Input_ButtonsCapabilities_RAI									
										})
		:Do(function(_,data)
		end)
		:ValidIf(function(_,data)
			local result = true

			if(data.payload.presetBankCapabilities ~= nil) then
				if( data.payload.presetBankCapabilities.onScreenPresetsAvailable ~= nil ) then
					if( data.payload.presetBankCapabilities.onScreenPresetsAvailable == true) then
				 		print("OK")
					else
						print("NOK Wrong param")
				 		result = false
					end
				else
					print("data.payload.presetBankCapabilities.onScreenPresetsAvailable in nil")
					result = false
				end
			else
				print("data.payload.presetBankCapabilities is nil")
				result = false
			end


			if(data.payload.buttonCapabilities == nil) then
				print("data.payload.buttonCapabilities is nil")
				result = false
			end

			return result
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

--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Preconditions")

--Stop SDL
stopSDL()	


-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK I----------------------------------------
-------------------------------- Check positive cases of response -----------------------------
-----------------------------------------------------------------------------------------------

--Requirement id in JIRA: 	
	--APPLINK-24325: [Buttons.GetCapabilities] response from HMI and RegisterAppInterface 
	--Description: If after sdl is started the HMI provides valid successful ButtonsGetCapabilities_response the sdl must provide the 
	--obtained buttons capabilities information to each and every application via RegisterAppInterface_response in the current ignition cycle 
	
		-- Parametres in GetCapabilities response:
		--1. capabilities, type= Common.ButtonCapabilities, array=true, minsize=1, maxsize=100, mandatory=true
		--2. presetBankCapabilities, type=Common.PresetBankCapabilities 
	
	--Verification criteria
		--1. HMI responsds to initHMI request from SDL with BC.OnReady		
		--2. SDL sends to HMI: Buttons.GetCapabilities request 
		--3. HMI checks the Buttons capabilities and sends to SDL response Buttons.GetCapabilities ("capabilities", "presetBankCapabilities")
		--4. The validity of parametres is checked in RegisterAppInterface_response ("buttonCapabilities", "presetBankCapabilities")

	--APPLINK-20199: [HMI API]Buttons.GetCapabilities request/response 
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
--Begin Test suit buttonCapabilities Positive 

	--Begin Test case buttonCapabilities.01
	--Description: HMI sends Buttons.GetCapabilities response with all button names


		for i =1, #ButtonNames_NoCUSTOM_BUTTON do 
		--Print new line to separate new test cases group			
		commonFunctions:newTestCasesGroup("Test case: HMI sends Buttons.GetCapabilities with all button names NoCustomButton- \"".. ButtonNames_NoCUSTOM_BUTTON[i] .. "\"")		
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
	end 

	
		--Print new line to separate new test cases group	
		commonFunctions:newTestCasesGroup("Test case: HMI sends Buttons.GetCapabilities with all button names NoCustomButton_OK")	
		
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
		
		for i =1, #ButtonNames_NoCUSTOM_BUTTON do 
		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test case: HMI sends Buttons.GetCapabilities with some button names NoCustomButton- \"".. ButtonNames_NoCUSTOM_BUTTON[i] .. "\"")		
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
	end 


		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test case: HMI sends Buttons.GetCapabilities with some button names NoCustomButton_OK")	
		
		--Test data: Create capabilities for Buttons.GetCapabilities response
		local capabilities =
				{
					button_capability("PRESET_1"),
					button_capability("PRESET_2"), -- commented to be removed 
					--button_capability("PRESET_3"), -- commented to be removed 
					--button_capability("PRESET_4"), -- commented to be removed 
					--button_capability("PRESET_5"), -- commented to be removed 
					--button_capability("PRESET_6"), -- commented to be removed 
					button_capability("OK", true, false, true),
					-- button_capability("SEEKLEFT"), -- commented to be removed 
					-- button_capability("SEEKRIGHT") -- commented to be removed 
				}

		--Execute success case
		SuccessTestCase(capabilities)
	
	--End Test case buttonCapabilities.02
	---------------------------------------------------------------------------------------------

	--Begin Test case buttonCapabilities.03
	--Description: HMI sends Buttons.GetCapabilities response with one button

		for i =1, #ButtonNames_NoCUSTOM_BUTTON do 
			--Print new line to separate new test case
			commonFunctions:newTestCasesGroup("Test case: HMI sends Buttons.GetCapabilities with one button NoCustomButton- \"".. ButtonNames_NoCUSTOM_BUTTON[i] .. "\"")	
			
			--Test data: Create capabilities for Buttons.GetCapabilities response
			local capabilities = {button_capability(ButtonNames_NoCUSTOM_BUTTON[i])}
			
			--Execute success case
			SuccessTestCase(capabilities)
			
		end

			--Print new line to separate new test case
			commonFunctions:newTestCasesGroup("Test case: HMI sends Buttons.GetCapabilities with one button NoCustomButton_OK")	
			
			--Test data: Create capabilities for Buttons.GetCapabilities response
			local capabilities = {button_capability(ButtonNames_NoCUSTOM_BUTTON_OK[i])}
			
			--Execute success case
			SuccessTestCase(capabilities)

	--End Test case buttonCapabilities.03	
	---------------------------------------------------------------------------------------------

--End Test suit buttonCapabilities Positive 


-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK II---------------------------------------
-------------------------------- Check negative cases of response -----------------------------
-----------------------------------------------------------------------------------------------

-- NOTE 1. According to APPLINK-24358 SDL receives information from HMI via ButtonsGetCapabilities and remembers
-- it during the ignition cycle. If mobile application is registered SDL must provide received info from HMI (Buttons.GetCapabilities)
-- via RegisterAppInterface_response.
-- NOTE 2. Case when SDL does not receive button capabilities or receives just partial values should be covered by APPLINK-7622 The order of capabilities processing
-- (SDLAQ-CRS-2678)
-- NOTE 3. For the reasons above the two applicable checks will be when the Button.Getcapabilities response is timed out (1)
--and when response comes with empty parametres (2) the expected result is that when invalid parametres are sent (or no params sent at all), the default ones will be taken 


--Requirement id in JIRA: 	
	--APPLINK-24325: [Buttons.GetCapabilities] response from HMI and RegisterAppInterface 
	--Description: If after sdl is started HMI does not provide successful ButtonsGetCapabilities_response the sdl must take the default ones 
	-- from hmi_capabilities.json(GetCapabilities) 
		
--Verification criteria
		--1. HMI responsds to initHMI request from SDL with BC.OnReady		
		--2. SDL sends to HMI: Buttons.GetCapabilities request 
		--3. HMI checks the Buttons capabilities and and either does not send Buttons.GetCapabilities response or sends it with wrong params
		--4. The validity of parametres is checked in RegisterAppInterface_response ("buttonCapabilities", "presetBankCapabilities") and the ones from
		--hmi_capabilities.json(GetCapabilities) are taken  

	--Begin Test case Negative buttonCapabilities.01
	
	--Description: After sdl is started HMI does not provide successful ButtonsGetCapabilities_response due to timeout and sdl takes the default parametres 
	-- from hmi_capabilities.json(GetCapabilities)

	--Verification criteria: 
		--1. SDL does not receive the list of button names supported by HMI via response to Buttons.GetCapabilities from HMI as it times out
		--2. SDL takes the parametres from hmi_capabilities.json(GetCapabilities) and sends it with RegisterAppInterface_response

-----------------------------------------------------------------------------------------------
--Begin Test suit buttonCapabilities Negative 

	--Print new line to separate new test case
	commonFunctions:newTestCasesGroup("Test case: Button.GetCapabilities Times Out")

--Timeout test case 
local function NegativeTimeoutTestCase()

	--Precondition:
	startSDL()	
	
	--Step 1: initiate HMI
	initHMI()
	
	--Step 2: HMI times out Button.GetCapabilities response
	HMI_Send_Button_GetCapabilities_Response_Timeout(Input_Timeoutcapabilities)

	--Step 3: Mobile starts session
	connectMobileStartSession()
	
	--Step 4: Mobile register an application and verify ButtonCapabilities parameter in RegisterAppInterface response
	 MobileRegisterAppAndVerifyButtonCapabilitiesTimeout(Input_ButtonsCapabilities_RAI)
	
end

--function Test:NegativeCheckTimeout ()
 	NegativeTimeoutTestCase()	
--end 

--Postcondition
stopSDL()

	--End Test case Negative buttonCapabilities.01
-------------------------------------------------------------------------------------------------

	--Begin Test case Negative buttonCapabilities.02
	
	--Description: After sdl is started HMI does not provide successful ButtonsGetCapabilities_response due to timeout and sdl takes the default parametres 
	-- from hmi_capabilities.json(GetCapabilities)

	--Verification criteria: 
		--1. SDL does not receive the list of button names supported by HMI via response to Buttons.GetCapabilities from HMI as incorrect params are sent
		--2. SDL takes the parametres from hmi_capabilities.json(GetCapabilities) and sends it with RegisterAppInterface_response

	--Print new line to separate new test case
	commonFunctions:newTestCasesGroup("Test case: Button.GetCapabilities Invalid Parametres")

--Negative test case 1

	local function NegativeTestCaseInvalidParametres()

	--Precondition:
	startSDL()	
	
	--Step 1: initiate HMI
	initHMI()
	
	--Step 2: HMI sends Button.GetCapabilities response
	
	HMI_Send_Button_GetCapabilities_Response_Invalid(Input_Invalidcapabilities)
	
	--Step 3: Mobile starts session
	connectMobileStartSession()
		
	--Step 4: Mobile register an application and verify ButtonCapabilities parameter in RegisterAppInterface response
	  MobileRegisterAppAndVerifyButtonCapabilitiesInvalid(Input_ButtonsCapabilities_RAI)
end


--function Test:CheckNegative ()
 
 	NegativeTestCaseInvalidParametres()
	
--end 

	--End Test case Negative buttonCapabilities.02
--------------------------------------------------------------------------------------------

--End Test suit buttonCapabilities Negative 				
