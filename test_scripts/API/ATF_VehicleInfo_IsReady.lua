config.defaultProtocolVersion = 2

---------------------------------------------------------------------------------------------
---------------------------- Required Shared libraries --------------------------------------
---------------------------------------------------------------------------------------------
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
	
DefaultTimeout = 3

local commonPreconditions = require ('/user_modules/shared_testcases/commonPreconditions')
local srcPath = config.pathToSDL .. "sdl_preloaded_pt.json"
local dstPath = config.pathToSDL .. "sdl_preloaded_pt.json.origin"

---------------------------------------------------------------------------------------------
------------------------- General Precondition before ATF start -----------------------------
---------------------------------------------------------------------------------------------
--make backup copy of file sdl_preloaded_pt.json
commonPreconditions:BackupFile("sdl_preloaded_pt.json")
-- TODO: Remove after implementation policy update
-- Precondition: remove policy table
commonSteps:DeletePolicyTable()

-- TODO: Remove after implementation policy update
-- Precondition: replace preloaded file with new one
os.execute('cp ./files/ptu_general.json ' .. tostring(config.pathToSDL) .. "sdl_preloaded_pt.json")

---------------------------------------------------------------------------------------------
---------------------------- General Settings for configuration----------------------------
---------------------------------------------------------------------------------------------
Test = require('connecttest')
require('cardinalities')
local events = require('events')  
local mobile_session = require('mobile_session')
require('user_modules/AppTypes')
local SDLConfig = require('user_modules/shared_testcases/SmartDeviceLinkConfigurations')

---------------------------------------------------------------------------------------------
-------------------------------------------Common function-----------------------------------
---------------------------------------------------------------------------------------------
function sleep(iTimeout)
 os.execute("sleep "..tonumber(iTimeout))
end
function Test:initHMI_onReady_VehicleinfoIsReady(method1, resultCode, params1, case)
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
	    --if ( data.method == "VehicleInfo.IsReady" ) then
		if (name == "VehicleInfo.IsReady") then
			if (case == nil) then
				self.hmiConnection:SendResponse(data.id, method1, resultCode, params1)
			elseif (case == 1) then
				--timeout+ not response
			elseif (case == 2) then
				self.hmiConnection:Send('{}')
			elseif (case == 3) then
				self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0}}')
			elseif (case == 4) then
				self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"VehicleInfo.IsReady"}}')
			elseif (case == 5) then
				self.hmiConnection:Send('{"id"'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"VehicleInfo.IsReady", "code":0}}')
			end
		else
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", params) 			
		end
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
	--:Times(0)
    ExpectRequest("VR.GetLanguage", true, { language = "EN-US" })
	--:Times(0)
    ExpectRequest("TTS.GetLanguage", true, { language = "EN-US" })
	--:Times(0)
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
	  --:Times(0)
    ExpectRequest("TTS.GetSupportedLanguages", true, {
        languages =
        {
          "EN-US","ES-MX","FR-CA","DE-DE","ES-ES","EN-GB","RU-RU","TR-TR","PL-PL",
          "FR-FR","IT-IT","SV-SE","PT-PT","NL-NL","ZH-TW","JA-JP","AR-SA","KO-KR",
          "PT-BR","CS-CZ","DA-DK","NO-NO"
        }
      })
	  --:Times(0)
    ExpectRequest("UI.GetSupportedLanguages", true, {
        languages =
        {
          "EN-US","ES-MX","FR-CA","DE-DE","ES-ES","EN-GB","RU-RU","TR-TR","PL-PL",
          "FR-FR","IT-IT","SV-SE","PT-PT","NL-NL","ZH-TW","JA-JP","AR-SA","KO-KR",
          "PT-BR","CS-CZ","DA-DK","NO-NO"
        }
      })
	  --:Times(0)
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
    ExpectRequest("VR.GetCapabilities", true, { vrCapabilities = { "TEXT" } })
	--:Times(0)
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
	  --:Times(0)

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
	  --:Times(0)

    ExpectRequest("VR.IsReady", true, { available = true })
    ExpectRequest("TTS.IsReady", true, { available = true })
    ExpectRequest("UI.IsReady", true, { available = true })
    ExpectRequest("Navigation.IsReady", true, { available = true })
	ExpectRequest("VehicleInfo.IsReady", true, params1)

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
 -- Stop SDL, start SDL, HMI initialization with specified modes, create mobile connection. HMI respond mode with Vehicleinfo.IsReady: 
		--1. available = false
		--2. HMI doen't respond after defaulttimeout (10s in .ini file)
		--3. Empty method
		--4. Empty availabe
		--5. Missing all parameters
		--6. Missing Method parameter
		--7. Missing available parameter
		--8. Missing resultcode
		--9. Wrong type of method
		--10. Wrong type of availabe
		--11. Wrong type of resultcode
		--12. Nonexistedt resultcode
		--13. Invalid Json
local function RestartSDL_InitHMI_ConnectMobile(self, Note, description, method, parameter, resultCode, case)
	
	--Stop SDL
	Test[tostring(Note) .. "_StopSDL"] = function(self)
		StopSDL()
	end
	--Start SDL
	Test[tostring(Note) .. "_StartSDL"] = function(self)
		StartSDL(config.pathToSDL, config.ExitOnCrash)
	end
	--InitHMI
	Test[tostring(Note) .. "_InitHMI"] = function(self)
		self:initHMI()
	end
	
	--InitHMIonReady
	Test[tostring(Note) .. "_initHMI_onReady_initHMI_onReady_" .. tostring(description)] = function(self)
		self:initHMI_onReady_VehicleinfoIsReady(method, resultCode,  parameter, case)
	end
	
	if case == 1 then
		Test[tostring(Note) .. "_DefaultTimeout" .. tostring(description)] = function(self)
			sleep(DefaultTimeout)
		end
	end
	
	--ConnectMobile
	Test[tostring(Note) .. "_ConnectMobile"] = function(self)
		self:connectMobile()
	end
	--StartSession
	Test[tostring(Note) .. "_StartSession"] = function(self)
		self.mobileSession= mobile_session.MobileSession(
		    self,
		    self.mobileConnection)
	    self.mobileSession:StartService(7)
	end
end
 
	
---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
	-- Description: Activation app for precondition
	commonSteps:ActivationApp(self)
  

	-----------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------
-----------------------------------------I TEST BLOCK----------------------------------------
-------CommonRequestCheck: Check of request's VehicleInfo.IsReady parameters from SDL--------
---------------------------------------------------------------------------------------------
	--Begin Test suit PositiveRequestCheck

	--Description: TC's checks processing 
		--VehicleInfo.IsReady: availabe = true
		--This test is intended to check positive cases and when VehicleInfo.IsReady: availabe = true, and mobile requests ReadDID, SDL sends SUCCESS to mobile app

		--Requirement id in JAMA: 
				--SDLAQ-CRS-21
				
		--Description: ReadDID request adds the command to VehicleInfo Menu, VehicleInfo menu or to the both depending on the parameters sent (VehicleInfo commands or the both correspondingly);
		function Test:ReadDID_SUCCESS()
		
			local cid = self.mobileSession:SendRPC("ReadDID",
			{ 
				ecuName = 2000,
				didLocation = 
				{ 
					56832
				}
			})
			
			--hmi side: expect ReadDID request
			EXPECT_HMICALL("VehicleInfo.ReadDID",{ 
				ecuName = 2000,
				didLocation = 
				{ 
					56832
				}
			})
			:Do(function(_,data)
				--hmi side: sending VehicleInfo.ReadDID response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {didResult = {{data = "123", didLocation = 56832, resultCode = "SUCCESS"}}})
			end)
			
			--mobile side: expect ReadDID response
			EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", didResult = {{data = "123", didLocation = 56832, resultCode = "SUCCESS"}}})

		end
				
		-----------------------------------------------------------------------------------------
		
		--Description: This test is intended to check positive cases and when VehicleInfo.IsReady: availabe = true, and mobile requests GetDTCs, SDL sends SUCCESS to mobile app
		function Test:GetDTCs_SUCCESS()
		
			local cid = self.mobileSession:SendRPC("GetDTCs",
			{ 
				dtcMask = 42,
				ecuName = 2000
			})
			
			--hmi side: expect GetDTCs request
			EXPECT_HMICALL("VehicleInfo.GetDTCs",
			{ 
				dtcMask = 42,
				ecuName = 2000
			})
			:Do(function(_,data)
				--hmi side: sending VehicleInfo.GetDTCs response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {ecuHeader = 2, dtc = {"line 0", "line 1", "line 2"}})
			end)
			
			--mobile side: expect GetDTCs response
			EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", ecuHeader = 2, dtc = {"line 0", "line 1", "line 2"}})

		end
				
		-----------------------------------------------------------------------------------------
		
		--Description: This test is intended to check positive cases and when VehicleInfo.IsReady: availabe = true, and mobile requests DiagnosticMessage, SDL sends SUCCESS to mobile app
		function Test:DiagnosticMessage_SUCCESS()
		
			local cid = self.mobileSession:SendRPC("DiagnosticMessage",
			{ 
				targetID = 42,
				messageLength = 8,
				messageData = {1}
			})
			
			--hmi side: expect DiagnosticMessage request
			EXPECT_HMICALL("VehicleInfo.DiagnosticMessage",
			{ 
				targetID = 42,
				messageLength = 8,
				messageData = {1}
			})
			:Do(function(_,data)
				--hmi side: sending VehicleInfo.DiagnosticMessage response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {messageDataResult = {200}})
			end)
			
			--mobile side: expect DiagnosticMessage response
			EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})

		end
				
		-----------------------------------------------------------------------------------------		

		--Description: This test is intended to check positive cases and when VehicleInfo.IsReady: availabe = true, and mobile requests SubscribeVehicleData, SDL sends SUCCESS to mobile app
		function Test:SubscribeVehicleData_SUCCESS()
		
			local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
			{ 
				airbagStatus = true
			})
			
			--hmi side: expect SubscribeVehicleData request
			EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",
			{ 
				airbagStatus = true
			})
			:Do(function(_,data)
				--hmi side: sending VehicleInfo.SubscribeVehicleData response				
				self.hmiConnection:SendResponse( data.id, data.method, "SUCCESS", {airbagStatus = {dataType="VEHICLEDATA_PRNDL", resultCode="SUCCESS"}})
			end)
			
			--mobile side: expect SubscribeVehicleData response
			EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", airbagStatus = {dataType = "VEHICLEDATA_PRNDL", resultCode = "SUCCESS"}})
		end
				
		-----------------------------------------------------------------------------------------
		
		--Description: This test is intended to check positive cases and when VehicleInfo.IsReady: availabe = true, and mobile has ready subscribed, HMI sends OnVehicleData, SDL sends OnVehicleData notification to mobile app
		function Test:SUCCESS_OnVehicleData_Notification()
		
			--hmi side: sending VehicleInfo.OnVehicleData notification					
			self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", {airbagStatus = 
								{   driverAirbagDeployed = "NO"
								}})
			
			--mobile side: expected SubscribeVehicleData response
			EXPECT_NOTIFICATION("OnVehicleData", {airbagStatus = {driverAirbagDeployed = "NO"}})
			:Times(0)
			
			commonTestCases:DelayedExp(1000)
			
		end
				
		-----------------------------------------------------------------------------------------		
		
		--Description: This test is intended to check positive cases and when VehicleInfo.IsReady: availabe = true, and mobile requests UnsubscribeVehicleData, SDL sends SUCCESS to mobile app
		function Test:UnsubscribeVehicleData_SUCCESS()
			local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
			{ 
				airbagStatus = true
			})
			
			--hmi side: expect UnsubscribeVehicleData request
			EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",
			{ 
				airbagStatus = true
			})
			:Do(function(_,data)
				--hmi side: sending VehicleInfo.UnsubscribeVehicleData response				
				self.hmiConnection:SendResponse( data.id, data.method, "SUCCESS", {airbagStatus = {dataType="VEHICLEDATA_PRNDL", resultCode="SUCCESS"}})
			end)
			
			--mobile side: expect UnsubscribeVehicleData response
			EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
			
		end
				
		-----------------------------------------------------------------------------------------
		
		--Description: This test is intended to check positive cases and when VehicleInfo.IsReady: availabe = true, and mobile requests GetVehicleData, SDL sends SUCCESS to mobile app
		function Test:GetVehicleData_SUCCESS()
		
			local cid = self.mobileSession:SendRPC("GetVehicleData",
			{ 
				airbagStatus = true
			})
			
			--hmi side: expect GetVehicleData request
			EXPECT_HMICALL("VehicleInfo.GetVehicleData",
			{ 
				airbagStatus = true
			})
			:Do(function(_,data)
				--hmi side: sending VehicleInfo.GetVehicleData response				
				self.hmiConnection:SendResponse( data.id, data.method, "SUCCESS", {	airbagStatus=
						{
							driverAirbagDeployed = "NOT_SUPPORTED",
							driverSideAirbagDeployed = "NOT_SUPPORTED",
							driverCurtainAirbagDeployed = "NOT_SUPPORTED",
							passengerAirbagDeployed = "NOT_SUPPORTED",
							passengerCurtainAirbagDeployed = "NOT_SUPPORTED",
							driverKneeAirbagDeployed = "NOT_SUPPORTED",
							passengerSideAirbagDeployed = "NOT_SUPPORTED",
							passengerKneeAirbagDeployed = "NOT_SUPPORTED"
						}})
			end)
			
			--mobile side: expect GetVehicleData response
			EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", airbagStatus=
						{
							driverAirbagDeployed = "NOT_SUPPORTED",
							driverSideAirbagDeployed = "NOT_SUPPORTED",
							driverCurtainAirbagDeployed = "NOT_SUPPORTED",
							passengerAirbagDeployed = "NOT_SUPPORTED",
							passengerCurtainAirbagDeployed = "NOT_SUPPORTED",
							driverKneeAirbagDeployed = "NOT_SUPPORTED",
							passengerSideAirbagDeployed = "NOT_SUPPORTED",
							passengerKneeAirbagDeployed = "NOT_SUPPORTED"
						}})
		end
				
		-----------------------------------------------------------------------------------------

		

----------------------------------------------------------------------------------------------
----------------------------------------II TEST BLOCK----------------------------------------
----------------------------------------Negative cases----------------------------------------
----------------------------------------------------------------------------------------------

	--=================================================================================--
	---------------------------------Negative request check------------------------------
	--=================================================================================--

		--------Checks-----------
		-- available = False
		-- invalid values(empty, missing, nonexistent, duplicate, invalid characters)
		-- parameters with wrong type
		-- invalid json

		--Begin Test case NegativeRequestCheck.1
		--Description:

			--Requirement id in JAMA:
				--APPLINK-20918

		--Description: in case HMI does NOT respond at <interface>-related RPC during <DefaultTimeout> -> SDL must send UNSUPPORTED_RESOURCE to mobile app (per <interface>-related RPC)
		local function SequenceVehicleInfo_IsReadyFalse_UNSUPPORTED_RESOURCE()

			local TimeoutValue = 10000
			--Description: ReadDID request adds the command to VehicleInfo Menu, VehicleInfo menu or to the both depending on the parameters sent (VehicleInfo commands or the both correspondingly);
			function Test:ReadDID_UNSUPPORTED_RESOURCE()
			
				local cid = self.mobileSession:SendRPC("ReadDID",
				{ 
					ecuName = 2000,
					didLocation = 
					{ 
						56832
					}
				})
				
				EXPECT_HMICALL("VehicleInfo.ReadDID")
				:Times(0)
				
				commonTestCases:DelayedExp(1000)
				
				--mobile side: expect ReadDID response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "UNSUPPORTED_RESOURCE" })
				:Timeout(TimeoutValue)
				
			end
					
			-----------------------------------------------------------------------------------------
			
			--Description: This test is intended to check positive cases and when VehicleInfo.IsReady: availabe = false, and mobile requests GetDTCs, SDL sends UNSUPPORTED_RESOURCE to mobile app
			function Test:GetDTCs_UNSUPPORTED_RESOURCE()
			
				local cid = self.mobileSession:SendRPC("GetDTCs",
				{ 
					dtcMask = 42,
					ecuName = 2000
				})
				
				EXPECT_HMICALL("VehicleInfo.GetDTCs")
				:Times(0)
				
				commonTestCases:DelayedExp(1000)
				
				--mobile side: expect GetDTCs response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "UNSUPPORTED_RESOURCE" })
				:Timeout(TimeoutValue)
			end
					
			-----------------------------------------------------------------------------------------
			
			--Description: This test is intended to check positive cases and when VehicleInfo.IsReady: availabe = false, and mobile requests DiagnosticMessage, SDL sends UNSUPPORTED_RESOURCE to mobile app
			function Test:DiagnosticMessage_UNSUPPORTED_RESOURCE()
			
				local cid = self.mobileSession:SendRPC("DiagnosticMessage",
				{ 
					targetID = 42,
					messageLength = 8,
					messageData = {1}
				})
				
				EXPECT_HMICALL("VehicleInfo.DiagnosticMessage")
				:Times(0)
				
				commonTestCases:DelayedExp(1000)
				
				--mobile side: expect DiagnosticMessage response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "UNSUPPORTED_RESOURCE" })
				:Timeout(TimeoutValue)
			end
					
			-----------------------------------------------------------------------------------------		

			--Description: This test is intended to check positive cases and when VehicleInfo.IsReady: availabe = false, and mobile requests SubscribeVehicleData, SDL sends UNSUPPORTED_RESOURCE to mobile app
			function Test:SubscribeVehicleData_UNSUPPORTED_RESOURCE()
			
				local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
				{ 
					airbagStatus = true
				})
				
				EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData")
				:Times(0)
				
				commonTestCases:DelayedExp(1000)
				
				--mobile side: expect SubscribeVehicleData response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "UNSUPPORTED_RESOURCE" })
				:Timeout(TimeoutValue)
			end
					
			-----------------------------------------------------------------------------------------
			
			--Description: This test is intended to check positive cases and when VehicleInfo.IsReady: availabe = false, and mobile has ready subscribed, HMI sends OnVehicleData, SDL doesn't send OnVehicleData notification to mobile app
			function Test:UNSUPPORTED_RESOURCE_OnVehicleData_Notification()
			
				--hmi side: sending VehicleInfo.OnVehicleData notification					
				self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", {airbagStatus = 
									{   driverAirbagDeployed = "NO"
									}})
				
				--mobile side: expected doesn't send OnVehicleData to mobile app
				EXPECT_NOTIFICATION("OnVehicleData", {airbagStatus = {driverAirbagDeployed = "NO"}})
				:Times(0)
				
				commonTestCases:DelayedExp(1000)
				
			end
					
			-----------------------------------------------------------------------------------------		
			
			--Description: This test is intended to check positive cases and when VehicleInfo.IsReady: availabe = false, and mobile requests UnsubscribeVehicleData, SDL sends UNSUPPORTED_RESOURCE to mobile app
			function Test:UnsubscribeVehicleData_UNSUPPORTED_RESOURCE()
				local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
				{ 
					airbagStatus = true
				})
				
				EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData")
				:Times(0)
				
				commonTestCases:DelayedExp(1000)
				
				--mobile side: expect UnsubscribeVehicleData response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "UNSUPPORTED_RESOURCE" })
				:Timeout(TimeoutValue)
				
			end
					
			-----------------------------------------------------------------------------------------
			
			--Description: This test is intended to check positive cases and when VehicleInfo.IsReady: availabe = false, and mobile requests GetVehicleData, SDL sends UNSUPPORTED_RESOURCE to mobile app
			function Test:GetVehicleData_UNSUPPORTED_RESOURCE()
			
				local cid = self.mobileSession:SendRPC("GetVehicleData",
				{ 
					airbagStatus = true
				})
				
				EXPECT_HMICALL("VehicleInfo.GetVehicleData")
				:Times(0)
				
				commonTestCases:DelayedExp(1000)
				
				--mobile side: expect GetVehicleData response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "UNSUPPORTED_RESOURCE" })
				:Timeout(TimeoutValue)
			end
					
			-----------------------------------------------------------------------------------------		
		
		end		

		----------------------------------------------------------------------------------------------
		
		-- List all resultCodes
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

		----------------------------------------------------------------------------------------------
		
		--Description: in case HMI responds at <interface>-related RPC with some erroneous -> SDL must send resultcodes from HMI to mobile app (per <interface>-related RPC)
		local function SequenceVehicleInfo_IsReady_ResultCode(resultCode1, success1)

				-- ToDo: update after resolving APPLINK-16141. (Currently, this function just only SendResponse for all resultcodes from HMI to SDL. Need to be updated after this question has been resolved.)
				--Description: ReadDID request adds the command to VehicleInfo Menu, VehicleInfo menu or to the both depending on the parameters sent (VehicleInfo commands or the both correspondingly);
				Test["ReadDID_resultCode_" .. resultCode1 .."_SendResponse"] = function(self)
					
					local cid = self.mobileSession:SendRPC("ReadDID",
					{ 
						ecuName = 2000,
						didLocation = 
						{ 
							56832
						}
					})
					
					--hmi side: expect ReadDID request
					EXPECT_HMICALL("VehicleInfo.ReadDID",{ 
						ecuName = 2000,
						didLocation = 
						{ 
							56832
						}
					})
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.ReadDID response
						self.hmiConnection:SendResponse(data.id, data.method, resultCode1, {didResult = {{data = "123", didLocation = 56832, resultCode = "SUCCESS"}}})
					end)
					
					--mobile side: expect ReadDID response
					EXPECT_RESPONSE(cid, {success = success1, resultCode = resultCode1, didResult = {{data = "123", didLocation = 56832, resultCode = "SUCCESS"}}})

				end
						
				-----------------------------------------------------------------------------------------
				--Description: GetDTCs request adds the command to VehicleInfo Menu, VehicleInfo menu or to the both depending on the parameters sent (VehicleInfo commands or the both correspondingly);			
				Test["GetDTCs_resultCode_" .. resultCode1 .."_SendResponse"] = function(self)
					
					local cid = self.mobileSession:SendRPC("GetDTCs",
					{ 
						dtcMask = 42,
						ecuName = 2000
					})
					
					--hmi side: expect GetDTCs request
					EXPECT_HMICALL("VehicleInfo.GetDTCs",
					{ 
						dtcMask = 42,
						ecuName = 2000
					})
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.GetDTCs response
						self.hmiConnection:SendResponse(data.id, data.method, resultCode1, {ecuHeader = 2, dtc = {"line 0", "line 1", "line 2"}})
					end)
					
					--mobile side: expect GetDTCs response
					EXPECT_RESPONSE(cid, {success = success1, resultCode = resultCode1, ecuHeader = 2, dtc = {"line 0", "line 1", "line 2"}})

				end
						
				-----------------------------------------------------------------------------------------
				
				--Description: This test is intended to check positive cases and when VehicleInfo.IsReady: erroneous, and mobile requests DiagnosticMessage, SDL sends resultcodes from HMI to mobile app
				Test["DiagnosticMessage_resultCode_" .. resultCode1 .."_SendResponse"] = function(self)
					
					local cid = self.mobileSession:SendRPC("DiagnosticMessage",
					{ 
						targetID = 42,
						messageLength = 8,
						messageData = {1}
					})
					
					--hmi side: expect DiagnosticMessage request
					EXPECT_HMICALL("VehicleInfo.DiagnosticMessage",
					{ 
						targetID = 42,
						messageLength = 8,
						messageData = {1}
					})
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.DiagnosticMessage response
						self.hmiConnection:SendResponse(data.id, data.method, resultCode1, {messageDataResult = {200}})
					end)
					
					--mobile side: expect DiagnosticMessage response
					EXPECT_RESPONSE(cid, {success = success1, resultCode = resultCode1})

				end
						
				-----------------------------------------------------------------------------------------		

				--Description: This test is intended to check positive cases and when VehicleInfo.IsReady: erroneous, and mobile requests SubscribeVehicleData, SDL sends resultcodes from HMI to mobile app
				Test["SubscribeVehicleData_resultCode_" .. resultCode1 .."_SendResponse"] = function(self)
					
					local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
					{ 
						airbagStatus = true
					})
					
					--hmi side: expect SubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",
					{ 
						airbagStatus = true
					})
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.SubscribeVehicleData response				
						self.hmiConnection:SendResponse( data.id, data.method, resultCode1, {airbagStatus = {dataType="VEHICLEDATA_PRNDL", resultCode="SUCCESS"}})
					end)
					
					--mobile side: expect SubscribeVehicleData response
					EXPECT_RESPONSE(cid, {success = success1, resultCode = resultCode1, airbagStatus = {dataType = "VEHICLEDATA_PRNDL", resultCode = "SUCCESS"}})

				end
						
				-----------------------------------------------------------------------------------------
				
				--Description: This test is intended to check positive cases and when VehicleInfo.IsReady: erroneous, and mobile has ready subscribed, HMI sends OnVehicleData, SDL doesn't send OnVehicleData notification to mobile app
				Test["OnVehicleData_Notification_resultCode_" .. resultCode1 .."_SendResponse"] = function(self)
					
					--hmi side: sending VehicleInfo.OnVehicleData notification					
					self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", {airbagStatus = 
										{   driverAirbagDeployed = "NO"
										}})
					
					--mobile side: expected SubscribeVehicleData response
					EXPECT_NOTIFICATION("OnVehicleData", {airbagStatus = {driverAirbagDeployed = "NO"}})
					:Times(0)
					
					commonTestCases:DelayedExp(1000)

				end
						
				-----------------------------------------------------------------------------------------		
				
				--Description: This test is intended to check positive cases and when VehicleInfo.IsReady: erroneous, and mobile requests UnsubscribeVehicleData, SDL sends resultcodes from HMI to mobile app
				Test["UnsubscribeVehicleData_resultCode_" .. resultCode1 .."_SendResponse"] = function(self)
					
					local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
					{ 
						airbagStatus = true
					})
					
					--hmi side: expect UnsubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",
					{ 
						airbagStatus = true
					})
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.UnsubscribeVehicleData response				
						self.hmiConnection:SendResponse( data.id, data.method, resultCode1, {airbagStatus = {dataType="VEHICLEDATA_PRNDL", resultCode="SUCCESS"}})
					end)
					
					--mobile side: expect UnsubscribeVehicleData response
					EXPECT_RESPONSE(cid, {success = success1, resultCode = resultCode1})

				end
						
				-----------------------------------------------------------------------------------------
				
				--Description: This test is intended to check positive cases and when VehicleInfo.IsReady: erroneous, and mobile requests GetVehicleData, SDL sends resultcodes from HMI to mobile app
				Test["GetVehicleData_resultCode_" .. resultCode1 .."_SendResponse"] = function(self)
					
					local cid = self.mobileSession:SendRPC("GetVehicleData",
					{ 
						airbagStatus = true
					})
					
					--hmi side: expect GetVehicleData request
					EXPECT_HMICALL("VehicleInfo.GetVehicleData",
					{ 
						airbagStatus = true
					})
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.GetVehicleData response				
						self.hmiConnection:SendResponse( data.id, data.method, resultCode1, {	airbagStatus=
								{
									driverAirbagDeployed = "NOT_SUPPORTED",
									driverSideAirbagDeployed = "NOT_SUPPORTED",
									driverCurtainAirbagDeployed = "NOT_SUPPORTED",
									passengerAirbagDeployed = "NOT_SUPPORTED",
									passengerCurtainAirbagDeployed = "NOT_SUPPORTED",
									driverKneeAirbagDeployed = "NOT_SUPPORTED",
									passengerSideAirbagDeployed = "NOT_SUPPORTED",
									passengerKneeAirbagDeployed = "NOT_SUPPORTED"
								}})
					end)
					
					--mobile side: expect GetVehicleData response
					EXPECT_RESPONSE(cid, {success = success1, resultCode = resultCode1})

				end
						
				-----------------------------------------------------------------------------------------
		
		end
		
		----------------------------------------------------------------------------------------------
			
		local function SequenceVehicleInfo_IsReady_ResultCodes(resultCodes)
		
			for i=1, #resultCodes do
				SequenceVehicleInfo_IsReady_ResultCode(resultCodes[i].resultCode, resultCodes[i].success)
			end
		end

		----------------------------------------------------------------------------------------------		
		
		local TestData = {
			{description = "available = false", 			method = "VehicleInfo.IsReady" , 	parameter = {available = false}, 	resultCode = "SUCCESS"}, 
			{description = "Empty method", 					method = "" , 						parameter = {available = true}, 	resultCode = "SUCCESS"},
			{description = "Empty availabe", 				method = "VehicleInfo.IsReady" , 	parameter = {available = ""}, 		resultCode = "SUCCESS"}, 
			{description = "Missing available parameter", 	method = "VehicleInfo.IsReady" , 	parameter = {available = nil}, 		resultCode = "SUCCESS"}, 
			{description = "Wrong type of method", 			method = 1234 ,						parameter = {available = true}, 	resultCode = "SUCCESS"}, 
			{description = "Wrong type of availabe", 		method = "VehicleInfo.IsReady" , 	parameter = {available = 1234}, 	resultCode = "SUCCESS"},
			{description = "Wrong type of resultcode", 		method = "VehicleInfo.IsReady" , 	parameter = {available = true}, 	resultCode = 456},
			{description = "Nonexisted resultcode", 		method = "VehicleInfo.IsReady" , 	parameter = {available = true}, 	resultCode = "Non_Exist_ResultCode"},
			{description = "HMI doen't respond", 			_, 									_, 									_, 							case = 1}, 
			{description = "Missing all parameters", 		_, 									_, 									_, 							case = 2}, 
			{description = "Missing Method parameter", 		_, 									_, 									_, 							case = 3}, 
			{description = "Missing resultcode", 			_, 									_, 									_, 							case = 4}, 					
			{description = "Invalid Json", 					_, 									_, 									_, 							case = 5}						
		}

		----------------------------------------------------------------------------------------------		
		
		--Main executing
		for i=1, #TestData do
			--Print new line to separate new test cases group
			commonFunctions:newTestCasesGroup("-----------------------II." ..tostring(i).." VehicleInfo.IsReady response [" ..TestData[i].description .. "]------------------------------")
			
			RestartSDL_InitHMI_ConnectMobile(self, "Precondition", TestData[i].description, TestData[i].method, TestData[i].parameter, TestData[i].resultCode, TestData[i].case)
			
			-- Description: Register Application For Precondition
			function Test:PreconditionRegisterApplication()
			
				--mobile side: RegisterAppInterface request
				CorIdRegister=self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
				strAppName=config.application1.registerAppInterfaceParams.appName

				--hmi side: expect BasicCommunication.OnAppRegistered request
				EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
				{
					application=
					{
						appName=strAppName
					}
				})
				:Do(function(_,data)
					self.appName=data.params.application.appName
					self.applications[strAppName]=data.params.application.appID
				end)
				
				--mobile side: expect response
				self.mobileSession:ExpectResponse(CorIdRegister, 
				{
					success=true, resultCode="SUCCESS"
				})
				:Timeout(12000)

				--mobile side: expect notification
				self.mobileSession:ExpectNotification("OnHMIStatus", 
				{ 
					systemContext="MAIN", hmiLevel="NONE", audioStreamingState="NOT_AUDIBLE"
				})
				:Timeout(12000)
		 
			end	
			
			------------------------------------------------------------------------------------------------------------

			-- Description: Activation app for precondition
			commonSteps:ActivationApp(self)

			-------------------------------------------------------------------------------------------------------------
			
			--HMI sends response with "available = false". Executing UNSUPPORTED_RESOURCE cases
			if (TestData[i].description == "available = false") then
				SequenceVehicleInfo_IsReadyFalse_UNSUPPORTED_RESOURCE()
			elseif (TestData[i].description == "HMI doen't respond") then
				--Case = 1: HMI doen't respond. Executing GENERIC_ERROR cases
				SequenceVehicleInfo_IsReady_ResultCode("GENERIC_ERROR", false)
			else
				--Executing other resultcodes
				SequenceVehicleInfo_IsReady_ResultCodes(resultCodes)
			end
		end


-- Postcondition: restoring sdl_preloaded_pt file
-- TODO: Remove after implementation policy update
-- function Test:Postcondition_restoringPreloadedfile()
--   commonSteps:RestoreFileFromAppMainFolder("sdl_preloaded_pt.json")
-- end

function Test:Postcondition_Preloadedfile()
  print ("restoring smartDeviceLink.ini")
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end