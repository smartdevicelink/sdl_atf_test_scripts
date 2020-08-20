config.defaultProtocolVersion = 2

---------------------------------------------------------------------------------------------
---------------------------- Required Shared libraries --------------------------------------
---------------------------------------------------------------------------------------------

local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')

APIName = "TTS.IsReady"

DefaultTimeout = 3
local iTimeout = 10000
local commonPreconditions = require ('/user_modules/shared_testcases/commonPreconditions')
---------------------------------------------------------------------------------------------
------------------------- General Precondition before ATF start -----------------------------
---------------------------------------------------------------------------------------------
--make backup copy of file sdl_preloaded_pt.json
commonPreconditions:BackupFile("sdl_preloaded_pt.json")
-- TODO: Remove after implementation policy update
-- Precondition: replace preloaded file with new one
os.execute('cp ./files/ptu_general.json ' .. tostring(config.pathToSDL) .. "sdl_preloaded_pt.json")

-- Precondition for APPLINK-16307 WARNINGS, true: appID is assigned none empty appHMIType = { "NAVIGATION" }
local function update_sdl_preloaded_pt_json()
	pathToFile = config.pathToSDL .. 'sdl_preloaded_pt.json'
	local file = io.open(pathToFile, "r")
	local json_data = file:read("*all") -- may be abbreviated to "*a";
	file:close()
	
	local json = require("modules/json")
	
	local data = json.decode(json_data)
	for k,v in pairs(data.policy_table.functional_groupings) do
		if (data.policy_table.functional_groupings[k].rpcs == nil) then
			--do
			data.policy_table.functional_groupings[k] = nil
		else
			--do
			local count = 0
			for _ in pairs(data.policy_table.functional_groupings[k].rpcs) do count = count + 1 end
			if (count < 30) then
				--do
				data.policy_table.functional_groupings[k] = nil
			end
		end
	end
	data.policy_table.functional_groupings["Base-4"]["rpcs"]["Speak"] = {}
	data.policy_table.functional_groupings["Base-4"]["rpcs"]["Speak"]["hmi_levels"] = {"BACKGROUND", "FULL","LIMITED"} 
	data.policy_table.functional_groupings["Base-4"]["rpcs"]["ChangeRegistration"] = {}
	data.policy_table.functional_groupings["Base-4"]["rpcs"]["ChangeRegistration"]["hmi_levels"] = {"BACKGROUND", "FULL","LIMITED"}
	data.policy_table.functional_groupings["Base-4"]["rpcs"]["SetGlobalProperties"] = {}
	data.policy_table.functional_groupings["Base-4"]["rpcs"]["SetGlobalProperties"]["hmi_levels"] = {"BACKGROUND", "FULL","LIMITED"}
	data.policy_table.functional_groupings["Base-4"]["rpcs"]["AlertManeuver"] = {}
	data.policy_table.functional_groupings["Base-4"]["rpcs"]["AlertManeuver"]["hmi_levels"] = {"BACKGROUND", "FULL","LIMITED"}
	data.policy_table.app_policies["0000001"].AppHMIType = {"NAVIGATION"}
	data = json.encode(data)
	file = io.open(pathToFile, "w")
	file:write(data)
	file:close()
end
update_sdl_preloaded_pt_json()

-- Precondition: remove policy table and log files
commonSteps:DeleteLogsFileAndPolicyTable()


---------------------------------------------------------------------------------------------
---------------------------- General Settings for configuration----------------------------
---------------------------------------------------------------------------------------------
Test = require('user_modules/connecttest_TTS_Isready')
require('cardinalities')
local events = require('events') 
local mobile_session = require('mobile_session')
require('user_modules/AppTypes')



---------------------------------------------------------------------------------------------
-------------------------------------------Common function-----------------------------------
---------------------------------------------------------------------------------------------
function Check_menuIconParams(data, type_icon, value)
	
	
	if( (value == nil) or (#value == 0) ) then value = "action.png" end
	if(type_icon == nil) then type_icon = "DYNAMIC" end
	
	local result = true
	local path = "bin/storage/"..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"
	local value_Icon = value--"action.png"
	
	if (type_icon == "DYNAMIC") then
		value_Icon = path .. value--"action.png"
	end
	
	
	
	--if (data.params.menuIcon.imageType ~= "DYNAMIC") then
	if (data.params.menuIcon.imageType ~= type_icon) then
		print("\27[31m imageType of menuIcon is WRONG. Expected: ".. type_icon.."; Real: " .. data.params.menuIcon.imageType .. "\27[0m")
		result = false
	end
	
	if(string.find(data.params.menuIcon.value, value_Icon) ) then
		
	else
		print("\27[31m value of menuIcon is WRONG. Expected: ~/".. value_Icon .. "; Real: " .. data.params.menuIcon.value .. "\27[0m")
		result = false
	end
	
	return result
end
function DelayedExp()
	local event = events.Event()
	event.matches = function(self, e) return self == e end
	EXPECT_EVENT(event, "Delayed event")
	RUN_AFTER(function()
		RAISE_EVENT(event, event)
	end, 2000)
end

--Cover APPLINK-25117: [HMI_API] TTS.IsReady
function Test:initHMI_onReady_TTS_IsReady(case)
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
			--APPLINK-25117: [HMI_API] TTS.IsReady
			if (name == "TTS.IsReady") then
				
				--On the view of JSON message, TTS.IsReady response has colerationidID, code/resultCode, method and message parameters. Below are tests to verify all invalid cases of the response.
				
				--caseID 1-3: Check special cases
				--0. available_false
				--1. HMI_Does_Not_Repond
				--2. MissedAllParamaters
				--3. Invalid_Json
				if (case == 1) then -- does not respond
					--	self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", params) 
				elseif (case == 2) then --MissedAllParamaters
					self.hmiConnection:Send('{}')
				elseif (case == 3) then --Invalid_Json
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"TTS.IsReady", "code":0}}')	
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc";"2.0","result":{"available":true,"method":"TTS.IsReady", "code":0}}')	
					
					--*****************************************************************************************************************************
					
					--caseID 11-14 are used to checking "collerationID" parameter
					--11. collerationID_IsMissed
					--12. collerationID_IsNonexistent
					--13. collerationID_IsWrongType
					--14. collerationID_IsNegative 	
					
				elseif (case == 11) then --collerationID_IsMissed
					
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"TTS.IsReady", "code":0}}')
					self.hmiConnection:Send('{"jsonrpc":"2.0","result":{"available":true,"method":"TTS.IsReady", "code":0}}')
					
				elseif (case == 12) then --collerationID_IsNonexistent
					
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"TTS.IsReady", "code":0}}')
					self.hmiConnection:Send('{"id":'..tostring(data.id + 10)..',"jsonrpc":"2.0","result":{"available":true,"method":"TTS.IsReady", "code":0}}')
					
				elseif (case == 13) then --collerationID_IsWrongType
					
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"TTS.IsReady", "code":0}}')
					self.hmiConnection:Send('{"id":"'..tostring(data.id)..'","jsonrpc":"2.0","result":{"available":true,"method":"TTS.IsReady", "code":0}}')
					
				elseif (case == 14) then --collerationID_IsNegative
					
					self.hmiConnection:Send('{"id":'..tostring(-1)..',"jsonrpc":"2.0","result":{"available":true,"method":"TTS.IsReady", "code":0}}')
					
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
					
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"TTS.IsReady", "code":0}}')
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"code":0}}')
					
				elseif (case == 22) then --method_IsNotValid
					
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"TTS.IsReady", "code":0}}')
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"TTS.IsRea", "code":0}}')				
					
				elseif (case == 23) then --method_IsOtherResponse
					
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"TTS.IsReady", "code":0}}')
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"VR.IsReady", "code":0}}')			
					
				elseif (case == 24) then --method_IsEmpty
					
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"TTS.IsReady", "code":0}}')
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"", "code":0}}')							 
					
				elseif (case == 25) then --method_IsWrongType
					
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"TTS.IsReady", "code":0}}')
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":123456789, "code":0}}')
					
				elseif (case == 26) then --method_IsInvalidCharacter_Newline
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"TTS.IsReady", "code":0}}')
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"TTS.IsR\neady", "code":0}}')
					
				elseif (case == 27) then --method_IsInvalidCharacter_OnlySpaces
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"TTS.IsReady", "code":0}}')
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":" ", "code":0}}')
					
				elseif (case == 28) then --method_IsInvalidCharacter_Tab
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"TTS.IsReady", "code":0}}')
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"TTS.IsRe\tady", "code":0}}')		
					
					--*****************************************************************************************************************************
					
					--caseID 31-35 are used to checking "resultCode" parameter
					--31. resultCode_IsMissed
					--32. resultCode_IsNotExist
					--33. resultCode_IsWrongType
					--34. resultCode_INVALID_DATA (code = 11)
					--35. resultCode_DATA_NOT_AVAILABLE (code = 9)
					--36. resultCode_GENERIC_ERROR (code = 22)
					
				elseif (case == 31) then --resultCode_IsMissed
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"TTS.IsReady", "code":0}}')
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"TTS.IsReady"}}')
					
				elseif (case == 32) then --resultCode_IsNotExist
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"TTS.IsReady", "code":0}}')
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"TTS.IsReady", "code":123}}')
					
				elseif (case == 33) then --resultCode_IsWrongType
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"TTS.IsReady", "code":0}}')
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"TTS.IsReady", "code":"0"}}')
					
				elseif (case == 34) then --resultCode_INVALID_DATA
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"TTS.IsReady", "code":0}}')
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"TTS.IsReady", "code":11}}')
					
				elseif (case == 35) then --resultCode_DATA_NOT_AVAILABLE
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"TTS.IsReady", "code":0}}')
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"TTS.IsReady", "code":9}}')
					
				elseif (case == 36) then --resultCode_GENERIC_ERROR
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"TTS.IsReady", "code":0}}')
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"TTS.IsReady", "code":22}}')
					
					
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
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"TTS.IsReady"}, "message":"The data sent is invalid","code":11}}') --INVALID_DATA
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"TTS.IsReady"}, "code":11}}')
					
				elseif (case == 42) then --message_IsLowerBound
					local messageValue = "a"
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"TTS.IsReady"}, "message":"The data sent is invalid","code":11}}') --INVALID_DATA
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"TTS.IsReady"}, "message":"' .. messageValue ..'","code":11}}')
					
				elseif (case == 43) then --message_IsUpperBound
					local messageValue = string.rep("a", 1000)
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"TTS.IsReady"}, "message":"The data sent is invalid","code":11}}') --INVALID_DATA
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"TTS.IsReady"}, "message":"' .. messageValue ..'","code":11}}')
					
				elseif (case == 44) then --message_IsOutUpperBound
					local messageValue = string.rep("a", 1001)
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"TTS.IsReady"}, "message":"The data sent is invalid","code":11}}') --INVALID_DATA
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"TTS.IsReady"}, "message":"' .. messageValue ..'","code":11}}')
					
				elseif (case == 45) then --message_IsEmpty_IsOutLowerBound
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"TTS.IsReady"}, "message":"The data sent is invalid","code":11}}') --INVALID_DATA
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"TTS.IsReady"}, "message":"","code":11}}')
					
				elseif (case == 46) then --message_IsWrongType
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"TTS.IsReady"}, "message":"The data sent is invalid","code":11}}') --INVALID_DATA
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"TTS.IsReady"}, "message":123,"code":11}}')
					
				elseif (case == 47) then --message_IsInvalidCharacter_Tab
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"TTS.IsReady"}, "message":"The data sent is invalid","code":11}}') --INVALID_DATA
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"TTS.IsReady"}, "message":"a\tb","code":11}}')
					
				elseif (case == 48) then --message_IsInvalidCharacter_OnlySpaces
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"TTS.IsReady"}, "message":"The data sent is invalid","code":11}}') --INVALID_DATA
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"TTS.IsReady"}, "message":" ","code":11}}')
					
				elseif (case == 49) then --message_IsInvalidCharacter_Newline
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"TTS.IsReady"}, "message":"The data sent is invalid","code":11}}') --INVALID_DATA
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"TTS.IsReady"}, "message":"a\n\b","code":11}}')
					
					--*****************************************************************************************************************************
					
					-- caseID 51-55 are used to checking "available" parameter
					-- 51. available_IsMissed
					-- 52. available_IsWrongType
					
				elseif (case == 51) then --available_IsMissed
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"TTS.IsReady", "code":0}}')
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"TTS.IsReady", "code":"0"}}')
					
				elseif (case == 52) then --available_IsWrongType
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"TTS.IsReady", "code":0}}')
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":"true","method":"TTS.IsReady", "code":"0"}}')
					
				else
					print("***************************Error: TTS.IsReady: Input value is not correct ***************************")
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
	
	ExpectRequest("TTS.GetLanguage", true, { language = "EN-US" })
	:Times(0)
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
	:Times(0)
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
	local speech_capabilities = {"TEXT", "SAPI_PHONEMES", "LHPLUS_PHONEMES", "PRE_RECORDED", "SILENCE", "FILE"}
	ExpectRequest("Buttons.GetCapabilities", true, buttons_capabilities)
	ExpectRequest("VR.GetCapabilities", true, { vrCapabilities = { "TEXT" } })
	ExpectRequest("TTS.GetCapabilities", true, speech_capabilities)
	:Times(0)
	
	ExpectRequest("TTS.GetCapabilities", true, {
		speechCapabilities = { "TEXT", "SAPI_PHONEMES", "LHPLUS_PHONEMES", "PRE_RECORDED", "SILENCE", "FILE" },
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

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

--Not applicable

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK I----------------------------------------
--------------------------------Check normal cases of Mobile request---------------------------
-----------------------------------------------------------------------------------------------

-- Not applicable for TTS.IsReady HMI API.



----------------------------------------------------------------------------------------------
----------------------------------------TEST BLOCK II-----------------------------------------
-----------------------------Check special cases of Mobile request----------------------------
----------------------------------------------------------------------------------------------

-- Not applicable for TTS.IsReady HMI API.

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK III--------------------------------------
----------------------------------Check normal cases of HMI response---------------------------
-----------------------------------------------------------------------------------------------

--List of CRQs:
--APPLINK-25117: [GENIVI] TTS interface: SDL behavior in case HMI does not respond to IsReady_request or respond with "available" = false
-- 1. HMI respond TTS.IsReady (false) -> SDL must return 'UNSUPPORTED_RESOURCE, success:false' to all single TTS-related RPC
-- 2. HMI respond TTS.IsReady (false) and app sends RPC that must be spitted -> SDL must NOT transfer TTS portion of spitted RPC to HMI
-- 3. HMI does NOT respond to TTS.IsReady_request -> SDL must transfer received RPC to HMI even to non-responded TTS module

--List of parameters in TTS.IsReady response:
--Parameter 1: correlationID: type=Integer, mandatory="true"
--Parameter 2: method: type=String, mandatory="true" (method = "TTS.IsReady") 
--Parameter 3: resultCode: type=String Enumeration(Integer), mandatory="true" 
--Parameter 4: info/message: type=String, minlength="1" maxlength="1000" mandatory="false" 
--Parameter 5: available: type=Boolean, mandatory="true"
-----------------------------------------------------------------------------------------------
-- Cases 2: HMI does not sends TTS.IsReady response or send invalid response
-----------------------------------------------------------------------------------------------

--List of CRQs:	
--CRQ #1: APPLINK-25064: [RegisterAppInterface] SDL behavior in case HMI does NOT respond to IsReady request
--CRQ #2: APPLINK-25131: [TTS Interface] SDL behavior in case HMI does not respond to TTS.IsReady_request (any single TTS-related RPC)
--CRQ #3: APPLINK-26092, APPLINK-25139: [TTS Interface] HMI does NOT respond to IsReady and mobile app sends RPC that must be split

-----------------------------------------------------------------------------------------------
--Requirement ID: APPLINK-25139, APPLINK-27365 
--3.2.2: TTS responds UNSUPPORTED_RESOURCE or SUCCESS code
--3.2.2: Other interfaces respond unsuccessful resultCodes

local function APPLINK_25139_checksplit_TTS_RPCs_TTS_Responds_SUCCESS_Or_UNSUPPORTED_RESOURCE_Others_respond_unsuccess_resultCodes(TestCaseName)
	-- List of erroneous resultCodes (success:false)
	local TestData = {
		
		{resultCode = "UNSUPPORTED_REQUEST"			},
		{resultCode = "DISALLOWED" 				},
		{resultCode = "USER_DISALLOWED" 			},
		{resultCode = "REJECTED" 					},
		{resultCode = "ABORTED" 					},
		{resultCode = "IGNORED" 					},
		{resultCode = "IN_USE" 					},
		{resultCode = "VEHICLE_DATA_NOT_AVAILABLE" },
		{resultCode = "TIMED_OUT" 					},
		{resultCode = "INVALID_DATA" 				},
		{resultCode = "CHAR_LIMIT_EXCEEDED" 		},
		{resultCode = "INVALID_ID" 				},
		{resultCode = "DUPLICATE_NAME" 			},
		{resultCode = "APPLICATION_NOT_REGISTERED" },
		{resultCode = "OUT_OF_MEMORY"			},
		{resultCode = "TOO_MANY_PENDING_REQUESTS" 	},
		{resultCode = "GENERIC_ERROR" 				},
		{resultCode = "TRUNCATED_DATA"	},
		{resultCode = "UNSUPPORTED_RESOURCE" 		}
	}
	
	local ResultCode_FromTTS = {
		{resultCode = "UNSUPPORTED_RESOURCE"		},
		{resultCode = "SUCCESS" 					},
		{resultCode = "WARNINGS" 					},
		{resultCode = "WRONG_LANGUAGE" 			},
		{resultCode = "RETRY"			},
		{resultCode = "SAVED" 						}
	}
	--1. ChangeRegistration
	for i = 1, #TestData do
		for j = 1, #ResultCode_FromTTS do
			Test[TestCaseName .. "_ChangeRegistration_TTS_responds_" ..ResultCode_FromTTS[j].resultCode.."_Others_responds"..TestData[i].resultCode] = function(self)
				commonTestCases:DelayedExp(iTimeout)
				
				local request = {	language ="EN-US",
					hmiDisplayLanguage ="EN-US",
					appName ="SyncProxyTester_" .. tostring(i),
					ttsName = {{text ="SyncProxyTester", type ="TEXT"}},
					ngnMediaScreenAppName ="SPT",
				vrSynonyms = {"VRSyncProxyTester"}}
				
				--mobile side: send ChangeRegistration request
				local cid = self.mobileSession:SendRPC("ChangeRegistration", request)
				--hmi side: expect UI.ChangeRegistration request
				EXPECT_HMICALL("UI.ChangeRegistration",
				{
					appName = request.appName,
					language = request.hmiDisplayLanguage,
					ngnMediaScreenAppName = request.ngnMediaScreenAppName
				})
				:Do(function(_,data)
					--hmi side: send UI.ChangeRegistration response
					self.hmiConnection:SendError(data.id, data.method, TestData[i].resultCode, "error message")
					
				end)
				--hmi side: expect VR.ChangeRegistration request
				EXPECT_HMICALL("VR.ChangeRegistration",
				{
					language = request.language, vrSynonyms = request.vrSynonyms
				})
				:Do(function(_,data)
					--hmi side: send VR.ChangeRegistration response
					self.hmiConnection:SendError(data.id, data.method, "UNSUPPORTED_RESOURCE", {})		
				end)
				
				--hmi side: expect TTS.ChangeRegistration request
				EXPECT_HMICALL("TTS.ChangeRegistration",
				{
					language = request.language,
					ttsName = request.ttsName
				})
				:Do(function(_,data)
					--hmi side: send TTS.ChangeRegistration response
					self.hmiConnection:SendResponse(data.id, data.method, ResultCode_FromTTS[j].resultCode,{})
				end)
				--mobile side: expect response
				EXPECT_RESPONSE(cid, {success = false, resultCode = TestData[i].resultCode, info = "error message"})
			end
		end
	end
	--2. SetGlobalProperties
	for i = 1, #TestData do
		for j = 1, #ResultCode_FromTTS do
			Test[TestCaseName .. "_SetGlobalProperties_TTS_responds_"..ResultCode_FromTTS[j].resultCode.."_UI_responds_" .. TestData[i].resultCode] = function(self)
				
				commonTestCases:DelayedExp(iTimeout)		
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
							image = 
							{
								value = "action.png",
								imageType = "DYNAMIC"
							},
							text = "VR help item"
						}
					},
					menuIcon = 
					{
						value = "action.png",
						imageType = "DYNAMIC"
					},
					helpPrompt = 
					{
						{
							text = "Help prompt",
							type = "TEXT"
						}
					},
					vrHelpTitle = "VR help title",
					keyboardProperties = 
					{
						keyboardLayout = "QWERTY",
						keypressMode = "SINGLE_KEYPRESS",
						limitedCharacterList = 
						{
							"a"
						},
						language = "EN-US",
						autoCompleteText = "Daemon, Freedom"
					}
				})
				
				
				--hmi side: expect TTS.SetGlobalProperties request
				EXPECT_HMICALL("TTS.SetGlobalProperties", {
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
							image = 
							{
								value = "action.png",
								imageType = "DYNAMIC"
							},
							text = "VR help item"
						}
					},
					menuIcon = 
					{
						value = "action.png",
						imageType = "DYNAMIC"
					},
					helpPrompt = 
					{
						{
							text = "Help prompt",
							type = "TEXT"
						}
					},
					vrHelpTitle = "VR help title",
					keyboardProperties = 
					{
						keyboardLayout = "QWERTY",
						keypressMode = "SINGLE_KEYPRESS",
						limitedCharacterList = 
						{
							"a"
						},
						language = "EN-US",
						autoCompleteText = "Daemon, Freedom"
				}}
				)
				:Do(function(_,data)
					--hmi side: sending TTS.SetGlobalProperties response
					self.hmiConnection:SendResponse(data.id, data.method, ResultCode_FromTTS[j].resultCode, {})
				end)
				
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
					vrHelpTitle = "VR help title",
					keyboardProperties = 
					{
						keyboardLayout = "QWERTY",
						keypressMode = "SINGLE_KEYPRESS",
						language = "EN-US",
						autoCompleteText = "Daemon, Freedom"
					}
				})
				:ValidIf(function(_,data)
					return Check_menuIconParams(data)
				end)
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetGlobalProperties response
					self.hmiConnection:SendError(data.id, data.method, TestData[i].resultCode, "error message")
				end)
				
				--mobile side: expect SetGlobalProperties response
				EXPECT_RESPONSE(cid, {success = false, TestData[i].resultCode, info = "error message"})
				
				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
			end
		end
	end
	--3. AlertManeuver
	for i = 1, #TestData do
		for j = 1, #ResultCode_FromTTS do
			Test[TestCaseName .. "_AlertManeuver_TTS_responds_"..ResultCode_FromTTS[j].resultCode.."_UI_responds_" .. TestData[i].resultCode] = function(self)
				
				--mobile side: AlertManeuver request 
				local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
				{
					
					ttsChunks = 
					{ 
						
						{ 
							text ="FirstAlert",
							type ="TEXT"
						}, 
						
						{ 
							text ="SecondAlert",
							type ="TEXT"
						}, 
					}
					
				})
				local AlertId
				--hmi side: Navigation.AlertManeuver request 
				EXPECT_HMICALL("Navigation.AlertManeuver", 
				{
					appID = self.applications[ config.application1.registerAppInterfaceParams.appName]
				})
				:Do(function(_,data)
					AlertId = data.id
					local function alertResponse()
						self.hmiConnection:SendError(data.id, data.method, TestData[i].resultCode, "error message")
					end
					
					RUN_AFTER(alertResponse, 2000)
				end)
				
				local SpeakId
				--hmi side: TTS.Speak request 
				EXPECT_HMICALL("TTS.Speak",{	
					speakType = "ALERT_MANEUVER",
					ttsChunks = 
					{ 
						
						{ 
							text ="FirstAlert",
							type ="TEXT",
						}, 
						
						{ 
							text ="SecondAlert",
							type ="TEXT",
						}
					}
					
				})
				:Do(function(_,data)
					self.hmiConnection:SendResponse(data.id, data.method, ResultCode_FromTTS[j].resultCode, {})
				end)
				--mobile side: expect response
				EXPECT_RESPONSE(CorIdAlertM, {success = false, TestData[i].resultCode, info = "error message"})
				
				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
			end	
		end
	end
end				
local function APPLINK_25139_checksplit_TTS_RPCs_TTS_Responds_ERROR_Others_respond_SUCCESS_resultCodes(TestCaseName)
	-- List of erroneous resultCodes (success:false)
	local ResultCode_FromTTS = {
		
		{resultCode = "UNSUPPORTED_REQUEST"			},
		{resultCode = "DISALLOWED", 				},
		{resultCode = "USER_DISALLOWED", 			},
		{resultCode = "REJECTED", 					},
		{resultCode = "ABORTED", 					},
		{resultCode = "IGNORED", 					},
		{resultCode = "IN_USE", 					},
		{resultCode = "VEHICLE_DATA_NOT_AVAILABLE", },
		{resultCode = "TIMED_OUT", 					},
		{resultCode = "INVALID_DATA", 				},
		{resultCode = "CHAR_LIMIT_EXCEEDED", 		},
		{resultCode = "INVALID_ID", 				},
		{resultCode = "DUPLICATE_NAME", 			},
		{resultCode = "APPLICATION_NOT_REGISTERED", },
		{resultCode = "OUT_OF_MEMORY", 				},
		{resultCode = "TOO_MANY_PENDING_REQUESTS", 	},
		{resultCode = "GENERIC_ERROR", 				},
		{resultCode = "TRUNCATED_DATA", 			},
		{resultCode = "UNSUPPORTED_RESOURCE", 		}
	}
	
	local TestData_FromOtherInterface = {
		{resultCode = "UNSUPPORTED_RESOURCE"		},
		{resultCode = "SUCCESS", 					},
		{resultCode = "WARNINGS", 					},
		{resultCode = "WRONG_LANGUAGE", 			},
		{resultCode = "RETRY", 						},
		{resultCode = "SAVED", 						}
		
	}
	--1. ChangeRegistration
	for i = 1, #ResultCode_FromTTS do
		for j = 1, #TestData_FromOtherInterface do
			Test["ChangeRegistration"..TestCaseName .. "Others_respond_"..TestData_FromOtherInterface[j].resultCode .."_TTS_responds_" .. ResultCode_FromTTS[i].resultCode] = function(self)
				
				commonTestCases:DelayedExp(iTimeout)
				
				local request = {	language ="EN-US",
					hmiDisplayLanguage ="EN-US",
					appName ="SyncProxyTester_" .. tostring(i),
					ttsName = {{text ="SyncProxyTester", type ="TEXT"}},
					ngnMediaScreenAppName ="SPT",
				vrSynonyms = {"VRSyncProxyTester"}}
				
				--mobile side: send ChangeRegistration request
				local cid = self.mobileSession:SendRPC("ChangeRegistration", request)
				
				--hmi side: expect UI.ChangeRegistration request
				EXPECT_HMICALL("UI.ChangeRegistration",
				{
					appName = request.appName,
					language = request.hmiDisplayLanguage,
					ngnMediaScreenAppName = request.ngnMediaScreenAppName
				})
				:Do(function(_,data)
					--hmi side: send UI.ChangeRegistration response
					self.hmiConnection:SendResponse(data.id, data.method, TestData_FromOtherInterface[j].resultCode, {})
					
				end)
				--hmi side: expect VR.ChangeRegistration request
				EXPECT_HMICALL("VR.ChangeRegistration",
				{
					language = request.language, vrSynonyms = request.vrSynonyms
				})
				:Do(function(_,data)
					--hmi side: send VR.ChangeRegistration response
					self.hmiConnection:SendError(data.id, data.method, TestData_FromOtherInterface[j].resultCode, {})		
				end)
				--hmi side: expect TTS.ChangeRegistration request
				EXPECT_HMICALL("TTS.ChangeRegistration",
				{
					language = request.language,
					ttsName = request.ttsName
				})
				:Do(function(_,data)
					--hmi side: send TTS.ChangeRegistration response
					self.hmiConnection:SendError(data.id, data.method, ResultCode_FromTTS[i].resultCode, "error message")
				end)
				
				--mobile side: expect response
				EXPECT_RESPONSE(cid, {success = false, resultCode = ResultCode_FromTTS[i].resultCode, info="error message"})
				
			end
		end
	end
	--2. SetGlobalProperties
	for i = 1, #ResultCode_FromTTS do
		for j = 1, #TestData_FromOtherInterface do
			Test["SetGlobalProperties" .. TestCaseName.. "Others_respond_" .. TestData_FromOtherInterface[j].resultCode .."_TTS_responds_"..ResultCode_FromTTS[i].resultCode] = function(self)
				commonTestCases:DelayedExp(iTimeout)		
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
							image = 
							{
								value = "action.png",
								imageType = "DYNAMIC"
							},
							text = "VR help item"
						}
					},
					menuIcon = 
					{
						value = "action.png",
						imageType = "DYNAMIC"
					},
					helpPrompt = 
					{
						{
							text = "Help prompt",
							type = "TEXT"
						}
					},
					vrHelpTitle = "VR help title",
					keyboardProperties = 
					{
						keyboardLayout = "QWERTY",
						keypressMode = "SINGLE_KEYPRESS",
						limitedCharacterList = 
						{
							"a"
						},
						language = "EN-US",
						autoCompleteText = "Daemon, Freedom"
					}
				})
				
				
				--hmi side: expect TTS.SetGlobalProperties request
				EXPECT_HMICALL("TTS.SetGlobalProperties", {
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
							image = 
							{
								value = "action.png",
								imageType = "DYNAMIC"
							},
							text = "VR help item"
						}
					},
					menuIcon = 
					{
						value = "action.png",
						imageType = "DYNAMIC"
					},
					helpPrompt = 
					{
						{
							text = "Help prompt",
							type = "TEXT"
						}
					},
					vrHelpTitle = "VR help title",
					keyboardProperties = 
					{
						keyboardLayout = "QWERTY",
						keypressMode = "SINGLE_KEYPRESS",
						limitedCharacterList = 
						{
							"a"
						},
						language = "EN-US",
						autoCompleteText = "Daemon, Freedom"
				}}
				)
				:Do(function(_,data)
					--hmi side: sending TTS.SetGlobalProperties response
					self.hmiConnection:SendError(data.id, data.method, ResultCode_FromTTS[i].resultCode, "error message")
				end)
				
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
					vrHelpTitle = "VR help title",
					keyboardProperties = 
					{
						keyboardLayout = "QWERTY",
						keypressMode = "SINGLE_KEYPRESS",
						language = "EN-US",
						autoCompleteText = "Daemon, Freedom"
					}
				})
				:ValidIf(function(_,data)
					return Check_menuIconParams(data)
				end)
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetGlobalProperties response
					self.hmiConnection:SendResponse(data.id, data.method, TestData_FromOtherInterface[j].resultCode, {})
				end)
				
				--mobile side: expect SetGlobalProperties response
				EXPECT_RESPONSE(cid, {success = false, ResultCode_FromTTS[i].resultCode, info ="error_message"})
			end
		end
	end
	--3. AlertManeuver
	for i = 1, #ResultCode_FromTTS do
		for j = 1, #TestData_FromOtherInterface do
			Test["AlertManeuver"..TestCaseName .. "Others_respond_"..TestData_FromOtherInterface[j].resultCode .."_TTS_responds_" .. ResultCode_FromTTS[i].resultCode] = function(self)
				--mobile side: AlertManeuver request 
				local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
				{
					
					ttsChunks = 
					{ 
						
						{ 
							text ="FirstAlert",
							type ="TEXT",
						}, 
						
						{ 
							text ="SecondAlert",
							type ="TEXT",
						}, 
					}
					
				})
				local AlertId
				--hmi side: Navigation.AlertManeuver request 
				EXPECT_HMICALL("Navigation.AlertManeuver", 
				{
					appID = self.applications[ config.application1.registerAppInterfaceParams.appName]
				})
				:Do(function(_,data)
					AlertId = data.id
					local function alertResponse()
						self.hmiConnection:SendResponse(data.id, data.method, TestData_FromOtherInterface[j].resultCode, {})
					end
					
					RUN_AFTER(alertResponse, 2000)
				end)
				
				local SpeakId
				--hmi side: TTS.Speak request 
				EXPECT_HMICALL("TTS.Speak",{	
					speakType = "ALERT_MANEUVER",
					ttsChunks = 
					{ 
						
						{ 
							text ="FirstAlert",
							type ="TEXT",
						}, 
						
						{ 
							text ="SecondAlert",
							type ="TEXT",
						}
					}
					
				})
				:Do(function(_,data)
					self.hmiConnection:SendError(data.id, data.method, ResultCode_FromTTS[i].resultCode, "error message")
				end)
				--mobile side: expect response
				EXPECT_RESPONSE(CorIdAlertM, {success = false, ResultCode_FromTTS[i].resultCode, info = "error message"})
				
			end	
		end	
	end	
end

local TestData = {
	
	--caseID 1-3 are used to checking special cases
	{caseID = 1, description = "HMI_Does_Not_Repond"},
	-- {caseID = 2, description = "MissedAllParamaters"},
	-- {caseID = 3, description = "Invalid_Json"},
	
	
	--caseID 11-14 are used to checking "collerationID" parameter
	--11. IsMissed
	--12. IsNonexistent
	--13. IsWrongType
	--14. IsNegative 	
	-- {caseID = 11, description = "collerationID_IsMissed"},
	-- {caseID = 12, description = "collerationID_IsNonexistent"},
	-- {caseID = 13, description = "collerationID_IsWrongType"},
	-- {caseID = 14, description = "collerationID_IsNegative"},
	
	--caseID 21-27 are used to checking "method" parameter
	--21. IsMissed
	--22. IsNotValid
	--23. IsOtherResponse
	--24. IsEmpty
	--25. IsWrongType
	--26. IsInvalidCharacter - \n, \t, only spaces
	-- {caseID = 21, description = "method_IsMissed"},
	-- {caseID = 22, description = "method_IsNotValid"},
	-- {caseID = 23, description = "method_IsOtherResponse"},
	-- {caseID = 24, description = "method_IsEmpty"},
	-- {caseID = 25, description = "method_IsWrongType"},
	-- {caseID = 26, description = "method_IsInvalidCharacter_Splace"},
	-- {caseID = 26, description = "method_IsInvalidCharacter_Tab"},
	-- {caseID = 26, description = "method_IsInvalidCharacter_NewLine"},
	
	-- --caseID 31-35 are used to checking "resultCode" parameter
	-- --31. IsMissed
	-- --32. IsNotExist
	-- --33. IsEmpty
	-- --34. IsWrongType
	-- {caseID = 31, description = "resultCode_IsMissed"},
	-- {caseID = 32, description = "resultCode_IsNotExist"},
	-- {caseID = 33, description = "resultCode_IsWrongType"},
	-- {caseID = 34, description = "resultCode_INVALID_DATA"},
	-- {caseID = 35, description = "resultCode_DATA_NOT_AVAILABLE"},
	-- {caseID = 36, description = "resultCode_GENERIC_ERROR"},
	
	
	--caseID 41-45 are used to checking "message" parameter
	--41. IsMissed
	--42. IsLowerBound
	--43. IsUpperBound
	--44. IsOutUpperBound
	--45. IsEmpty/IsOutLowerBound
	--46. IsWrongType
	--47. IsInvalidCharacter - \n, \t, only spaces
	-- {caseID = 41, description = "message_IsMissed"},
	-- {caseID = 42, description = "message_IsLowerBound"},
	-- {caseID = 43, description = "message_IsUpperBound"},
	-- {caseID = 44, description = "message_IsOutUpperBound"},
	-- {caseID = 45, description = "message_IsEmpty_IsOutLowerBound"},
	-- {caseID = 46, description = "message_IsWrongType"},
	-- {caseID = 47, description = "message_IsInvalidCharacter_Tab"},
	-- {caseID = 48, description = "message_IsInvalidCharacter_OnlySpaces"},
	-- {caseID = 49, description = "message_IsInvalidCharacter_Newline"},
	
	
	--caseID 51-55 are used to checking "available" parameter
	--51. IsMissed
	--52. IsWrongType
	-- {caseID = 51, description = "available_IsMissed"},
	-- {caseID = 52, description = "available_IsWrongType"},
	
}

for i=1, #TestData do
	
	local TestCaseName = "Case_" .. TestData[i].caseID .. "_IsReady_" ..TestData[i].description
	
	
	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup(TestCaseName)
	
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
		Test[tostring(TestCaseName) .. "_initHMI_onReady_TTS_InReady_" .. tostring(description)] = function(self)
			
			self:initHMI_onReady_TTS_IsReady(case)
			
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
	
	StopStartSDL_HMI_MOBILE(TestData[i].caseID, TestCaseName)
	Test[TestCaseName .. "_RegisterApplication_Check_TTS_Parameters_From_HMI_capabilities_json_resultCode_SUCCESS"] = function(self)
		
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
		
		
		-- Read TTS parameters from hmi_capabilities.json
		local HmiCapabilities_file = config.pathToSDL .. "hmi_capabilities.json"
		f = assert(io.open(HmiCapabilities_file, "r"))
		fileContent = f:read("*all")
		f:close()
		
		local json = require("modules/json")
		local HmiCapabilities = json.decode(fileContent)
		
		--mobile side: expect response
		-- SDL sends TTS-related parameters to mobile app with value from HMI_capabilities_json
		self.mobileSession:ExpectResponse(CorIdRegister, 
		{
			success = true, 
			resultCode = "SUCCESS",
			speechCapabilities = HmiCapabilities.TTS.capabilities,
			language = HmiCapabilities.TTS.language
		}
		)
		
		--mobile side: expect notification
		self.mobileSession:ExpectNotification("OnHMIStatus", { systemContext="MAIN", hmiLevel="NONE", audioStreamingState="NOT_AUDIBLE"})
		
	end	
	
	commonSteps:ActivationApp()
	
	commonSteps:PutFile("PutFile_action.png", "action.png")
	
	APPLINK_25139_checksplit_TTS_RPCs_TTS_Responds_SUCCESS_Or_UNSUPPORTED_RESOURCE_Others_respond_unsuccess_resultCodes(TestCaseName)
	APPLINK_25139_checksplit_TTS_RPCs_TTS_Responds_ERROR_Others_respond_SUCCESS_resultCodes(TestCaseName)	
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

-- Not applicable for TTS.IsReady HMI API.


----------------------------------------------------------------------------------------------
------------------------------------------Post-condition--------------------------------------
----------------------------------------------------------------------------------------------


function Test:Postcondition_Preloadedfile()
	print ("restoring sdl_preloaded_pt.json")
	commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end

return Test