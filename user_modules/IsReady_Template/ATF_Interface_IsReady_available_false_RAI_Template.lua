---------------------------------------------------------------------------------------------
-- This script check parameters related to testing interface are omitted in RAI response when <testing interface>.IsReady (available = false)
---------------------------------------------------------------------------------------------

local commonPreconditions = require ('/user_modules/shared_testcases/commonPreconditions')
commonPreconditions:Connecttest_without_ExitBySDLDisconnect("connecttest_IsReady.lua")
--Test = require('connecttest')
Test = require('user_modules/connecttest_IsReady')
require('cardinalities')
local events = require('events') 
local mobile_session = require('mobile_session')
require('user_modules/AppTypes')

local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')		

config.defaultProtocolVersion = 2
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
config.SDLStoragePath = commonPreconditions:GetPathToSDL() .. "storage/"
local isReady = require('user_modules/IsReady_Template/isReady')

DefaultTimeout = 3
local iTimeout = 2000



---------------------------------------------------------------------------------------------
---------------------------- Local functions ------------------------------------------------
---------------------------------------------------------------------------------------------

local function update_sdl_preloaded_pt_json_allow_All_Related_RPCs()
	pathToFile = commonPreconditions:GetPathToSDL() .. 'sdl_preloaded_pt.json'
	local file = io.open(pathToFile, "r")
	local json_data = file:read("*all") -- may be abbreviated to "*a";
	file:close()
	
	local json = require("modules/json")
	
	local data = json.decode(json_data)
	for k,v in pairs(data.policy_table.functional_groupings) do
		if (data.policy_table.functional_groupings[k].rpcs == nil) then
			--do
			data.policy_table.functional_groupings[k] = nil
		end
	end
	
	data.policy_table.functional_groupings["Base-4"].rpcs["SubscribeWayPoints"] = { hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}}
	data.policy_table.functional_groupings["Base-4"].rpcs["SubscribeVehicleData"] = { hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}}
	
	data = json.encode(data)
	file = io.open(pathToFile, "w")
	file:write(data)
	file:close()
end

function StopStartSDL_HMI_MOBILE_VR_TTS(self)
		
	--Stop SDL
	Test["Precondition_StopSDL_VR_TTS_available_false"] = function(self)

		StopSDL()
	end

	function Test:Postcondition_RestorePreloadedFile()
		commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
	end
			
	--Start SDL
	Test["Precondition_StartSDL_VR_TTS_available_false"] = function(self)

		StartSDL(commonPreconditions:GetPathToSDL(), config.ExitOnCrash)
	end
			
	--InitHMI
	Test["Precondition_InitHMI_VR_TTS_available_false"] = function(self)

		self:initHMI()
	end

	Test["Precondition_initHMI_onReady_VR_TTS_available_false"] = function(self)
	
		local function ExpectRequest(name, mandatory, params)
				
		    xmlReporter.AddMessage(debug.getinfo(1, "n").name, tostring(name))
		    local event = events.Event()
		    event.level = 2
		    event.matches = function(self, data) return data.method == name end
		    
		    if(mandatory == true) then
		    	return
			      	EXPECT_HMIEVENT(event, name)
			      	:Times(1)-- or AtLeast(1))
			      	:Do(function(_, data)
						if (name == "VR.IsReady" or name == "TTS.IsReady") then
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {available = false}) 
							
						else
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", params) 			
						end
		      	  	end)
		    else --if(mandatory == true) 
		    		return
			      		EXPECT_HMIEVENT(event, name)
					    :Times(mandatory and 1 or AnyNumber())			      
					    :Do(function(_, data)
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", params) 			
					    end)
			end --if(mandatory == true) then
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
		:Times(0)
		
		ExpectRequest("TTS.GetLanguage", true, { language = "EN-US" })
		:Times(0)
		  
		ExpectRequest("UI.ChangeRegistration", false, { }):Pin()
		ExpectRequest("TTS.SetGlobalProperties", false, { }):Pin()
		ExpectRequest("BasicCommunication.UpdateDeviceList", false, { }):Pin()
		ExpectRequest("VR.ChangeRegistration", false, { })
		:Times(0)
		ExpectRequest("TTS.ChangeRegistration", false, { })
		:Times(0)
		
		ExpectRequest("VR.GetSupportedLanguages", true, {})
		:Times(0)
		
		ExpectRequest("TTS.GetSupportedLanguages", true, {})
		:Times(0)

	  	ExpectRequest("UI.GetSupportedLanguages", true, {}):Pin()

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
		      button_capability("SEEKLEFT"),
		      button_capability("SEEKRIGHT"),
		      button_capability("TUNEUP"),
		      button_capability("TUNEDOWN")
		    },
		    presetBankCapabilities = { onScreenPresetsAvailable = true }
		}
	  
	  	ExpectRequest("Buttons.GetCapabilities", true, buttons_capabilities)
	  	ExpectRequest("VR.GetCapabilities", true, { vrCapabilities = { "TEXT" } })
	  	:Times(0)
	  	ExpectRequest("TTS.GetCapabilities", true, {})
	  	:Times(0)

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
	      {{
	        shortPressAvailable = true,
	        longPressAvailable = true,
	        upDownAvailable = true,
	        imageSupported = true
	      }}
	    })

	  	ExpectRequest("VR.IsReady", true, { available = false })
	  	ExpectRequest("TTS.IsReady", true, { available = false })
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
			
	--ConnectMobile
	Test["Precondition_ConnectMobile_VR_TTS_available_false"] = function(self)

		self:connectMobile()
	end
			
	--StartSession
	Test["Precondition_StartSession_VR_TTS_available_false"] = function(self)

		self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
		self.mobileSession:StartService(7)
	end
end

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

commonPreconditions:BackupFile("sdl_preloaded_pt.json")

-- Update preload_PT to allow all related RPCs
update_sdl_preloaded_pt_json_allow_All_Related_RPCs()

-- Precondition: remove policy table and log files
commonSteps:DeleteLogsFileAndPolicyTable()

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK I----------------------------------------
--------------------------------Check normal cases of Mobile request---------------------------
-----------------------------------------------------------------------------------------------

-- Not applicable for

----------------------------------------------------------------------------------------------
----------------------------------------TEST BLOCK II-----------------------------------------
-----------------------------Check special cases of Mobile request----------------------------
----------------------------------------------------------------------------------------------

-- Not applicable for 

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK III--------------------------------------
----------------------------------Check normal cases of HMI response---------------------------
-----------------------------------------------------------------------------------------------
--List of CRQs:
--APPLINK-20918: [GENIVI] VR interface: SDL behavior in case HMI does not respond to IsReady_request or respond with "available" = false
-- 1. HMI respond '..tested_method..' (false) -> SDL must return 'UNSUPPORTED_RESOURCE, success:false' to all single VR-related RPC
-- 2. HMI respond '..tested_method..' (false) and app sends RPC that must be spitted -> SDL must NOT transfer VR portion of spitted RPC to HMI
-- 3. HMI does NOT respond to '..tested_method..'_request -> SDL must transfer received RPC to HMI even to non-responded VR module

--List of parameters in '..tested_method..' response:
--Parameter 1: correlationID: type=Integer, mandatory="true"
--Parameter 2: method: type=String, mandatory="true" (method = "'..tested_method..'") 
--Parameter 3: resultCode: type=String Enumeration(Integer), mandatory="true" 
--Parameter 4: info/message: type=String, minlength="1" maxlength="10" mandatory="false" 
--Parameter 5: available: type=Boolean, mandatory="true"
-----------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------				
-- Cases 1: HMI sends '..tested_method..' response (available = false)
-----------------------------------------------------------------------------------------------
--List of CRQs:	
--CRQ #1) APPLINK-25046: [RegisterAppInterface] SDL behavior in case <Interface> is not supported by system => omit <Interface>-related parameters from response to mobile app (meaning: SDL must NOT retrieve the default values from 'HMI_capabilities.json' file and provide via response to mobile app)		




--Print new line to separate new test cases group
commonFunctions:newTestCasesGroup("Case_1_" .. TestedInterface .."_IsReady_response_available_false")

local TestCaseName = "Case_1"

isReady:StopStartSDL_HMI_MOBILE(self, 0, TestCaseName)

-----------------------------------------------------------------------------------------------		
--CRQ #1) APPLINK-25046: [RegisterAppInterface] SDL behavior in case <Interface> is not supported by system => omit <Interface>-related param from response to mobile app (meaning: SDL must NOT retrieve the default values from 'HMI_capabilities.json' file and provide via response to mobile app)
-- Requirement it applicable for: VR; UI; TTS; VehicleInfo
-- Requirement is NOT applicable for Navigation
-- Verification criteria:
-- 		In case HMI respond <Interface>.IsReady (available=false) to SDL (<Interface>: VehicleInfo, TTS, UI, VR)
-- 		and mobile app sends RegisterAppInterface_request to SDL
-- 		and SDL successfully registers this application (see req-s # APPLINK-16420, APPLINK-16251, APPLINK-16250, APPLINK-16249, APPLINK-16320, APPLINK-15686, APPLINK-16307)
-- SDL must:
--		omit <Interface>-related param from response to mobile app (meaning: SDL must NOT retrieve the default values from 'HMI_capabilities.json' file and provide via response to mobile app)		
-----------------------------------------------------------------------------------------------		


--List of resultCodes: APPLINK-16420 SUCCESS, APPLINK-16251 WRONG_LANGUAGE, APPLINK-16250 WRONG_LANGUAGE languageDesired, APPLINK-16249 WRONG_LANGUAGE hmiDisplayLanguageDesired, APPLINK-16320 UNSUPPORTED_RESOURCE unavailable/not supported component, APPLINK-15686 RESUME_FAILED, APPLINK-16307 WARNINGS, true
	
-- APPLINK-16420 SUCCESS
-- Precondition: App has not been registered yet.			
local function RAI_SUCCESS(count)
	if(count == nil) then count = 0 end
	
	commonFunctions:newTestCasesGroup("Verify RAI: resultCode SUCCESS")
	
	Test["TC_"..count.."_RegisterApplication_Check_"..TestedInterface.."_Parameters_IsOmitted_resultCode_SUCCESS_"..TestCaseName] = function(self)
		
		commonTestCases:DelayedExp(iTimeout)
		
		--mobile side: RegisterAppInterface request
		local CorIdRegister=self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
		
		--hmi side: expect BasicCommunication.OnAppRegistered request
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
		{
			application=
			{
				appName=config.application1.registerAppInterfaceParams.appName
			}
		})
		:Do(function(_,data)
			self.appName=data.params.application.appName
			self.applications[config.application1.registerAppInterfaceParams.appName]=data.params.application.appID
		end)
		
		--mobile side: expect response
		-- SDL does not send VR-related param to mobile app	
		self.mobileSession:ExpectResponse(CorIdRegister, {success=true,resultCode="SUCCESS"})
		:ValidIf (function(_,data)
			if(TestedInterface ~= "Navigation") then
				local errorMessage = ""
				
				------------------------------------------------------------------------------------------
				-- VR:
				if ( data.payload.vrCapabilities and (TestedInterface == "VR") )then
					errorMessage = errorMessage .. "SDL resends 'vrCapabilities' parameter to mobile app. "
				end
				-- The parameter will be sent in case TTS.IsReady is transmitted. Additional check is done in test RAI_Language_TTS_VR_available_false
				if ( (data.payload.language == nil) and (TestedInterface == "VR") )then
				 	errorMessage = errorMessage .. "SDL doesn't resend 'language' parameter because of TTS to mobile app"
				end	
				------------------------------------------------------------------------------------------
				-- UI:
				if ( data.payload.hmiDisplayLanguage and (TestedInterface == "UI") )then
					errorMessage = errorMessage .. "SDL resends 'hmiDisplayLanguage' parameter to mobile app. "
				end
				if ( data.payload.displayCapabilities and (TestedInterface == "UI") )then
					errorMessage = errorMessage .. "SDL resends 'displayCapabilities' parameter to mobile app. "
				end
				if ( data.payload.audioPassThruCapabilities and (TestedInterface == "UI") )then
					errorMessage = errorMessage .. "SDL resends 'audioPassThruCapabilities' parameter to mobile app. "
				end
				if ( data.payload.hmiCapabilities and (TestedInterface == "UI") )then
					errorMessage = errorMessage .. "SDL resends 'hmiCapabilities' parameter to mobile app. "
				end						
				------------------------------------------------------------------------------------------
				-- TTS:
				--The parameter will be sent in case VR.IsReady is transmitted. Additional check is done in test RAI_Language_TTS_VR_available_false
				if ( (data.payload.language == nil) and (TestedInterface == "TTS") )then
				 	errorMessage = errorMessage .. "SDL doesn't resend 'language' parameter because of VR to mobile app"
				end	
				if ( data.payload.speechCapabilities and (TestedInterface == "TTS") )then
					errorMessage = errorMessage .. "SDL resends 'speechCapabilities' parameter to mobile app"
				end
				--TODO: Check parameter name prerecordedSpeech or prerecordedSpeechCapabilities
				if ( data.payload.prerecordedSpeech and (TestedInterface == "TTS") )then
					errorMessage = errorMessage .. "SDL resends 'prerecordedSpeech' parameter to mobile app"
				end
				------------------------------------------------------------------------------------------
				-- VehicleInfo:
				if ( data.payload.vehicleType and (TestedInterface == "VehicleInfo") )then
					errorMessage = errorMessage .. "SDL resends 'vehicleType' parameter to mobile app"
				end	
				------------------------------------------------------------------------------------------
				
				if errorMessage == "" then
					return true					
				else
					commonFunctions:printError(errorMessage)
					return false
				end
				
			end --if(TestedInterface ~= Navigation) then
		end)
		
		--mobile side: expect notification
		self.mobileSession:ExpectNotification("OnHMIStatus", { systemContext="MAIN", hmiLevel="NONE", audioStreamingState="NOT_AUDIBLE"})
	end	
end

-- APPLINK-16320 UNSUPPORTED_RESOURCE unavailable/not supported component: It is not applicable for RegisterAppInterface because RegisterAppInterface is not split able request		
-- APPLINK-16251 WRONG_LANGUAGE
-- APPLINK-16250 WRONG_LANGUAGE languageDesired
local function RAI_WRONG_LANGUAGE()

	commonFunctions:newTestCasesGroup("Verify RAI: resultCode WRONG_LANGUAGE")
	
	commonSteps:UnregisterApplication("TC2_Precondition_UnregisterApplication")
	
	Test["TC2_RegisterApplication_Check_"..TestedInterface.."_Parameters_IsOmitted_resultCode_WRONG_LANGUAGE"..TestCaseName ] = function(self)
		
		commonTestCases:DelayedExp(iTimeout)
		
		--Set language = "RU-RU"
		local parameters = commonFunctions:cloneTable(config.application1.registerAppInterfaceParams)
		parameters.languageDesired = "RU-RU"
		
		--mobile side: RegisterAppInterface request
		local CorIdRegister=self.mobileSession:SendRPC("RegisterAppInterface", parameters)
		
		--hmi side: expect BasicCommunication.OnAppRegistered request
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
		{
			application=
			{
				appName=config.application1.registerAppInterfaceParams.appName
			}
		})
		:Do(function(_,data)
			self.appName=data.params.application.appName
			self.applications[config.application1.registerAppInterfaceParams.appName]=data.params.application.appID
		end)
		
		
		--mobile side: expect response
		-- SDL does not send VR-related param to mobile app	
		self.mobileSession:ExpectResponse(CorIdRegister, {success=true,resultCode="WRONG_LANGUAGE"})
		:ValidIf (function(_,data)
			if(TestedInterface ~= "Navigation") then
				local errorMessage = ""
				------------------------------------------------------------------------------------------
				-- VR:
				if ( data.payload.vrCapabilities and (TestedInterface == "VR") )then
					errorMessage = errorMessage .. "SDL resends 'vrCapabilities' parameter to mobile app. "
				end
				-- The parameter will be sent in case TTS.IsReady is transmitted. Additional check is done in test RAI_Language_TTS_VR_available_false
				if ( (data.payload.language == nil) and (TestedInterface == "VR") )then
				 	errorMessage = errorMessage .. "SDL doesn't resend 'language' parameter because of TTS to mobile app"
				end	
				------------------------------------------------------------------------------------------
				-- UI:
				if ( data.payload.hmiDisplayLanguage and (TestedInterface == "UI") )then
					errorMessage = errorMessage .. "SDL resends 'hmiDisplayLanguage' parameter to mobile app. "
				end
				if ( data.payload.displayCapabilities and (TestedInterface == "UI") )then
					errorMessage = errorMessage .. "SDL resends 'displayCapabilities' parameter to mobile app. "
				end
				if ( data.payload.audioPassThruCapabilities and (TestedInterface == "UI") )then
					errorMessage = errorMessage .. "SDL resends 'audioPassThruCapabilities' parameter to mobile app. "
				end
				if ( data.payload.hmiCapabilities and (TestedInterface == "UI") )then
					errorMessage = errorMessage .. "SDL resends 'hmiCapabilities' parameter to mobile app. "
				end						
				------------------------------------------------------------------------------------------
				-- TTS:
				-- The parameter will be sent in case TTS.IsReady is transmitted. Additional check is done in test RAI_Language_TTS_VR_available_false
				if ( (data.payload.language == nil) and (TestedInterface == "TTS") )then
				 	errorMessage = errorMessage .. "SDL doesn't resend 'language' parameter because of VR to mobile app"
				end	

				if ( data.payload.speechCapabilities and (TestedInterface == "TTS") )then
					errorMessage = errorMessage .. "SDL resends 'speechCapabilities' parameter to mobile app"
				end
				--TODO: Check parameter name prerecordedSpeech or prerecordedSpeechCapabilities
				if ( data.payload.prerecordedSpeech and (TestedInterface == "TTS") )then
					errorMessage = errorMessage .. "SDL resends 'prerecordedSpeech' parameter to mobile app"
				end
				------------------------------------------------------------------------------------------
				-- VehicleInfo:
				if ( data.payload.vehicleType and (TestedInterface == "VehicleInfo") )then
					errorMessage = errorMessage .. "SDL resends 'vehicleType' parameter to mobile app"
				end	
				------------------------------------------------------------------------------------------
				
				if errorMessage == "" then
					return true					
				else
					commonFunctions:printError(errorMessage)
					return false
				end
			end --if(TestedInterface ~= Navigation) then
		end)
		
		--mobile side: expect notification
		self.mobileSession:ExpectNotification("OnHMIStatus", { systemContext="MAIN", hmiLevel="NONE", audioStreamingState="NOT_AUDIBLE"})
	end	
end
	
-- APPLINK-16307 WARNINGS, true
local function RAI_WARNINGS()	

	commonFunctions:newTestCasesGroup("Verify RAI: resultCode WARNINGS")
	
	local function update_sdl_preloaded_pt_json()
		pathToFile = commonPreconditions:GetPathToSDL() .. 'sdl_preloaded_pt.json'
		local file = io.open(pathToFile, "r")
		local json_data = file:read("*all") -- may be abbreviated to "*a";
		file:close()
		
		local json = require("modules/json")
		
		local data = json.decode(json_data)
		for k,v in pairs(data.policy_table.functional_groupings) do
			if (data.policy_table.functional_groupings[k].rpcs == nil) then
				--do
				data.policy_table.functional_groupings[k] = nil
			end
		end
		
		
		data.policy_table.app_policies["0000001"] = {
			keep_context = false,
			steal_focus = false,
			priority = "NONE",
			default_hmi = "NONE",
			groups = {"Base-4"}
		}
		data.policy_table.app_policies["0000001"].AppHMIType = {"NAVIGATION"}
		
		data = json.encode(data)
		file = io.open(pathToFile, "w")
		file:write(data)
		file:close()
	end


	Test["RegisterApplication_Check_Parameters_IsOmitted_resultCode_WARNINGS_Precondition_Update_Preload_PT_JSON"] = function(self)					
		--Add AppHMIType = {"NAVIGATION"} for app "0000001"
		--config.application1.registerAppInterfaceParams.AppHMIType = {"NAVIGATION"}
		
		--TODO: Update after comments with Dong
		update_sdl_preloaded_pt_json()
		commonSteps:DeletePolicyTable()
	end
	
	isReady:StopStartSDL_HMI_MOBILE(self, 0, "RegisterApplication_Check_"..TestedInterface.."_Parameters_IsOmitted_resultCode_WARNINGS_Precondition")
		
	Test["TC3_Parameters_IsOmitted_resultCode_WARNINGS_RegisterApplication_Check_"..TestedInterface] = function(self)
		
		--commonTestCases:DelayedExp(iTimeout)
		
		local parameters = commonFunctions:cloneTable(config.application1.registerAppInterfaceParams)
		parameters.appHMIType = {"MEDIA"}
		
		--mobile side: RegisterAppInterface request
		local CorIdRegister=self.mobileSession:SendRPC("RegisterAppInterface", parameters)
		
		--hmi side: expect BasicCommunication.OnAppRegistered request
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
		{
			application=
			{
				appName=config.application1.registerAppInterfaceParams.appName
			}
		})
		:Do(function(_,data)
			self.appName=data.params.application.appName
			self.applications[config.application1.registerAppInterfaceParams.appName]=data.params.application.appID
		end)
		
		-- mobile side: expect response
		-- SDL does not send VR-related param to mobile app	
		self.mobileSession:ExpectResponse(CorIdRegister, {success=true,resultCode="WARNINGS"})
		:ValidIf (function(_,data)
			if(TestedInterface ~= "Navigation") then
				local errorMessage = ""
				------------------------------------------------------------------------------------------
				-- VR:
				if ( data.payload.vrCapabilities and (TestedInterface == "VR") )then
					errorMessage = errorMessage .. "SDL resends 'vrCapabilities' parameter to mobile app. "
				end
				-- The parameter will be sent in case TTS.IsReady is transmitted. Additional check is done in test RAI_Language_TTS_VR_available_false
				if ( (data.payload.language == nil) and (TestedInterface == "VR") )then
				 	errorMessage = errorMessage .. "SDL doesn't resend 'language' parameter because of TTS to mobile app"
				end		
				------------------------------------------------------------------------------------------
				-- UI:
				if ( data.payload.hmiDisplayLanguage and (TestedInterface == "UI") )then
					errorMessage = errorMessage .. "SDL resends 'hmiDisplayLanguage' parameter to mobile app. "
				end
				if ( data.payload.displayCapabilities and (TestedInterface == "UI") )then
					errorMessage = errorMessage .. "SDL resends 'displayCapabilities' parameter to mobile app. "
				end
				if ( data.payload.audioPassThruCapabilities and (TestedInterface == "UI") )then
					errorMessage = errorMessage .. "SDL resends 'audioPassThruCapabilities' parameter to mobile app. "
				end
				if ( data.payload.hmiCapabilities and (TestedInterface == "UI") )then
					errorMessage = errorMessage .. "SDL resends 'hmiCapabilities' parameter to mobile app. "
				end						
				------------------------------------------------------------------------------------------
				-- TTS:
				-- The parameter will be sent in case TTS.IsReady is transmitted. Additional check is done in test RAI_Language_TTS_VR_available_false
				if ( (data.payload.language == nil) and (TestedInterface == "TTS") )then
				 	errorMessage = errorMessage .. "SDL doesn't resend 'language' parameter because of VR to mobile app"
				end	
				if ( data.payload.speechCapabilities and (TestedInterface == "TTS") )then
					errorMessage = errorMessage .. "SDL resends 'speechCapabilities' parameter to mobile app"
				end
				--TODO: Check parameter name prerecordedSpeech or prerecordedSpeechCapabilities
				if ( data.payload.prerecordedSpeech and (TestedInterface == "TTS") )then
					errorMessage = errorMessage .. "SDL resends 'prerecordedSpeech' parameter to mobile app"
				end
				------------------------------------------------------------------------------------------
				-- VehicleInfo:
				if ( data.payload.vehicleType and (TestedInterface == "VehicleInfo") )then
					errorMessage = errorMessage .. "SDL resends 'vehicleType' parameter to mobile app"
				end	
				------------------------------------------------------------------------------------------
				
				if errorMessage == "" then
					return true					
				else
					commonFunctions:printError(errorMessage)
					return false
				end
			end --if(TestedInterface ~= Navigation) then
		end)
		
		--mobile side: expect notification
		self.mobileSession:ExpectNotification("OnHMIStatus", { systemContext="MAIN", hmiLevel="NONE", audioStreamingState="NOT_AUDIBLE"})
	end	
end	
	
-- APPLINK-15686 RESUME_FAILED
--////////////////////////////////////////////////////////////////////////////////////////////--
-- Check absence of resumption in case HashID in RAI is not match
--////////////////////////////////////////////////////////////////////////////////////////////--
local function RAI_RESUME_FAILED()	

	commonFunctions:newTestCasesGroup("Verify RAI: resultCode RESUME_FAILED")
	
	--Precondition:
	commonSteps:UnregisterApplication("Precondition_for_checking_RESUME_FAILED_UnregisterApp")
	commonSteps:RegisterAppInterface("Precondition_for_checking_RESUME_FAILED_RegisterApp")
	commonSteps:ActivationApp(_, "Precondition_for_checking_RESUME_FAILED_ActivateApp")	
	
	if(TestedInterface == "UI") then
		
		function Test:Precondition_for_checking_RESUME_FAILED_AddResumptionData_AddCommand()
			
			commonTestCases:DelayedExp(2000)
			
			--mobile side: sending AddCommand request
			local cid = self.mobileSession:SendRPC("AddCommand",
			{
				cmdID = 1,
				menuParams = 	
				{
					position = 0,
					menuName ="Command 1"
				}, 
				vrCommands = {"VRCommand 1"}
			})
			
			--hmi side: expect there is no UI.AddCommand request 
			EXPECT_HMICALL("UI.AddCommand", {})
			:Times(0)
			
			--hmi side: expect VR.AddCommand request 
			EXPECT_HMICALL("VR.AddCommand", 
			{ 
				cmdID = 1,							
				type = "Command",
				vrCommands = 
				{
					"VRCommand 1"
				}
			})
			:Do(function(_,data)
				--hmi side: sending VR.AddCommand response 
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)	
			
			--mobile side: expect AddCommand response 
			EXPECT_RESPONSE(cid, { success = true, resultCode = "UNSUPPORTED_RESOURCE" })
			
			--mobile side: expect OnHashChange notification
			--Requirement id in JAMA/or Jira ID: APPLINK-15682
			--[Data Resumption]: OnHashChange
			EXPECT_NOTIFICATION("OnHashChange")
			:Do(function(_, data)
				self.currentHashID = data.payload.hashID
			end)						
			
		end
		
		function Test:Precondition_for_checking_RESUME_FAILED_AddResumptionData_CreateInteractionChoiceSet()
			--mobile side: sending CreateInteractionChoiceSet request
			local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
			{
				interactionChoiceSetID = 1,
				choiceSet = 
				{ 
					
					{ 
						choiceID = 1,
						menuName = "Choice 1",
						vrCommands = 
						{ 
							"VrChoice 1",
						}
					}
				}
			})
			
			
			--hmi side: expect VR.AddCommand request
			EXPECT_HMICALL("VR.AddCommand", 
			{ 
				cmdID = 1,
				appID = self.applications[config.application1.registerAppInterfaceParams.appName],
				type = "Choice",
				vrCommands = {"VrChoice 1"}
			})
			:Do(function(_,data)
				--hmi side: sending VR.AddCommand response
				grammarIDValue = data.params.grammarID
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			
			--mobile side: expect CreateInteractionChoiceSet response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			:Do(function(_,data)
				
				--mobile side: expect OnHashChange notification
				--Requirement id in JAMA/or Jira ID: APPLINK-15682
				--[Data Resumption]: OnHashChange
				EXPECT_NOTIFICATION("OnHashChange")
				:Do(function(_, data)
					self.currentHashID = data.payload.hashID
				end)
			end)
		end
		
		function Test:Precondition_for_checking_RESUME_FAILED_AddResumptionData_AddSubMenu()
			
			commonTestCases:DelayedExp(2000)
			
			--mobile side: sending AddSubMenu request
			local cid = self.mobileSession:SendRPC("AddSubMenu",
			{
				menuID = 1,
				position = 500,
				menuName = "SubMenupositive 1"
			})
			
			--hmi side: expect there is no UI.AddSubMenu request
			EXPECT_HMICALL("UI.AddSubMenu", {})
			:Times(0)
			
			--mobile side: expect AddSubMenu response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "UNSUPPORTED_RESOURCE" })
			
			--mobile side: expect OnHashChange notification					
			--Requirement id in JAMA/or Jira ID: APPLINK-15682
			--[Data Resumption]: OnHashChange
			EXPECT_NOTIFICATION("OnHashChange")
			:Times(0)
			
		end
		
		function Test:Precondition_for_checking_RESUME_FAILED_AddResumptionData_SetGlobalProperites()
			
			commonTestCases:DelayedExp(2000)
			
			--mobile side: sending SetGlobalProperties request
			local cid = self.mobileSession:SendRPC("SetGlobalProperties",
			{
				menuTitle = "Menu Title",
				timeoutPrompt = 
				{
					{
						text = "Timeout prompt",
						type = "TEXT"
					}
				},
				vrHelp = 
				{
					{
						position = 1,
						text = "VR help item"
					}
				},
				helpPrompt = 
				{
					{
						text = "Help prompt",
						type = "TEXT"
					}
				},
				vrHelpTitle = "VR help title",
			})
			
			if(TestedInterface ~= "TTS") then
				--hmi side: expect TTS.SetGlobalProperties request
				EXPECT_HMICALL("TTS.SetGlobalProperties",
				{
					timeoutPrompt = 
					{
						{
							text = "Timeout prompt",
							type = "TEXT"
						}
					},
					helpPrompt = 
					{
						{
							text = "Help prompt",
							type = "TEXT"
						}
					}
				})
				:Do(function(_,data)
					--hmi side: sending UI.SetGlobalProperties response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
			end
			
			--hmi side: expect UI.SetGlobalProperties request
			EXPECT_HMICALL("UI.SetGlobalProperties", {})
			:Times(0)
						
			--mobile side: expect SetGlobalProperties response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "UNSUPPORTED_RESOURCE"})
			
			--Requirement id in JAMA/or Jira ID: APPLINK-15682
			--[Data Resumption]: OnHashChange
			EXPECT_NOTIFICATION("OnHashChange")
			:Do(function(_, data)
				self.currentHashID = data.payload.hashID
			end)
			
		end
		
		function Test:Precondition_for_checking_RESUME_FAILED_AddResumptionData_SubscribeButton()
			
			commonTestCases:DelayedExp(2000)
			
			--SubscribeButton RPC is related to UI interface.
			
			--mobile side: sending SubscribeButton request
			local cid = self.mobileSession:SendRPC("SubscribeButton", {buttonName = "PRESET_0"})
			
			--expect Buttons.OnButtonSubscription
			EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", 
			{
				appID = self.applications[config.application1.registerAppInterfaceParams.appName], 
				isSubscribed = true, 
				name = "PRESET_0"
			})
			:Times(0)
			
			--mobile side: expect SubscribeButton response
			EXPECT_RESPONSE(cid, {success = false, resultCode = "UNSUPPORTED_RESOURCE"})
			
			--Requirement id in JAMA/or Jira ID: APPLINK-15682
			--[Data Resumption]: OnHashChange
			EXPECT_NOTIFICATION("OnHashChange")
			:Times(0)
			
		end
		
		function Test:Precondition_for_checking_RESUME_FAILED_AddResumptionData_SubscribeVehicleData()
			
			--mobile side: sending SubscribeVehicleData request
			local cid = self.mobileSession:SendRPC("SubscribeVehicleData",{gps = true})
			
			--hmi side: expect SubscribeVehicleData request
			EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true})
			:Do(function(_,data)
				--hmi side: sending VehicleInfo.SubscribeVehicleData response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { gps = { resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})	
			end)
			
			--mobile side: expect SubscribeVehicleData response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
			:Do(function(_,data)
				
				--mobile side: expect OnHashChange notification
				--Requirement id in JAMA/or Jira ID: APPLINK-15682
				--[Data Resumption]: OnHashChange
				EXPECT_NOTIFICATION("OnHashChange")
				:Do(function(_, data)
					self.currentHashID = data.payload.hashID
				end)
			end)
		end
		
		function Test:Precondition_for_checking_RESUME_FAILED_AddResumptionData_SubscribeWayPoints()
			
			local cid = self.mobileSession:SendRPC("SubscribeWayPoints", {})
			
			--hmi side: expected SubscribeWayPoints request
			EXPECT_HMICALL("Navigation.SubscribeWayPoints")
			:Do(function(_,data)
				--hmi side: sending Navigation.SubscribeWayPoints response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			
			--mobile side: SubscribeWayPoints response
			EXPECT_RESPONSE(cid, {success = true , resultCode = "SUCCESS"})
			:Do(function(_,data)
				--Requirement id in JAMA/or Jira ID: APPLINK-15682
				--[Data Resumption]: OnHashChange
				
				--userPrint(31,"DEFECT ID: APPLINK-25808")
				EXPECT_NOTIFICATION("OnHashChange")
				:Do(function(_, data)
					self.currentHashID = data.payload.hashID
				end)
			end)
		end
		
	else
		-- Update this part for other interface: VR, VehicleInfo, TTS.
		
		if(TestedInterface ~= "VR") then
			function Test:Precondition_for_checking_RESUME_FAILED_AddResumptionData_AddCommand()
				
				--mobile side: sending AddCommand request
				local cid = self.mobileSession:SendRPC("AddCommand",
				{
					cmdID = 1,
					menuParams = 	
					{
						position = 0,
						menuName ="Command 1"
					}, 
					vrCommands = {"VRCommand 1"}
				})
				
				--hmi side: expect UI.AddCommand request 
				EXPECT_HMICALL("UI.AddCommand", 
				{ 
					cmdID = icmdID,		
					menuParams = 
					{
						position = 0,
						menuName ="Command 1"
					}
				})
				:Do(function(_,data)
					--hmi side: sending UI.AddCommand response 
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
				
				--hmi side: expect VR.AddCommand request 
				EXPECT_HMICALL("VR.AddCommand", 
				{ 
					cmdID = 1,							
					type = "Command",
					vrCommands = 
					{
						"VRCommand 1"
					}
				})
				:Do(function(_,data)
					--hmi side: sending VR.AddCommand response 
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)	
				
				
				--mobile side: expect AddCommand response 
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
				:Do(function()
					--mobile side: expect OnHashChange notification
					--Requirement id in JAMA/or Jira ID: APPLINK-15682
					--[Data Resumption]: OnHashChange
					EXPECT_NOTIFICATION("OnHashChange")
					:Do(function(_, data)
						self.currentHashID = data.payload.hashID
					end)
				end)				
			end
			
			function Test:Precondition_for_checking_RESUME_FAILED_AddResumptionData_CreateInteractionChoiceSet()
				--mobile side: sending CreateInteractionChoiceSet request
				local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
				{
					interactionChoiceSetID = 1,
					choiceSet = 
					{ 
						
						{ 
							choiceID = 1,
							menuName = "Choice 1",
							vrCommands = 
							{ 
								"VrChoice 1",
							}
						}
					}
				})
				
				
				--hmi side: expect VR.AddCommand request
				EXPECT_HMICALL("VR.AddCommand", 
				{ 
					cmdID = 1,
					appID = self.applications[config.application1.registerAppInterfaceParams.appName],
					type = "Choice",
					vrCommands = {"VrChoice 1"}
				})
				:Do(function(_,data)
					--hmi side: sending VR.AddCommand response
					grammarIDValue = data.params.grammarID
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
				
				--mobile side: expect CreateInteractionChoiceSet response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
				:Do(function(_,data)
					
					--mobile side: expect OnHashChange notification
					--Requirement id in JAMA/or Jira ID: APPLINK-15682
					--[Data Resumption]: OnHashChange
					EXPECT_NOTIFICATION("OnHashChange")
					:Do(function(_, data)
						self.currentHashID = data.payload.hashID
					end)
				end)
			end
		end
		
		function Test:Precondition_for_checking_RESUME_FAILED_AddResumptionData_AddSubMenu()
			
			--mobile side: sending AddSubMenu request
			local cid = self.mobileSession:SendRPC("AddSubMenu",
			{
				menuID = 1,
				position = 500,
				menuName = "SubMenupositive 1"
			})
			
			--hmi side: expect UI.AddSubMenu request
			EXPECT_HMICALL("UI.AddSubMenu", 
			{ 
				menuID = 1,
				menuParams = {
					position = 500,
					menuName = "SubMenupositive 1"
				}
			})
			:Do(function(_,data)
				--hmi side: sending UI.AddSubMenu response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			
			--mobile side: expect AddSubMenu response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			:Do(function()
				--mobile side: expect OnHashChange notification
				
				--Requirement id in JAMA/or Jira ID: APPLINK-15682
				--[Data Resumption]: OnHashChange
				EXPECT_NOTIFICATION("OnHashChange")
				:Do(function(_, data)
					self.currentHashID = data.payload.hashID
				end)
			end)
		end
		
		function Test:Precondition_for_checking_RESUME_FAILED_AddResumptionData_SetGlobalProperites()
			
			--mobile side: sending SetGlobalProperties request
			local cid = self.mobileSession:SendRPC("SetGlobalProperties",
			{
				menuTitle = "Menu Title",
				timeoutPrompt = 
				{
					{
						text = "Timeout prompt",
						type = "TEXT"
					}
				},
				vrHelp = 
				{
					{
						position = 1,
						text = "VR help item"
					}
				},
				helpPrompt = 
				{
					{
						text = "Help prompt",
						type = "TEXT"
					}
				},
				vrHelpTitle = "VR help title",
			})
			
			if(TestedInterface ~= "TTS") then 
				--hmi side: expect TTS.SetGlobalProperties request
				EXPECT_HMICALL("TTS.SetGlobalProperties",
				{
					timeoutPrompt = 
					{
						{
							text = "Timeout prompt",
							type = "TEXT"
						}
					},
					helpPrompt = 
					{
						{
							text = "Help prompt",
							type = "TEXT"
						}
					}
				})
				:Do(function(_,data)
					--hmi side: sending UI.SetGlobalProperties response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
			end
			
			--hmi side: expect UI.SetGlobalProperties request
			EXPECT_HMICALL("UI.SetGlobalProperties",
			{
				menuTitle = "Menu Title",
				vrHelp = 
				{
					{
						position = 1,
						text = "VR help item"
					}
				},
				vrHelpTitle = "VR help title"
			})
			:Do(function(_,data)
				--hmi side: sending UI.SetGlobalProperties response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			
			if( (TestedInterface ~= "TTS") and (TestedInterface ~= "UI") ) then
				--mobile side: expect SetGlobalProperties response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
				:Do(function(_,data)
					
					--Requirement id in JAMA/or Jira ID: APPLINK-15682
					--[Data Resumption]: OnHashChange
					EXPECT_NOTIFICATION("OnHashChange")
					:Do(function(_, data)
						self.currentHashID = data.payload.hashID
					end)
				end)
			else
				EXPECT_RESPONSE(cid, { resultCode = "UNSUPPORTED_RESOURCE"})
			end
		end
		
		function Test:Precondition_for_checking_RESUME_FAILED_AddResumptionData_SubscribeButton()
			
			--SubscribeButton RPC is related to UI interface.
			
			--mobile side: sending SubscribeButton request
			local cid = self.mobileSession:SendRPC("SubscribeButton", {buttonName = "PRESET_0"})
			
			--expect Buttons.OnButtonSubscription
			EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", 
			{
				appID = self.applications[config.application1.registerAppInterfaceParams.appName], 
				isSubscribed = true, 
				name = "PRESET_0"
			})
			
			--mobile side: expect SubscribeButton response
			EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
			:Do(function(_,data)
				
				--Requirement id in JAMA/or Jira ID: APPLINK-15682
				--[Data Resumption]: OnHashChange
				EXPECT_NOTIFICATION("OnHashChange")
				:Do(function(_, data)
					self.currentHashID = data.payload.hashID
				end)
			end)
		end
		
		if(TestedInterface ~= "VehicleInfo") then
			function Test:Precondition_for_checking_RESUME_FAILED_AddResumptionData_SubscribeVehicleData()
				
				--mobile side: sending SubscribeVehicleData request
				local cid = self.mobileSession:SendRPC("SubscribeVehicleData",{gps = true})
				
				--hmi side: expect SubscribeVehicleData request
				EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true})
				:Do(function(_,data)
					--hmi side: sending VehicleInfo.SubscribeVehicleData response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { gps = { resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})	
				end)
				
				--mobile side: expect SubscribeVehicleData response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
				:Do(function(_,data)
					
					--mobile side: expect OnHashChange notification
					--Requirement id in JAMA/or Jira ID: APPLINK-15682
					--[Data Resumption]: OnHashChange
					EXPECT_NOTIFICATION("OnHashChange")
					:Do(function(_, data)
						self.currentHashID = data.payload.hashID
					end)
				end)
			end
		end
		
		function Test:Precondition_for_checking_RESUME_FAILED_AddResumptionData_SubscribeWayPoints()
			
			local cid = self.mobileSession:SendRPC("SubscribeWayPoints", {})
			
			--hmi side: expected SubscribeWayPoints request
			EXPECT_HMICALL("Navigation.SubscribeWayPoints")
			:Do(function(_,data)
				--hmi side: sending Navigation.SubscribeWayPoints response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			
			--mobile side: SubscribeWayPoints response
			EXPECT_RESPONSE(cid, {success = true , resultCode = "SUCCESS"})
			:Do(function(_,data)
				--Requirement id in JAMA/or Jira ID: APPLINK-15682
				--[Data Resumption]: OnHashChange
				
				--userPrint(31,"DEFECT ID: APPLINK-25808")
				EXPECT_NOTIFICATION("OnHashChange")
				:Do(function(_, data)
					self.currentHashID = data.payload.hashID
				end)
			end)
		end
		
	end
	
	
	function Test:Precondition_for_checking_RESUME_FAILED_CloseConnection()
		
		self.mobileConnection:Close() 
		
	end
	
	function Test:Precondition_for_checking_RESUME_FAILED_ConnectMobile()
		os.execute("sleep 30") -- sleep 30s to wait for SDL detects app is disconnected unexpectedly.
		self:connectMobile()
	end
	
	function Test:Precondition_for_checking_RESUME_FAILED_StartSession()
		self.mobileSession = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		config.application1.registerAppInterfaceParams)
		
		self.mobileSession:StartService(7)
	end
	

	Test["TC4_RegisterApplication_Check_"..TestedInterface.."_Parameters_IsOmitted_resultCode_RESUME_FAILED"] = function(self)
		
		commonTestCases:DelayedExp(iTimeout)
		
		local parameters = commonFunctions:cloneTable(config.application1.registerAppInterfaceParams)
		parameters.hashID = "sdfgTYWRTdfhsdfgh"
		
		--mobile side: RegisterAppInterface request
		local CorIdRegister=self.mobileSession:SendRPC("RegisterAppInterface", parameters)
		
		--hmi side: expect BasicCommunication.OnAppRegistered request
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
		{
			application=
			{
				appName=config.application1.registerAppInterfaceParams.appName
			}
		})
		:Do(function(_,data)
			self.appName=data.params.application.appName
			self.applications[config.application1.registerAppInterfaceParams.appName]=data.params.application.appID
		end)
		
		--hmi side: expect BasicCommunication.ActivateApp request
		EXPECT_HMICALL("BasicCommunication.ActivateApp", {})
		:Do(function(_,data)
			--hmi side: sending response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		
		
		--mobile side: expect response
		-- SDL does not send VR-related param to mobile app	
		self.mobileSession:ExpectResponse(CorIdRegister, {success=true,resultCode="RESUME_FAILED"})
		:ValidIf (function(_,data)
			if(TestedInterface ~= "Navigation") then
				local errorMessage = ""
				------------------------------------------------------------------------------------------
				-- VR:
				if ( data.payload.vrCapabilities and (TestedInterface == "VR") )then
					errorMessage = errorMessage .. "SDL resends 'vrCapabilities' parameter to mobile app. "
				end
				-- The parameter will be sent in case TTS.IsReady is transmitted. Additional check is done in test RAI_Language_TTS_VR_available_false
				if ( (data.payload.language == nil) and (TestedInterface == "VR") )then
				 	errorMessage = errorMessage .. "SDL doesn't resend 'language' parameter because of TTS to mobile app"
				end	
				------------------------------------------------------------------------------------------
				-- UI:
				if ( data.payload.hmiDisplayLanguage and (TestedInterface == "UI") )then
					errorMessage = errorMessage .. "SDL resends 'hmiDisplayLanguage' parameter to mobile app. "
				end
				if ( data.payload.displayCapabilities and (TestedInterface == "UI") )then
					errorMessage = errorMessage .. "SDL resends 'displayCapabilities' parameter to mobile app. "
				end
				if ( data.payload.audioPassThruCapabilities and (TestedInterface == "UI") )then
					errorMessage = errorMessage .. "SDL resends 'audioPassThruCapabilities' parameter to mobile app. "
				end
				if ( data.payload.hmiCapabilities and (TestedInterface == "UI") )then
					errorMessage = errorMessage .. "SDL resends 'hmiCapabilities' parameter to mobile app. "
				end						
				------------------------------------------------------------------------------------------
				-- TTS:
				-- The parameter will be sent in case TTS.IsReady is transmitted. Additional check is done in test RAI_Language_TTS_VR_available_false
				if ( (data.payload.language == nil) and (TestedInterface == "TTS") )then
				 	errorMessage = errorMessage .. "SDL doesn't resend 'language' parameter because of VR to mobile app"
				end	
				if ( data.payload.speechCapabilities and (TestedInterface == "TTS") )then
					errorMessage = errorMessage .. "SDL resends 'speechCapabilities' parameter to mobile app"
				end
				--TODO: Check parameter name prerecordedSpeech or prerecordedSpeechCapabilities
				if ( data.payload.prerecordedSpeech and (TestedInterface == "TTS") )then
					errorMessage = errorMessage .. "SDL resends 'prerecordedSpeech' parameter to mobile app"
				end
				------------------------------------------------------------------------------------------
				-- VehicleInfo:
				if ( data.payload.vehicleType and (TestedInterface == "VehicleInfo") )then
					errorMessage = errorMessage .. "SDL resends 'vehicleType' parameter to mobile app"
				end	
				------------------------------------------------------------------------------------------
				
				if errorMessage == "" then
					return true					
				else
					commonFunctions:printError(errorMessage)
					return false
				end
			end --if(TestedInterface ~= Navigation) then
		end)
		
		
		--mobile side: expect notification									
		self.mobileSession:ExpectNotification("OnHMIStatus", 
		{systemContext="MAIN", hmiLevel="NONE", audioStreamingState="NOT_AUDIBLE"}, 
		{systemContext="MAIN", hmiLevel="FULL", audioStreamingState="AUDIBLE"}
		)
		:Times(2)
		:Timeout(20000)
		
		EXPECT_HMICALL("UI.AddCommand")
		:Times(0)
		
		EXPECT_HMICALL("VR.AddCommand")
		:Times(0)
		
		EXPECT_HMICALL("UI.AddSubMenu")
		:Times(0)
		
		--APPLINK-9532: Sending TTS.SetGlobalProperties to VCA in case no obtained from mobile app
		--Description: When registering the app as soon as the app gets HMI Level NONE, SDL sends TTS.SetGlobalProperties(helpPrompt[]) with an empty array of helpPrompts (just helpPrompts, no timeoutPrompt).
		--hmi side: expect TTS.SetGlobalProperties request
		EXPECT_HMICALL("TTS.SetGlobalProperties")
		:Do(function(_,data)
			--hmi side: sending UI.SetGlobalProperties response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		:ValidIf(function(_,data)
			if data.params.timeoutPrompt then
				commonFunctions:printError("TTS.SetGlobalProperties request came with unexpected timeoutPrompt parameter.")
				return false
			elseif data.params.helpPrompt and #data.params.helpPrompt == 0 then
				return true
			elseif data.params.helpPrompt == nil then
				commonFunctions:printError("UI.SetGlobalProperties request came without helpPrompt")
				return false
			else 
				commonFunctions:printError("UI.SetGlobalProperties request came with some unexpected values of helpPrompt, array length is " .. tostring(#data.params.helpPrompt))
				return false
			end
		end)
		
		EXPECT_HMICALL("UI.SetGlobalProperties")
		:Times(0)
		
		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
		:Times(0)
	end
end

-- Parameter language is transmitted via VR and TTS.
-- Goal: to check that parameter language will be ommited when TTS.IsReady(available = false) and VR.IsReady(available = false) 
local function RAI_Language_TTS_VR_available_false()
	commonFunctions:newTestCasesGroup("Verify RAI: resultCode SUCCESS when TTS.IsReady(available = false) and VR.IsReady(available = false)  ")

	StopStartSDL_HMI_MOBILE_VR_TTS(self)
		
	Test["TC5_RegisterApplication_Check_"..TestedInterface.."_Parameters_IsOmitted_resultCode_SUCCESS_"..TestCaseName] = function(self)
			
		commonTestCases:DelayedExp(iTimeout)
		
		--mobile side: RegisterAppInterface request
		local CorIdRegister=self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
			
		--hmi side: expect BasicCommunication.OnAppRegistered request
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
		{
			application=
			{
				appName=config.application1.registerAppInterfaceParams.appName
			}
		})
		:Do(function(_,data)
			self.appName=data.params.application.appName
			self.applications[config.application1.registerAppInterfaceParams.appName]=data.params.application.appID
		end)
		
		--mobile side: expect response
		-- SDL does not send VR-related param to mobile app	
		self.mobileSession:ExpectResponse(CorIdRegister, {success=true})
		:ValidIf (function(_,data)
			local errorMessage = ""
			------------------------------------------------------------------------------------------
			-- VR and TTS are available = false
			if ( data.payload.language)then
			 	errorMessage = errorMessage .. "SDL resends 'language' parameter to mobile app"
			end	

			------------------------------------------------------------------------------------------
			-- VR:
			if ( data.payload.vrCapabilities)then
				errorMessage = errorMessage .. "SDL resends 'vrCapabilities' parameter to mobile app. "
			end
										
			------------------------------------------------------------------------------------------
			-- TTS:
			if ( data.payload.speechCapabilities)then
				errorMessage = errorMessage .. "SDL resends 'speechCapabilities' parameter to mobile app"
			end
			--TODO: Check parameter name prerecordedSpeech or prerecordedSpeechCapabilities
			if ( data.payload.prerecordedSpeech)then
				errorMessage = errorMessage .. "SDL resends 'prerecordedSpeech' parameter to mobile app"
			end
			------------------------------------------------------------------------------------------
					
			if errorMessage == "" then
				return true					
			else
				commonFunctions:printError(errorMessage)
				return false
			end
		end)
			
		--mobile side: expect notification
		self.mobileSession:ExpectNotification("OnHMIStatus", { systemContext="MAIN", hmiLevel="NONE", audioStreamingState="NOT_AUDIBLE"})
	end	
end

if(TestedInterface ~= "NAVIGATION") then -- for NAVIGATION interface, there is no related parameters to check in RAI response so ignore this case.
	
	-- ToDo: Due to defect when stop and start SDL many times, please only execute 2 times:
	-- The first time: RAI_SUCCESS, RAI_WRONG_LANGUAGE
	
	RAI_SUCCESS()	
	RAI_WRONG_LANGUAGE()
	
	
	-- The second time: RAI_WARNINGS, RAI_RESUME_FAILED
	
	RAI_WARNINGS()	
	RAI_RESUME_FAILED()
	
	if(TestedInterface == "VR" or TestedInterface == "TTS") then
	
		RAI_Language_TTS_VR_available_false()
	end

	for i = 1, #TestData_AvailableFalse do
		
		if ( i == 1) then
			Test["Restore_Preloaded_Before_SUCCESS"] = function (self)
				commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
				commonSteps:DeletePolicyTable()
				commonPreconditions:BackupFile("sdl_preloaded_pt.json")
			end
		end

		commonFunctions:newTestCasesGroup("Case_"..i.."_" .. TestedInterface .."_"..TestData_AvailableFalse[i].description)

		isReady:StopStartSDL_HMI_MOBILE_available_false(self, TestData_AvailableFalse[i].caseID, TestData_AvailableFalse[i].value, TestCaseName)
		
		RAI_SUCCESS(i)
	end

else
	userPrint(33,"Requirements for RAI are not applicable for Navigation.")
	
end --if(TestedInterface ~= "NAVIGATION") then 


----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK IV----------------------------------------
------------------------------Check special cases of HMI response-----------------------------
----------------------------------------------------------------------------------------------

-- These cases are merged into TEST BLOCK III

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK V----------------------------------------
-------------------------------------Checks All Result Codes-----------------------------------
-----------------------------------------------------------------------------------------------

--Not applicable

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VI----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------

--Not applicable

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VII---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------
-- Not applicable

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_RestorePreloadedFile()
	commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end

function Test.Postcondition_Stop()
  StopSDL()
end


return Test