---------------------------------------------------------------------------------------------
-- Purpose: Covert a part of CRQ APPLINK-20918
-- Verify functional requirement APPLINK-20932 (single VR)
---------------------------------------------------------------------------------------------

config.defaultProtocolVersion = 2


---------------------------------------------------------------------------------------------
---------------------------- Required Shared libraries --------------------------------------
---------------------------------------------------------------------------------------------

local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')


DefaultTimeout = 3
local iTimeout = 3000
local commonPreconditions = require ('/user_modules/shared_testcases/commonPreconditions')


---------------------------------------------------------------------------------------------
------------------------- General Precondition before ATF start -----------------------------
---------------------------------------------------------------------------------------------
--make backup copy of file sdl_preloaded_pt.json
commonPreconditions:BackupFile("sdl_preloaded_pt.json")
-- TODO: Remove after implementation policy update

-- TODO: Remove after implementation policy update
-- Precondition: replace preloaded file with new one
os.execute('cp ./files/ptu_general.json ' .. tostring(config.pathToSDL) .. "sdl_preloaded_pt.json")


-- Precondition: remove policy table and log files
commonSteps:DeleteLogsFileAndPolicyTable()


---------------------------------------------------------------------------------------------
---------------------------- General Settings for configuration----------------------------
---------------------------------------------------------------------------------------------
Test = require('connecttest')

require('cardinalities')
local events = require('events')  
local mobile_session = require('mobile_session')
require('user_modules/AppTypes')


  
---------------------------------------------------------------------------------------------
-------------------------------------------Common function-----------------------------------
---------------------------------------------------------------------------------------------
--List of CRQs:
	--APPLINK-20918: [GENIVI] VR interface: SDL behavior in case HMI does not respond to IsReady_request or respond with "available" = false
		-- 1. HMI respond VR.IsReady (false) -> SDL must return 'UNSUPPORTED_RESOURCE, success:false' to all single VR-related RPC
		-- 2. HMI respond VR.IsReady (false) and app sends RPC that must be spitted -> SDL must NOT transfer VR portion of spitted RPC to HMI
		-- 3. HMI does NOT respond to VR.IsReady_request -> SDL must transfer received RPC to HMI even to non-responded VR module

--List of parameters in VR.IsReady response:
	--Parameter 1: correlationID: type=Integer, mandatory="true"
	--Parameter 2: method: type=String, mandatory="true" (method = "VR.IsReady") 
	--Parameter 3: resultCode: type=String Enumeration(Integer), mandatory="true" 
	--Parameter 4: info/message: type=String, minlength="1" maxlength="10" mandatory="false" 
	--Parameter 5: available: type=Boolean, mandatory="true"
-----------------------------------------------------------------------------------------------
--Cover APPLINK-25286: [HMI_API] VR.IsReady
function Test:initHMI_onReady_VR_IsReady(case)
    -- critical(true)
    local function ExpectRequest(name, mandatory, params)
	
	
	
      xmlReporter.AddMessage(debug.getinfo(1, "n").name, tostring(name))
      local event = events.Event()
      event.level = 2
      event.matches = function(self, data) return data.method == name end
      return
      EXPECT_HMIEVENT(event, name)
      :Times(mandatory and 1 or AnyNumber())
      :Do(function(_, data)

		--APPLINK-25286: [HMI_API] VR.IsReady
		if (name == "VR.IsReady") then
	
			--On the view of JSON message, VR.IsReady response has colerationidID, code/resultCode, method and message parameters. Below are tests to verify all invalid cases of the response.
			
			--caseID 1-3: Check special cases
				--0. availabe_false
				--1. HMI_Does_Not_Repond
				--2. MissedAllParamaters
				--3. Invalid_Json

			if (case == 0) then -- responds {availabe = false}
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {availabe = false}) 
				
			elseif (case == 1) then -- does not respond
				--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", params) 
				
			elseif (case == 2) then --MissedAllParamaters
				self.hmiConnection:Send('{}')
				
			elseif (case == 3) then --Invalid_Json
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"VR.IsReady", "code":0}}')	
				  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc";"2.0","result":{"available":true,"method":"VR.IsReady", "code":0}}')	
			
			--*****************************************************************************************************************************
			
			--caseID 11-14 are used to checking "collerationID" parameter
				--11. collerationID_IsMissed
				--12. collerationID_IsNonexistent
				--13. collerationID_IsWrongType
				--14. collerationID_IsNegative 	
				
			elseif (case == 11) then --collerationID_IsMissed
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"VR.IsReady", "code":0}}')
				  self.hmiConnection:Send('{"jsonrpc":"2.0","result":{"available":true,"method":"VR.IsReady", "code":0}}')
				  
			elseif (case == 12) then --collerationID_IsNonexistent
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"VR.IsReady", "code":0}}')
				  self.hmiConnection:Send('{"id":'..tostring(data.id + 10)..',"jsonrpc":"2.0","result":{"available":true,"method":"VR.IsReady", "code":0}}')
				  
			elseif (case == 13) then --collerationID_IsWrongType
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"VR.IsReady", "code":0}}')
				  self.hmiConnection:Send('{"id":"'..tostring(data.id)..'","jsonrpc":"2.0","result":{"available":true,"method":"VR.IsReady", "code":0}}')
				  
			elseif (case == 14) then --collerationID_IsNegative
				self.hmiConnection:Send('{"id":'..tostring(-1)..',"jsonrpc":"2.0","result":{"available":true,"method":"VR.IsReady", "code":0}}')
			
			--*****************************************************************************************************************************
			
			--caseID 21-27 are used to checking "method" parameter
				--21. method_IsMissed
				--22. method_IsNotValid
				--23. method_IsOtherResponse
				--24. method_IsEmpty
				--25. method_IsWrongType
				--26. method_IsInvalidCharacter_Newline
				--27. method_IsInvalidCharacter_OnlySpaces
				--28. method_IsInvalidCharacter_Tab
				
			elseif (case == 21) then --method_IsMissed
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"VR.IsReady", "code":0}}')
				  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"code":0}}')

			elseif (case == 22) then --method_IsNotValid
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"VR.IsReady", "code":0}}')
				 self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"VR.IsRea", "code":0}}')				

			elseif (case == 23) then --method_IsOtherResponse
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"VR.IsReady", "code":0}}')
				 self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"UI.IsReady", "code":0}}')			

			elseif (case == 24) then --method_IsEmpty
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"VR.IsReady", "code":0}}')
				 self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"", "code":0}}')							 
			
			elseif (case == 25) then --method_IsWrongType
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"VR.IsReady", "code":0}}')
				  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":123456789, "code":0}}')
			
			elseif (case == 26) then --method_IsInvalidCharacter_Newline
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"VR.IsReady", "code":0}}')
				  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"VR.IsR\neady", "code":0}}')
			
			elseif (case == 27) then --method_IsInvalidCharacter_OnlySpaces
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"VR.IsReady", "code":0}}')
				  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"  ", "code":0}}')
			
			elseif (case == 28) then --method_IsInvalidCharacter_Tab
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"VR.IsReady", "code":0}}')
				  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"VR.IsRe\tady", "code":0}}')		
				  
			--*****************************************************************************************************************************
			
			--caseID 31-35 are used to checking "resultCode" parameter
				--31. resultCode_IsMissed
				--32. resultCode_IsNotExist
				--33. resultCode_IsWrongType
				--34. resultCode_INVALID_DATA (code = 11)
				--35. resultCode_DATA_NOT_AVAILABLE (code = 9)
				--36. resultCode_GENERIC_ERROR (code = 22)
				
			elseif (case == 31) then --resultCode_IsMissed
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"VR.IsReady", "code":0}}')
				  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"VR.IsReady"}}')

			elseif (case == 32) then --resultCode_IsNotExist
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"VR.IsReady", "code":0}}')
				  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"VR.IsReady", "code":123}}')

			elseif (case == 33) then --resultCode_IsWrongType
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"VR.IsReady", "code":0}}')
				  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"VR.IsReady", "code":"0"}}')
			
			elseif (case == 34) then --resultCode_INVALID_DATA
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"VR.IsReady", "code":0}}')
				  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"VR.IsReady", "code":11}}')
			
			elseif (case == 35) then --resultCode_DATA_NOT_AVAILABLE
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"VR.IsReady", "code":0}}')
				  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"VR.IsReady", "code":9}}')
			
			elseif (case == 36) then --resultCode_GENERIC_ERROR
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"VR.IsReady", "code":0}}')
				  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"VR.IsReady", "code":22}}')
			
			
			--*****************************************************************************************************************************
			
			--caseID 41-45 are used to checking "message" parameter
				--41. message_IsMissed
				--42. message_IsLowerBound
				--43. message_IsUpperBound
				--44. message_IsOutUpperBound
				--45. message_IsEmpty_IsOutLowerBound
				--46. message_IsWrongType
				--47. message_IsInvalidCharacter_Tab
				--48. message_IsInvalidCharacter_OnlySpaces
				--49. message_IsInvalidCharacter_Newline

			elseif (case == 41) then --message_IsMissed
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"VR.IsReady"}, "message":"The data sent is invalid","code":11}}') --INVALID_DATA
				  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"VR.IsReady"},"code":11}}')
				  
			elseif (case == 42) then --message_IsLowerBound
				local messageValue = "a"
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"VR.IsReady"}, "message":"The data sent is invalid","code":11}}') --INVALID_DATA
				  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"VR.IsReady"}, "message":"' .. messageValue ..'","code":11}}')
							  
			elseif (case == 43) then --message_IsUpperBound
				local messageValue = string.rep("a", 1000)
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"VR.IsReady"}, "message":"The data sent is invalid","code":11}}') --INVALID_DATA
				  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"VR.IsReady"}, "message":"' .. messageValue ..'","code":11}}')
			
			elseif (case == 44) then --message_IsOutUpperBound
				local messageValue = string.rep("a", 1001)
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"VR.IsReady"}, "message":"The data sent is invalid","code":11}}') --INVALID_DATA
				  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"VR.IsReady"}, "message":"' .. messageValue ..'","code":11}}')

			elseif (case == 45) then --message_IsEmpty_IsOutLowerBound
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"VR.IsReady"}, "message":"The data sent is invalid","code":11}}') --INVALID_DATA
				  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"VR.IsReady"}, "message":"","code":11}}')

			elseif (case == 46) then --message_IsWrongType
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"VR.IsReady"}, "message":"The data sent is invalid","code":11}}') --INVALID_DATA
				  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"VR.IsReady"}, "message":123,"code":11}}')
				  
			elseif (case == 47) then --message_IsInvalidCharacter_Tab
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"VR.IsReady"}, "message":"The data sent is invalid","code":11}}') --INVALID_DATA
				  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"VR.IsReady"}, "message":"a\tb","code":11}}')

			elseif (case == 48) then --message_IsInvalidCharacter_OnlySpaces
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"VR.IsReady"}, "message":"The data sent is invalid","code":11}}') --INVALID_DATA
				  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"VR.IsReady"}, "message":"  ","code":11}}')

			elseif (case == 49) then --message_IsInvalidCharacter_Newline
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"VR.IsReady"}, "message":"The data sent is invalid","code":11}}') --INVALID_DATA
				  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"VR.IsReady"}, "message":"a\n\b","code":11}}')

			--*****************************************************************************************************************************

			--caseID 51-55 are used to checking "available" parameter
				--51. available_IsMissed
				--52. available_IsWrongType

			elseif (case == 51) then --available_IsMissed
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"VR.IsReady", "code":0}}')
				  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"VR.IsReady", "code":"0"}}')
	  
			elseif (case == 52) then --available_IsWrongType
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"VR.IsReady", "code":0}}')
				  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":"true","method":"VR.IsReady", "code":"0"}}')

			else
				print("***************************Error: VR.IsReady: Input value is not correct ***************************")
			end

		
		else
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", params) 			
		end

		
		
      end)
	  
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
	:Timeout(15000)
	
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
	:Timeout(15000)
	
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
        button_capability("SEEKLEFT"),
        button_capability("SEEKRIGHT"),
        button_capability("TUNEUP"),
        button_capability("TUNEDOWN")
      },
      presetBankCapabilities = { onScreenPresetsAvailable = true }
    }
    ExpectRequest("Buttons.GetCapabilities", true, buttons_capabilities)
    ExpectRequest("VR.GetCapabilities", true, { vrCapabilities = { "TEXT" } })
	:Timeout(15000)
	
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
 

local function StopStartSDL_HMI_MOBILE(case, TestCaseName)

	--Stop SDL
	Test[tostring(TestCaseName) .. "_Precondition_StopSDL"] = function(self)
		StopSDL()
	end
	
	--Start SDL
	Test[tostring(TestCaseName) .. "_Precondition_StartSDL"] = function(self)
		StartSDL(config.pathToSDL, config.ExitOnCrash)
	end
	
	--InitHMI
	Test[tostring(TestCaseName) .. "_Precondition_InitHMI"] = function(self)
		self:initHMI()
	end
	
	
	--InitHMIonReady
	Test[tostring(TestCaseName) .. "_initHMI_onReady_VR_InReady_" .. tostring(description)] = function(self)
					
		self:initHMI_onReady_VR_IsReady(case)
		
	end

	
	--ConnectMobile
	Test[tostring(TestCaseName) .. "_ConnectMobile"] = function(self)
		self:connectMobile()
	end
	
	--StartSession
	Test[tostring(TestCaseName) .. "_StartSession"] = function(self)
		self.mobileSession= mobile_session.MobileSession(self, self.mobileConnection)
		self.mobileSession:StartService(7)
	end
	
end

--ToDo: Uncomment invalid cases when APPLINK-15494 is resolved (According to answers on question APPLINK-27524).
local TestData = {

--caseID 1-3 are used to checking special cases
{caseID = 1, description = "HMI_Does_Not_Repond"},
{caseID = 2, description = "MissedAllParamaters"},
{caseID = 3, description = "Invalid_Json"},

		
--caseID 11-14 are used to checking "collerationID" parameter
	--11. IsMissed
	--12. IsNonexistent
	--13. IsWrongType
	--14. IsNegative 	
{caseID = 11, description = "collerationID_IsMissed"},
{caseID = 12, description = "collerationID_IsNonexistent"},
{caseID = 13, description = "collerationID_IsWrongType"},
{caseID = 14, description = "collerationID_IsNegative"},

--caseID 21-27 are used to checking "method" parameter
	--21. IsMissed
	--22. IsNotValid
	--23. IsOtherResponse
	--24. IsEmpty
	--25. IsWrongType
	--26. IsInvalidCharacter - \n, \t, only spaces
{caseID = 21, description = "method_IsMissed"},
{caseID = 22, description = "method_IsNotValid"},
 {caseID = 23, description = "method_IsOtherResponse"},
{caseID = 24, description = "method_IsEmpty"},
{caseID = 25, description = "method_IsWrongType"},
{caseID = 26, description = "method_IsInvalidCharacter_Splace"},
{caseID = 26, description = "method_IsInvalidCharacter_Tab"},
{caseID = 26, description = "method_IsInvalidCharacter_NewLine"},

--caseID 31-35 are used to checking "resultCode" parameter
	--31. IsMissed
	--32. IsNotExist
	--33. IsEmpty
	--34. IsWrongType
{caseID = 31,  description = "resultCode_IsMissed"},
{caseID = 32,  description = "resultCode_IsNotExist"},
{caseID = 33,  description = "resultCode_IsWrongType"},
{caseID = 34,  description = "resultCode_INVALID_DATA"},
{caseID = 35,  description = "resultCode_DATA_NOT_AVAILABLE"},
{caseID = 36,  description = "resultCode_GENERIC_ERROR"},


--caseID 41-45 are used to checking "message" parameter
	--41. IsMissed
	--42. IsLowerBound
	--43. IsUpperBound
	--44. IsOutUpperBound
	--45. IsEmpty/IsOutLowerBound
	--46. IsWrongType
	--47. IsInvalidCharacter - \n, \t, only spaces
{caseID = 41,  description = "message_IsMissed"},
{caseID = 42,  description = "message_IsLowerBound"},
{caseID = 43,  description = "message_IsUpperBound"},
{caseID = 44,  description = "message_IsOutUpperBound"},
{caseID = 45,  description = "message_IsEmpty_IsOutLowerBound"},
{caseID = 46,  description = "message_IsWrongType"},
{caseID = 47,  description = "message_IsInvalidCharacter_Tab"},
{caseID = 48,  description = "message_IsInvalidCharacter_OnlySpaces"},
{caseID = 49,  description = "message_IsInvalidCharacter_Newline"},


--caseID 51-55 are used to checking "available" parameter
	--51. IsMissed
	--52. IsWrongType
{caseID = 51,  description = "available_IsMissed"},
{caseID = 52,  description = "available_IsWrongType"},
			
}

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

--Not applicable

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK I----------------------------------------
--------------------------------Check normal cases of Mobile request---------------------------
-----------------------------------------------------------------------------------------------

-- Not applicable for VR.IsReady HMI API.



----------------------------------------------------------------------------------------------
----------------------------------------TEST BLOCK II-----------------------------------------
-----------------------------Check special cases of Mobile request----------------------------
----------------------------------------------------------------------------------------------

-- Not applicable for VR.IsReady HMI API.

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK III--------------------------------------
----------------------------------Check normal cases of HMI response---------------------------
-----------------------------------------------------------------------------------------------


	-----------------------------------------------------------------------------------------------
	--APPLINK-20932 (single VR)
	--Verification criteria:	
		-- In case SDL does NOT receive VR.IsReady_response during <DefaultTimeout> from HMI
		-- and mobile app sends any single VR-related RPC
		-- SDL must:
		-- transfer this VR-related RPC to HMI
		-- respond with <received_resultCode_from_HMI> to mobile app	
	-----------------------------------------------------------------------------------------------
	local function APPLINK_20932_single_VR_RPCs(TestCaseName, resultCodes)
		-- Structure of resultCodes parameter = {
			-- {success = true, resultCode = "SUCCESS", 			expected_resultCode = "SUCCESS"},
			-- {success = true, resultCode = "WARNINGS", 			expected_resultCode = "WARNINGS"}
		-- }


		-- 1. Add.Command
		for i = 1, #resultCodes do
			
			Test[TestCaseName .. "_AddCommand_VRCommandsOnly_".. tostring(resultCodes[i].resultCode)] = function(self)
			
				commonTestCases:DelayedExp(iTimeout)
		
				--mobile side: sending AddCommand request
				local cid = self.mobileSession:SendRPC("AddCommand",
				{
					cmdID = i,
					vrCommands = {"vrCommands_" .. tostring(i)}
				})
					
				--hmi side: expect VR.AddCommand request
				EXPECT_HMICALL("VR.AddCommand", 
				{ 
					cmdID = i,
					type = "Command",
					vrCommands = {"vrCommands_" .. tostring(i)}
				})
				:Do(function(_,data)
					--hmi side: sending response
					if (resultCodes[i].resultCode == "") then
						-- HMI does not respond					
					elseif (resultCodes[i].resultCode == "ABC") then
						self.hmiConnection:Send('{"id":'.. data.id ..',"jsonrpc":"2.0","result":{"method":"'..data.method..'","code":26}}')  -- code 26 is out of existing values [0-25] 
					else
						if resultCodes[i].success == true then 
							self.hmiConnection:SendResponse(data.id, data.method, resultCodes[i].resultCode, {})
						else
							self.hmiConnection:SendError(data.id, data.method, resultCodes[i].resultCode, "error message")
						end						
					end
					
				end)
				
				--mobile side: expect AddCommand response and OnHashChange notification
				if resultCodes[i].success == true then 
					
					EXPECT_RESPONSE(cid, { success = resultCodes[i].success , resultCode = resultCodes[i].expected_resultCode })
					
					EXPECT_NOTIFICATION("OnHashChange")
					:Timeout(iTimeout)
					
				else
					
					if resultCodes[i].resultCode == "" then  -- means HMI does not respond
						EXPECT_RESPONSE(cid, { success = resultCodes[i].success , resultCode = resultCodes[i].expected_resultCode})
						:Timeout(12000)
					else
						EXPECT_RESPONSE(cid, { success = resultCodes[i].success , resultCode = resultCodes[i].expected_resultCode, info = "error message"})					
					end
					
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
					
				end

			end
		
		end
		
		-- 2. DeleteCommand
		for i = 1, #resultCodes do

			if (resultCodes[i].success == false) then
				Test[TestCaseName .. "Precondition_AddCommand_VRCommandsOnly_".. tostring(resultCodes[i].resultCode)] = function(self)
				
					commonTestCases:DelayedExp(iTimeout)
			
					--mobile side: sending AddCommand request
					local cid = self.mobileSession:SendRPC("AddCommand",
					{
						cmdID = i,
						vrCommands = {"vrCommands_" .. tostring(i)}
					})
						
					--hmi side: expect VR.AddCommand request
					EXPECT_HMICALL("VR.AddCommand", 
					{ 
						cmdID = i,
						type = "Command",
						vrCommands = {"vrCommands_" .. tostring(i)}				
					})
					:Do(function(_,data)
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					
					--mobile side: expect AddCommand response and OnHashChange notification

					EXPECT_RESPONSE(cid, { success = true , resultCode = "SUCCESS" })
						
					EXPECT_NOTIFICATION("OnHashChange")
					:Timeout(iTimeout)

				end
			end
			
			Test[TestCaseName .. "_DeleteCommand_VRCommandsOnly_".. tostring(resultCodes[i].resultCode)] = function(self)
			
				commonTestCases:DelayedExp(iTimeout)
				
				--mobile side: sending DeleteCommand request
				local cid = self.mobileSession:SendRPC("DeleteCommand", {cmdID = i})
				
				--hmi side: expect VR.DeleteCommand request
				EXPECT_HMICALL("VR.DeleteCommand", {cmdID = commandID})
				:Do(function(_,data)
					--hmi side: sending VR.DeleteCommand response
					if (resultCodes[i].resultCode == "") then
						-- HMI does not respond		
					elseif (resultCodes[i].resultCode == "ABC") then
						self.hmiConnection:Send('{"id":'.. data.id ..',"jsonrpc":"2.0","result":{"method":"'..data.method..'","code":26}}')  -- code 26 is out of existing values [0-25] 
					else
						if resultCodes[i].success == true then 
							self.hmiConnection:SendResponse(data.id, data.method, resultCodes[i].resultCode, {})
						else
							self.hmiConnection:SendError(data.id, data.method, resultCodes[i].resultCode, "error message")
						end
					end						
				end)

				
				--mobile side: expect DeleteCommand response and OnHashChange notification
				if resultCodes[i].success == true then 
					
					EXPECT_RESPONSE(cid, { success = resultCodes[i].success , resultCode = resultCodes[i].expected_resultCode })
					
					EXPECT_NOTIFICATION("OnHashChange")
					:Timeout(iTimeout)
					
				else
					if resultCodes[i].resultCode == "" then  -- means HMI does not respond
						EXPECT_RESPONSE(cid, { success = resultCodes[i].success , resultCode = resultCodes[i].expected_resultCode})
						:Timeout(12000)
					elseif (resultCodes[i].resultCode == "ABC") then
						EXPECT_RESPONSE(cid, { success = resultCodes[i].success , resultCode = resultCodes[i].expected_resultCode, info = "Invalid message received from VR"})
					else
						EXPECT_RESPONSE(cid, { success = resultCodes[i].success , resultCode = resultCodes[i].expected_resultCode, info = "error message"})					
					end
					
						
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
				
			end		
		
		end
		

	end

	
	-- List of all resultCodes
	local Full_ResultCodes = {
		{success = true, resultCode = "SUCCESS", 			expected_resultCode = "SUCCESS"},
		{success = true, resultCode = "WARNINGS", 			expected_resultCode = "WARNINGS"},
		{success = true, resultCode = "WRONG_LANGUAGE", 		expected_resultCode = "WRONG_LANGUAGE"},
		{success = true, resultCode = "RETRY", 				expected_resultCode = "RETRY"},
		{success = true, resultCode = "SAVED", 				expected_resultCode = "SAVED"},
						
		{success = false, resultCode = "", 		expected_resultCode = "GENERIC_ERROR"}, --mean HMI does not respond
		{success = false, resultCode = "ABC", 	expected_resultCode = "GENERIC_ERROR"}, -- APPLINK-15494
		
		{success = false, resultCode = "UNSUPPORTED_REQUEST", 	expected_resultCode = "UNSUPPORTED_REQUEST"},
		{success = false, resultCode = "DISALLOWED", 			expected_resultCode = "DISALLOWED"},
		{success = false, resultCode = "USER_DISALLOWED", 		expected_resultCode = "USER_DISALLOWED"},
		{success = false, resultCode = "REJECTED", 				expected_resultCode = "REJECTED"},
		{success = false, resultCode = "ABORTED", 				expected_resultCode = "ABORTED"},
		{success = false, resultCode = "IGNORED", 				expected_resultCode = "IGNORED"},
		{success = false, resultCode = "IN_USE", 				expected_resultCode = "IN_USE"},
		{success = false, resultCode = "DATA_NOT_AVAILABLE", expected_resultCode = "VEHICLE_DATA_NOT_AVAILABLE"},
		{success = false, resultCode = "TIMED_OUT", 					expected_resultCode = "TIMED_OUT"},
		{success = false, resultCode = "INVALID_DATA", 				expected_resultCode = "INVALID_DATA"},
		{success = false, resultCode = "CHAR_LIMIT_EXCEEDED", 		expected_resultCode = "CHAR_LIMIT_EXCEEDED"},
		{success = false, resultCode = "INVALID_ID", 				expected_resultCode = "INVALID_ID"},
		{success = false, resultCode = "DUPLICATE_NAME", 			expected_resultCode = "DUPLICATE_NAME"},
		{success = false, resultCode = "APPLICATION_NOT_REGISTERED", expected_resultCode = "APPLICATION_NOT_REGISTERED"},
		{success = false, resultCode = "OUT_OF_MEMORY", 				expected_resultCode = "OUT_OF_MEMORY"},
		{success = false, resultCode = "TOO_MANY_PENDING_REQUESTS", 	expected_resultCode = "TOO_MANY_PENDING_REQUESTS"},
		{success = false, resultCode = "GENERIC_ERROR", 				expected_resultCode = "GENERIC_ERROR"},
		{success = false, resultCode = "TRUNCATED_DATA", 			expected_resultCode = "TRUNCATED_DATA"}
	}
		
	local SUCCESS_ResultCode = {
		{success = true, resultCode = "SUCCESS", expected_resultCode = "SUCCESS"}
	}		
			
	for i=1, #TestData do
				
		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Case_" .. TestData[i].caseID .. "_IsReady_" ..TestData[i].description)
		

		local TestCaseName = "Case_" .. TestData[i].caseID
		
		--ToDo: Due to problem when stop and start SDL (APPLINK-25898), script is debugged by updating user_modules/connecttest_VR_Isready.lua
		StopStartSDL_HMI_MOBILE(TestData[i].caseID, TestCaseName)
		
		commonSteps:RegisterAppInterface()

		commonSteps:ActivationApp()
		
		--Verify all resultCodes for the first case: HMI does not respond VR.IsReady. And verify only SUCCESS resultCode for other cases.
		local resultCodes
		if i ==1 then
			resultCodes = Full_ResultCodes
		else
			resultCodes = SUCCESS_ResultCode
		end

		APPLINK_20932_single_VR_RPCs(TestCaseName, resultCodes)
		
	
	end


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

-- Not applicable for VR.IsReady HMI API.


----------------------------------------------------------------------------------------------
------------------------------------------Post-condition--------------------------------------
----------------------------------------------------------------------------------------------


	function Test:Postcondition_Preloadedfile()
	  print ("restoring sdl_preloaded_pt.json")
	  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
	end

return Test
