-----------------------------------------------------------------------
-- values for interfaces.RPC and RAI are taken in global variables:
--	isReady.mobile_request - requests of application according to tested RPC
--  isReady.RPCs - structure of tested RPCs for tested interface
--	isReady.NotTestedInterfaces - structure of interfaces that are not in scope 
--                        of testing, but should be included
--  isReady.params_RAI - parameters according to tested interface at RAI
-----------------------------------------------------------------------
local isReady = {}

require('cardinalities')
local interface = require('user_modules/IsReady_Template/Interfaces_RPC')
local events = require('events')  
local mobile_session = require('mobile_session')
local commonPreconditions = require ('/user_modules/shared_testcases/commonPreconditions')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')

--User output
local function userPrint( color, message)
  print ("\27[" .. tostring(color) .. "m " .. tostring(message) .. " \27[0m")
end

---------------------------------------------------------------------------------------------
-----------------------------------Backup, updated preloaded file ---------------------------
---------------------------------------------------------------------------------------------
	local function UpdatePolicy()
		--Updated because of APPLINK-26629
		local PermissionLinesForBase4
		local PTName
			if ( (TestedInterface == "UI") or (TestedInterface == "VR") ) then
				local PermissionForDeleteCommand = 
				[[				
				"DeleteCommand": {
				"hmi_levels": [
				"BACKGROUND",
				"FULL",
				"LIMITED"
				]
				}
				]].. ", \n"
				local PermissionForShow = 
				[[				
				"Show": {
					"hmi_levels": [
					"BACKGROUND",
					"FULL",
					"LIMITED"
					]
				}
				]].. ", \n"
				local PermissionForAlert = 
				[[				
				"Alert": {
					"hmi_levels": [
					"BACKGROUND",
					"FULL",
					"LIMITED"
					]
				}
				]].. ", \n"
				local PermissionForSpeak = 
				[[				
				"Speak": {
					"hmi_levels": [
					"BACKGROUND",
					"FULL",
					"LIMITED"
					]
				}
				]].. ", \n"
				PermissionLinesForBase4 = PermissionForDeleteCommand..PermissionForShow..PermissionForAlert..PermissionForSpeak
				PTName = testCasesForPolicyTable:createPolicyTableFile_temp(PermissionLinesForBase4, nil, nil, {"DeleteCommand","Show","Alert","Speak"})	
			elseif(TestedInterface == "VehicleInfo") then
				local PermissionForReadDID = 
				[[				
				"ReadDID": {
				"hmi_levels": [
				"BACKGROUND",
				"FULL",
				"LIMITED"
				]
				}
				]].. ", \n"
				local PermissionForGetDTCs = 
				[[				
				"GetDTCs": {
				"hmi_levels": [
				"BACKGROUND",
				"FULL",
				"LIMITED"
				]
				}
				]].. ", \n"
				local PermissionForDiagnosticMessage = 
				[[				
				"DiagnosticMessage": {
				"hmi_levels": [
				"BACKGROUND",
				"FULL",
				"LIMITED"
				]
				}
				]].. ", \n"
				local PermissionForSubscribeVehicleData = 
				[[				
				"SubscribeVehicleData": {
				"hmi_levels": [
				"BACKGROUND",
				"FULL",
				"LIMITED"
				]
				}
				]].. ", \n"
				local PermissionForGetVehicleData = 
				[[				
				"GetVehicleData": {
				"hmi_levels": [
				"BACKGROUND",
				"FULL",
				"LIMITED"
				]
				}
				]].. ", \n"
				local PermissionForUnsubscribeVehicleData = 
				[[				
				"UnsubscribeVehicleData": {
				"hmi_levels": [
				"BACKGROUND",
				"FULL",
				"LIMITED"
				]
				}
				]].. ", \n"
				PermissionLinesForBase4 = PermissionForReadDID..PermissionForGetDTCs..PermissionForDiagnosticMessage..PermissionForSubscribeVehicleData..PermissionForGetVehicleData..PermissionForUnsubscribeVehicleData
				PTName = testCasesForPolicyTable:createPolicyTableFile_temp(PermissionLinesForBase4, nil, nil, {"ReadDID","GetDTCs","DiagnosticMessage","SubscribeVehicleData","GetVehicleData","UnsubscribeVehicleData"})	
			else --if (TestedInterface == "Navigation")
		
				local PermissionForSendLocation = 
				[[				
				"SendLocation": {
					"hmi_levels": [
					"BACKGROUND",
					"FULL",
					"LIMITED"
					]
				}
				]].. ", \n"
				local PermissionForShowConstantTBT = 
				[[				
				"ShowConstantTBT": {
					"hmi_levels": [
					"BACKGROUND",
					"FULL",
					"LIMITED"
					]
				}
				]].. ", \n"
				local PermissionForAlertManeuver = 
				[[				
				"AlertManeuver": {
					"hmi_levels": [
					"BACKGROUND",
					"FULL",
					"LIMITED"
					]
				}
				]].. ", \n"
				local PermissionForUpdateTurnList = 
				[[				
				"UpdateTurnList": {
					"hmi_levels": [
					"BACKGROUND",
					"FULL",
					"LIMITED"
					]
				}
				]].. ", \n"
				local PermissionForGetWayPoints = 
				[[				
				"GetWayPoints": {
					"hmi_levels": [
					"BACKGROUND",
					"FULL",
					"LIMITED"
					]
				}
				]].. ", \n"
				local PermissionForSubscribeWayPoints = 
				[[				
				"SubscribeWayPoints": {
					"hmi_levels": [
					"BACKGROUND",
					"FULL",
					"LIMITED"
					]
				}
				]].. ", \n"		
				local PermissionForUnsubscribeWayPoints = 
				[[				
				"UnsubscribeWayPoints": {
					"hmi_levels": [
					"BACKGROUND",
					"FULL",
					"LIMITED"
					]
				}
				]].. ", \n"	
				local PermissionForOnWayPointChange = 
				[[				
				"OnWayPointChange": {
					"hmi_levels": [
					"BACKGROUND",
					"FULL",
					"LIMITED"
					]
				}
				]].. ", \n"	
				local PermissionForOnTBTClientState = 
				[[				
				"OnTBTClientState": {
					"hmi_levels": [
					"BACKGROUND",
					"FULL",
					"LIMITED"
					]
				}
				]].. ", \n"		
				local PermissionForSpeak = 
				[[				
				"Speak": {
					"hmi_levels": [
					"BACKGROUND",
					"FULL",
					"LIMITED"
					]
				}
				]].. ", \n"			
				local PermissionForAlert = 
				[[				
				"Alert": {
					"hmi_levels": [
					"BACKGROUND",
					"FULL",
					"LIMITED"
					]
				}
				]].. ", \n"	
				PermissionLinesForBase4 = PermissionForSendLocation..PermissionForShowConstantTBT..PermissionForAlertManeuver..PermissionForUpdateTurnList..PermissionForGetWayPoints..PermissionForSubscribeWayPoints..PermissionForUnsubscribeWayPoints..PermissionForOnWayPointChange..PermissionForOnTBTClientState..PermissionForSpeak..PermissionForAlert
				PTName = testCasesForPolicyTable:createPolicyTableFile_temp(PermissionLinesForBase4, nil, nil, {"SendLocation","ShowConstantTBT","AlertManeuver","UpdateTurnList","GetWayPoints","SubscribeWayPoints","UnsubscribeWayPoints","OnWayPointChange","OnTBTClientState","Speak","Alert"})	
			end
			
		
		
		-- TODO: Remove after implementation policy update
		--testCasesForPolicyTable:updatePolicy(PTName)	
		testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt(PTName)
	end

	commonPreconditions:BackupFile("sdl_preloaded_pt.json")
	f = assert(io.open(commonPreconditions:GetPathToSDL().. "sdl_preloaded_pt.json", "r"))
	fileContent = f:read("*all")

    DefaultContant = fileContent:match('"default".?:.?.?%{.-%}')

    if not DefaultContant then
      print ( " \27[31m  default grpoup is not found in sdl_preloaded_pt.json \27[0m " )
    else
       DefaultContant =  string.gsub(DefaultContant, '".?groups.?".?:.?.?%[.-%]', '"groups": ["Base-4", "Location-1", "DrivingCharacteristics-3", "VehicleInfo-3", "Emergency-1", "PropriataryData-1"]')
    end


	fileContent  =  string.gsub(fileContent, '".?default.?".?:.?.?%{.-%}', DefaultContant)


	f = assert(io.open(commonPreconditions:GetPathToSDL().. "sdl_preloaded_pt.json", "w+"))
	
	f:write(fileContent)
	f:close()

	UpdatePolicy()

--Interfaces and RPCs that will be tested:
---------------------------------------------------------------------------
--if RPC is applicable for this interface, then:

	-- in structure mobile_request add request[count_RPC];
	isReady.mobile_request = {}
	-- in structure RPCs add RPC[count_RPC];
	isReady.RPCs = {}
	local count_RPC = 1
	-- position of RCP in structure usedRPC{}
	local position_RPC = {}

	-- Interfaces that are not scope of testing
	local count_NotTestedInterface = 1
	isReady.NotTestedInterfaces = {}

	for i = 1, #interface.RPC do
		if(interface.RPC[i].interface == TestedInterface) then
			print("====================== Tests are executed for "..TestedInterface.." interface. ====================================")
			for j = 1, #interface.RPC[i].usedRPC do
				
				if(interface.RPC[i].usedRPC[j].name ~= "Not applicable") then
				
					isReady.RPCs[count_RPC] = interface.RPC[i].usedRPC[j]
					position_RPC[count_RPC] = j

					-- will be added request only applicable for this interface
					isReady.mobile_request[count_RPC] = interface.mobile_req[j]

	 				count_RPC = count_RPC + 1
	 			end
	 		end
	 	else
			isReady.NotTestedInterfaces[count_NotTestedInterface] = interface.RPC[i]
			count_NotTestedInterface = count_NotTestedInterface +1 
	  end
	end

	isReady.params_RAI = {}
	for i = 1, #interface.RAI do
		if(interface.RAI[i].name == TestedInterface) then
			isReady.params_RAI = interface.RAI[i].params
		end
	end
---------------------------------------------------------------------------
-- Tested Data according to JSON format
	TestData = {

		--caseID 1-3 are used to check special cases
		{caseID = 1, description = "HMI_Does_Not_Respond"},
		{caseID = 2, description = "MissedAllParamaters"},
		{caseID = 3, description = "Invalid_Json"},

				
		--caseID 11-14 are used to check "collerationID" parameter
			--11. IsMissed
			--12. IsNonexistent
			--13. IsWrongType
			--14. IsNegative 	
		{caseID = 11, description = "correlationID_IsMissed"},
		{caseID = 12, description = "correlationID_IsNonexistent"},
		{caseID = 13, description = "correlationID_IsWrongType"},
		{caseID = 14, description = "correlationID_IsNegative"},

		--caseID 21-27 are used to check "method" parameter
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
		{caseID = 26, description = "method_IsInvalidCharacter_Space"},
		{caseID = 26, description = "method_IsInvalidCharacter_Tab"},
		{caseID = 26, description = "method_IsInvalidCharacter_NewLine"},

			-- --caseID 31-35 are used to check "resultCode" parameter
				-- --31. IsMissed
				-- --32. IsNotExist
				-- --33. IsEmpty
				-- --34. IsWrongType
		{caseID = 31,  description = "resultCode_IsMissed"},
		{caseID = 32,  description = "resultCode_IsNotExist"},
		{caseID = 33,  description = "resultCode_IsWrongType"},
		{caseID = 34,  description = "resultCode_INVALID_DATA"},
		{caseID = 35,  description = "resultCode_DATA_NOT_AVAILABLE"},
		{caseID = 36,  description = "resultCode_GENERIC_ERROR"},
		

		--caseID 41-45 are used to check "message" parameter
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
		

		--caseID 51-55 are used to check "available" parameter
			--51. IsMissed
			--52. IsWrongType
		{caseID = 51,  description = "available_IsMissed"},
		{caseID = 52,  description = "available_IsWrongType"},

		--caseID 61-64 are used to check "successfull_resultCode" parameter with available = true
			--61. resultCode_WARNINGS_available_true
			--62. resultCode_WRONG_LANGUAGE_available_true
			--63. resultCode_RETRY_available_true
			--64. resultCode_SAVED_available_true (code = 11)
		{caseID = 61,  description = "resultCode_WARNINGS_available_true"},
		{caseID = 62,  description = "resultCode_WRONG_LANGUAGE_available_true"},
		{caseID = 63,  description = "resultCode_RETRY_available_true"},
		{caseID = 64,  description = "resultCode_SAVED_available_true"},
	}
---------------------------------------------------------------------------
-- Tested Data according to available false
	TestData_AvailableFalse = {

		--caseID 1-5 are used to check "successfull_resultCode" parameter with available = false
		{caseID = 1,  description = "resultCode_SUCCESS_available_false", value = 0},
		{caseID = 2,  description = "resultCode_WARNINGS_available_false", value = 21},
		{caseID = 3,  description = "resultCode_WRONG_LANGUAGE_available_false", value = 16},
		{caseID = 4,  description = "resultCode_RETRY_available_false", value = 7},
		{caseID = 5,  description = "resultCode_SAVED_available_false", value = 25},
				
		--caseID 11-28 are used to check "error_resultCode" parameter with available = false
		{caseID = 11, description = "resultCode_UNSUPPORTED_REQUEST_available_false", value = 1},
		{caseID = 12, description = "resultCode_DISALLOWED_available_false", value = 3},
		{caseID = 13, description = "resultCode_USER_DISALLOWED_available_false", value = 23},
		{caseID = 14, description = "resultCode_REJECTED_available_false", value = 4},
		{caseID = 15, description = "resultCode_ABORTED_available_false", value = 5},
		{caseID = 16, description = "resultCode_IGNORED_available_false", value = 6},
		{caseID = 17, description = "resultCode_IN_USE_available_false", value = 8},
		{caseID = 18, description = "resultCode_DATA_NOT_AVAILABLE_available_false", value = 0},
		{caseID = 19, description = "resultCode_TIMED_OUT_available_false", value = 10},
		{caseID = 20, description = "resultCode_INVALID_DATA_available_false", value = 11},
		{caseID = 21, description = "resultCode_CHAR_LIMIT_EXCEEDED_available_false", value = 12},
		{caseID = 22, description = "resultCode_INVALID_ID_available_false", value = 13},
		{caseID = 23, description = "resultCode_DUPLICATE_NAME_available_false", value = 14},
		{caseID = 24, description = "resultCode_APPLICATION_NOT_REGISTERED_available_false", value = 15},
		{caseID = 25, description = "resultCode_OUT_OF_MEMORY_available_false", value = 17},
		{caseID = 26, description = "resultCode_TOO_MANY_PENDING_REQUESTS_available_false", value = 18},
		{caseID = 27, description = "resultCode_GENERIC_ERROR_available_false", value = 22},
		{caseID = 28, description = "resultCode_TRUNCATED_DATA_available_false", value = 24},

		--caseID 31-48 are used to check "error_resultCode" parameter with available = true
		{caseID = 31, description = "resultCode_UNSUPPORTED_REQUEST_available_true", value = 1},
		{caseID = 32, description = "resultCode_DISALLOWED_available_true", value = 3},
		{caseID = 33, description = "resultCode_USER_DISALLOWED_available_true", value = 23},
		{caseID = 34, description = "resultCode_REJECTED_available_true", value = 4},
		{caseID = 35, description = "resultCode_ABORTED_available_true", value = 5},
		{caseID = 36, description = "resultCode_IGNORED_available_true", value = 6},
		{caseID = 37, description = "resultCode_IN_USE_available_true", value = 8},
		{caseID = 38, description = "resultCode_DATA_NOT_AVAILABLE_available_true", value = 0},
		{caseID = 39, description = "resultCode_TIMED_OUT_available_true", value = 10},
		{caseID = 40, description = "resultCode_INVALID_DATA_available_true", value = 11},
		{caseID = 41, description = "resultCode_CHAR_LIMIT_EXCEEDED_available_true", value = 12},
		{caseID = 42, description = "resultCode_INVALID_ID_available_true", value = 13},
		{caseID = 43, description = "resultCode_DUPLICATE_NAME_available_true", value = 14},
		{caseID = 44, description = "resultCode_APPLICATION_NOT_REGISTERED_available_true", value = 15},
		{caseID = 45, description = "resultCode_OUT_OF_MEMORY_available_true", value = 17},
		{caseID = 46, description = "resultCode_TOO_MANY_PENDING_REQUESTS_available_true", value = 18},
		{caseID = 47, description = "resultCode_GENERIC_ERROR_available_true", value = 22},
		{caseID = 48, description = "resultCode_TRUNCATED_DATA_available_true", value = 24},

	}
---------------------------------------------------------------------------

---------------------------------------------------------------------------------------------	
	function isReady:Common_initHMI_onReady_Interfaces_IsReady(self, case)
	
		critical(false)
		local tested_method = (TestedInterface..".IsReady") 
	  
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

						-- VR:          APPLINK-25286: [HMI_API] VR.IsReady
						-- UI:          APPLINK-25299: [HMI_API] UI.IsReady
						-- TTS:         APPLINK-25303: [HMI_API] TTS.IsReady
						-- VehicleInfo: APPLINK-25305: [HMI_API] VehicleInfo.IsReady
						-- Navigation:  APPLINK-25301: [HMI_API] Navi.IsReady
						if (name == tested_method) then
						
							--On the view of JSON message, Interface.IsReady response has colerationidID, code/resultCode, method and message parameters. Below are tests to verify all invalid cases of the response.
							
							--caseID 1-3: Check special cases
								--0. available_false
								--1. HMI_Does_Not_Repond
								--2. MissedAllParamaters
								--3. Invalid_Json

							if (case == 0) then -- responds {available = false}
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {available = false}) 
									
							elseif (case == 1) then -- does not respond
								--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", params) 
								
							elseif (case == 2) then --MissedAllParamaters
								self.hmiConnection:Send('{}')
								
							elseif (case == 3) then --Invalid_Json
								--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"'..tested_method..'", "code":0}}')	
								self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc";"2.0","result":{"available":true,"method":"'..tested_method..'", "code":0}}')	
							
							--*****************************************************************************************************************************
							
							--caseID 11-14 are used to check "collerationID" parameter
								--11. collerationID_IsMissed
								--12. collerationID_IsNonexistent
								--13. collerationID_IsWrongType
								--14. collerationID_IsNegative 	
								
							elseif (case == 11) then --correlationID_IsMissed
								--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"'..tested_method..'", "code":0}}')
							    self.hmiConnection:Send('{"jsonrpc":"2.0","result":{"available":true,"method":"'..tested_method..'", "code":0}}')
								  
							elseif (case == 12) then --correlationID_IsNonexistent
								--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"'..tested_method..'", "code":0}}')
								self.hmiConnection:Send('{"id":'..tostring(data.id + 10)..',"jsonrpc":"2.0","result":{"available":true,"method":"'..tested_method..'", "code":0}}')
									  
							elseif (case == 13) then --correlationID_IsWrongType
								--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"'..tested_method..'", "code":0}}')
							    self.hmiConnection:Send('{"id":"'..tostring(data.id)..'","jsonrpc":"2.0","result":{"available":true,"method":"'..tested_method..'", "code":0}}')
									  
							elseif (case == 14) then --correlationID_IsNegative
								self.hmiConnection:Send('{"id":'..tostring(-1)..',"jsonrpc":"2.0","result":{"available":true,"method":"'..tested_method..'", "code":0}}')
								
							--*****************************************************************************************************************************
								
							--caseID 21-27 are used to check "method" parameter
								--21. method_IsMissed
								--22. method_IsNotValid
								--23. method_IsOtherResponse
								--24. method_IsEmpty
								--25. method_IsWrongType
								--26. method_IsInvalidCharacter_Newline
								--27. method_IsInvalidCharacter_OnlySpaces
								--28. method_IsInvalidCharacter_Tab
								
							elseif (case == 21) then --method_IsMissed
								--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"'..tested_method..'", "code":0}}')
							    self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"code":0}}')
							elseif (case == 22) then --method_IsNotValid
								local method_IsNotValid = TestedInterface ..".IsRea"
								--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"'..tested_method..'", "code":0}}')
							    self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"'..method_IsNotValid..'", "code":0}}')				

							elseif (case == 23) then --method_IsOtherResponse
								local method_IsOtherResponse = isReady.NotTestedInterfaces[1].interface .. ".IsReady"
								--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"'..tested_method..'", "code":0}}')
							    self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"'..method_IsOtherResponse..'", "code":0}}')			

							elseif (case == 24) then --method_IsEmpty
								--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"'..tested_method..'", "code":0}}')
							    self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"", "code":0}}')							 
								
							elseif (case == 25) then --method_IsWrongType
								--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"'..tested_method..'", "code":0}}')
							    self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":123456789, "code":0}}')
								
							elseif (case == 26) then --method_IsInvalidCharacter_Newline
								local method_IsInvalidCharacter_Newline = TestedInterface ..".IsR\neady"
								--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"'..tested_method..'", "code":0}}')
								self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"'..method_IsInvalidCharacter_Newline..'", "code":0}}')
								
							elseif (case == 27) then --method_IsInvalidCharacter_OnlySpaces
								--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"'..tested_method..'", "code":0}}')
								self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"  ", "code":0}}')
								
							elseif (case == 28) then --method_IsInvalidCharacter_Tab
								local method_IsInvalidCharacter_Tab = TestedInterface ..".IsR\teady"
								--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"'..tested_method..'", "code":0}}')
								self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"'..method_IsInvalidCharacter_Tab..'", "code":0}}')		
									  
							--*****************************************************************************************************************************
								
							--caseID 31-35 are used to check "resultCode" parameter
								--31. resultCode_IsMissed
								--32. resultCode_IsNotExist
								--33. resultCode_IsWrongType
								--34. resultCode_INVALID_DATA (code = 11)
								--35. resultCode_DATA_NOT_AVAILABLE (code = 9)
								--36. resultCode_GENERIC_ERROR (code = 22)
									
							elseif (case == 31) then --resultCode_IsMissed
								--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"'..tested_method..'", "code":0}}')
								self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"'..tested_method..'"}}')

							elseif (case == 32) then --resultCode_IsNotExist
								--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"'..tested_method..'", "code":0}}')
							    self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"'..tested_method..'", "code":123}}')

							elseif (case == 33) then --resultCode_IsWrongType
								--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"'..tested_method..'", "code":0}}')
								self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"'..tested_method..'", "code":"0"}}')
								
							elseif (case == 34) then --resultCode_INVALID_DATA
								--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"'..tested_method..'", "code":0}}')
								self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"'..tested_method..'", "code":11}}')
								
							elseif (case == 35) then --resultCode_DATA_NOT_AVAILABLE
								--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"'..tested_method..'", "code":0}}')
								self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"'..tested_method..'", "code":9}}')
								
							elseif (case == 36) then --resultCode_GENERIC_ERROR
								--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"'..tested_method..'", "code":0}}')
							    self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"'..tested_method..'", "code":22}}')
								
								
							--*****************************************************************************************************************************
								
							--caseID 41-45 are used to check "message" parameter
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
								--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"'..tested_method..'"}, "message":"The data sent is invalid","code":11}}') --INVALID_DATA
								self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"'..tested_method..'"}, "message":"The data sent is invalid","code":11}}')
									  
							elseif (case == 42) then --message_IsLowerBound
								local messageValue = "a"
								--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"'..tested_method..'"}, "message":"The data sent is invalid","code":11}}') --INVALID_DATA
								self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"'..tested_method..'"}, "message":"' .. messageValue ..'","code":11}}')
												  
							elseif (case == 43) then --message_IsUpperBound
								local messageValue = string.rep("a", 1000)
								--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"'..tested_method..'"}, "message":"The data sent is invalid","code":11}}') --INVALID_DATA
								  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"'..tested_method..'"}, "message":"' .. messageValue ..'","code":11}}')
								
							elseif (case == 44) then --message_IsOutUpperBound
									local messageValue = string.rep("a", 1001)
									--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"'..tested_method..'"}, "message":"The data sent is invalid","code":11}}') --INVALID_DATA
									  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"'..tested_method..'"}, "message":"' .. messageValue ..'","code":11}}')

							elseif (case == 45) then --message_IsEmpty_IsOutLowerBound
									--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"'..tested_method..'"}, "message":"The data sent is invalid","code":11}}') --INVALID_DATA
									  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"'..tested_method..'"}, "message":"","code":11}}')

							elseif (case == 46) then --message_IsWrongType
									--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"'..tested_method..'"}, "message":"The data sent is invalid","code":11}}') --INVALID_DATA
									  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"'..tested_method..'"}, "message":123,"code":11}}')
									  
							elseif (case == 47) then --message_IsInvalidCharacter_Tab
									--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"'..tested_method..'"}, "message":"The data sent is invalid","code":11}}') --INVALID_DATA
									  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"'..tested_method..'"}, "message":"a\tb","code":11}}')

							elseif (case == 48) then --message_IsInvalidCharacter_OnlySpaces
									--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"'..tested_method..'"}, "message":"The data sent is invalid","code":11}}') --INVALID_DATA
									  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"'..tested_method..'"}, "message":"  ","code":11}}')

							elseif (case == 49) then --message_IsInvalidCharacter_Newline
									--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"'..tested_method..'"}, "message":"The data sent is invalid","code":11}}') --INVALID_DATA
									  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"'..tested_method..'"}, "message":"a\n\b","code":11}}')

							--*****************************************************************************************************************************

							--caseID 51-55 are used to check "available" parameter
									--51. available_IsMissed
									--52. available_IsWrongType

							elseif (case == 51) then --available_IsMissed
									--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"'..tested_method..'", "code":0}}')
									  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"'..tested_method..'", "code":"0"}}')
						  
							elseif (case == 52) then --available_IsWrongType
									--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"'..tested_method..'", "code":0}}')
									  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":"true","method":"'..tested_method..'", "code":"0"}}')

							--*****************************************************************************************************************************
							--caseID 61-64 are used to check "successfull_resultCode" parameter with available = true
							elseif (case == 61) then -- SUCCESS
								self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true, "method":"'..data.method..'","code": 0}}')
							elseif (case == 62) then -- WARNINGS
								self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true, "method":"'..data.method..'","code": 21}}')
							elseif (case == 63) then -- WRONG_LANGUAGE
								self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true, "method":"'..data.method..'","code": 16}}')
							elseif (case == 64) then -- RETRY
								self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true, "method":"'..data.method..'","code": 7}}')
							elseif (case == 65) then -- SAVED
								self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true, "method":"'..data.method..'","code": 25}}')
							else
								print("***************************Error: "..tested_method..": Input value is not correct ***************************")
							end			
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

		    ExpectRequest("BasicCommunication.MixingAudioSupported", true, { attenuatedSupported = true })
		    ExpectRequest("BasicCommunication.GetSystemInfo", false, {
																        ccpu_version = "ccpu_version",
																        language = "EN-US",
																        wersCountryCode = "wersCountryCode"
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
		    ----------------------------------------------------------------------------------------
		    -- Params for specific RPCs that are tested in scope of IsReady
			    local params_TTS_GetCapabilities = {
				    									speechCapabilities = { "TEXT", "PRE_RECORDED" },
												        prerecordedSpeechCapabilities =
												        {
												          "HELP_JINGLE",
												          "INITIAL_JINGLE",
												          "LISTEN_JINGLE",
												          "POSITIVE_JINGLE",
												          "NEGATIVE_JINGLE"
												        }
													}
				
				local params_UI_GetCapabilities = {  
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
											        hmiDisplayLanguage  = "EN-US",
											        softButtonCapabilities =
											        {{
											          shortPressAvailable = true,
											          longPressAvailable = true,
											          upDownAvailable = true,
											          imageSupported = true
											        }},
											        hmiCapabilities = { 
											        					navigation = false,
											        					phoneCall  = false,
											        					steeringWheelLocation = "CENTER"
											        				}
											    }

				local params_VR_GetCapabilities = {vrCapabilities = { "TEXT" }}

				local params_VehInfo_GetVehicleType = { vehicleType =
																        {
																          make = "Ford",
																          model = "Fiesta",
																          modelYear = "2013",
																          trim = "SE"
																        }}
			----------------------------------------------------------------------------------------
		    ExpectRequest(tested_method, true, { available = true })

		    --VR:          APPLINK-25100 / APPLINK-25099
		    --UI:          APPLINK-25102 / APPLINK-25099
		    --TTS:         APPLINK-25139 / APPLINK-25134
		    --VehicleInfo: NotApplicable for start-up RPCs
		    --Navigation:  APPLINK - 25225 / APPLINK-25224
		    
			if(case == 0) then
				--TestedInterface.IsReady: available = false:
				-- RPC are not transfered
				if(TestedInterface == "VR" or TestedInterface == "UI" or TestedInterface == "TTS") then
					ExpectRequest(TestedInterface ..".GetLanguage" , true, { language = "EN-US" })
		    		:Times(0)

		    		ExpectRequest(TestedInterface ..".GetSupportedLanguages" , true, { language = "EN-US" })
		    		:Times(0)

		    		ExpectRequest(TestedInterface ..".GetCapabilities", true, { vrCapabilities = { "TEXT" } })
					:Times(0)
				end
				if(TestedInterface == "VehicleInfo" ) then
					ExpectRequest("VehicleInfo.GetVehicleType", true, params_VehInfo_GetVehicleType)
					:Times(0)
				end
			else -- (case ~=0)
				-- TestedInterface.IsReady is not sent
				-- RPC are transfered
		    	-- https://adc.luxoft.com/confluence/pages/viewpage.action?pageId=290334082&focusedCommentId=290338124#comment-290338124
		    	-- As result, in case HMI does NOT respond to Vehicle.IsReady -> SDL can send this request to HMI 
		    	if( TestedInterface == "VehicleInfo") then
					ExpectRequest("VehicleInfo.GetVehicleType", true, params_VehInfo_GetVehicleType)
					:Timeout(20000)
				end

				if(TestedInterface == "VR" or TestedInterface == "UI" or TestedInterface == "TTS") then
					local params_GetCapabilities = params_VR_GetCapabilities
					
					if (TestedInterface == "UI")      then params_GetCapabilities = params_UI_GetCapabilities
					elseif(TestedInterface == "TTS")  then params_GetCapabilities = params_TTS_GetCapabilities	end

					ExpectRequest(TestedInterface ..".GetLanguage" , true, { language = "EN-US" })
					:Timeout(20000)

		    		ExpectRequest(TestedInterface ..".GetSupportedLanguages" , true, {  languages = {
																								        "EN-US","ES-MX","FR-CA","DE-DE","ES-ES","EN-GB","RU-RU",
																								        "TR-TR","PL-PL","FR-FR","IT-IT","SV-SE","PT-PT","NL-NL",
																								        "ZH-TW","JA-JP","AR-SA","KO-KR","PT-BR","CS-CZ","DA-DK",
																								        "NO-NO","NL-BE","EL-GR","HU-HU","FI-FI","SK-SK" } })
		    		:Timeout(20000)

		    		ExpectRequest(TestedInterface ..".GetCapabilities", true,  params_GetCapabilities )
		    		:Timeout(20000)
				end
			end

		    for i = 1, #isReady.NotTestedInterfaces do
		    	if(isReady.NotTestedInterfaces[i].interface == "VR" or isReady.NotTestedInterfaces[i].interface == "UI" or isReady.NotTestedInterfaces[i].interface == "TTS") then
			    	ExpectRequest(isReady.NotTestedInterfaces[i].interface ..".GetLanguage", true, { language = "EN-US" })
			    	:Timeout(20000)
			    	ExpectRequest(isReady.NotTestedInterfaces[i].interface ..".GetSupportedLanguages", true, { languages =
																					        {
																					          "EN-US","ES-MX","FR-CA","DE-DE","ES-ES","EN-GB","RU-RU","TR-TR","PL-PL",
																					          "FR-FR","IT-IT","SV-SE","PT-PT","NL-NL","ZH-TW","JA-JP","AR-SA","KO-KR",
																					          "PT-BR","CS-CZ","DA-DK","NO-NO"
																					        } })	    	
			    	:Timeout(20000)

					if  ( isReady.NotTestedInterfaces[i].interface == "UI") then 
						
						ExpectRequest("UI.GetCapabilities", true,   params_UI_GetCapabilities )
						:Timeout(20000)
					elseif( isReady.NotTestedInterfaces[i].interface == "TTS") then
						
						ExpectRequest("TTS.GetCapabilities", true, params_TTS_GetCapabilities)
						:Timeout(20000)
					elseif( isReady.NotTestedInterfaces[i].interface == "VR") then
						
						ExpectRequest("VR.GetCapabilities", true,   params_VR_GetCapabilities )
						:Timeout(20000)
					end
				end
				if(isReady.NotTestedInterfaces[i].interface == "VehicleInfo" ) then
					ExpectRequest("VehicleInfo.GetVehicleType", true, params_VehInfo_GetVehicleType)
					:Timeout(20000)
				end
		    end
	    
		    ExpectRequest("UI.ChangeRegistration", false, { }):Pin()
		    ExpectRequest("TTS.SetGlobalProperties", false, { }):Pin()
		    ExpectRequest("BasicCommunication.UpdateDeviceList", false, { }):Pin()
		    ExpectRequest("VR.ChangeRegistration", false, { }):Pin()
			
		    ExpectRequest("TTS.ChangeRegistration", false, { }):Pin()
		    
		    ExpectRequest("VehicleInfo.GetVehicleData", true, { vin = "52-452-52-752" })
			-- TODO: APPLINK-28499: Should VehicleInfo.GetVehicleData be expected with initHMI OnReady
			-- Update after clarification if needed.
			:Times(0)
			:Timeout(10000)

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
	    
		    for i = 1, #isReady.NotTestedInterfaces do
		    	ExpectRequest(isReady.NotTestedInterfaces[i].interface ..".IsReady", true, { available = true })
		    end

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

 	function isReady:Common_initHMI_onReady_Interfaces_IsReady_available_false(self, case, result_value)

		if result_value == nil then result_value = 0 end

		critical(false)
		local tested_method = (TestedInterface..".IsReady") 
	  
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

						-- VR:          APPLINK-25286: [HMI_API] VR.IsReady
						-- UI:          APPLINK-25299: [HMI_API] UI.IsReady
						-- TTS:         APPLINK-25303: [HMI_API] TTS.IsReady
						-- VehicleInfo: APPLINK-25305: [HMI_API] VehicleInfo.IsReady
						-- Navigation:  APPLINK-25301: [HMI_API] Navi.IsReady
						if (name == tested_method) then
							--caseID 1-5 are used to check "successfull_resultCode" parameter with available = false
							if (case > 0 and case < 6) then -- SUCCESS
								self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":false, "method":"'..data.method..'","code":'..tostring(result_value)..'}}')

							--caseID 11-28 are used to check "error_resultCode" parameter with available = false
							elseif ( case > 10 and case < 29) then -- <<error>> with available = false
								self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":false, "method":"'..data.method..'","code":'..tostring(result_value)..'}}')

							--caseID 31-48 are used to check "error_resultCode" parameter with available = true
							elseif ( case > 30 and case < 49) then -- <<error>> with available = true
								self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true, "method":"'..data.method..'","code":'..tostring(result_value)..'}}')
							else
								print("***************************Error: "..tested_method..": Input value is not correct ***************************")
							end			
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

		    ExpectRequest("BasicCommunication.MixingAudioSupported", true, { attenuatedSupported = true })
		    ExpectRequest("BasicCommunication.GetSystemInfo", false, {
																        ccpu_version = "ccpu_version",
																        language = "EN-US",
																        wersCountryCode = "wersCountryCode"
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
		    ----------------------------------------------------------------------------------------
		    -- Params for specific RPCs that are tested in scope of IsReady
			    local params_TTS_GetCapabilities = {
				    									speechCapabilities = { "TEXT", "PRE_RECORDED" },
												        prerecordedSpeechCapabilities =
												        {
												          "HELP_JINGLE",
												          "INITIAL_JINGLE",
												          "LISTEN_JINGLE",
												          "POSITIVE_JINGLE",
												          "NEGATIVE_JINGLE"
												        }
													}
				
				local params_UI_GetCapabilities = {  
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
											        hmiDisplayLanguage  = "EN-US",
											        softButtonCapabilities =
											        {{
											          shortPressAvailable = true,
											          longPressAvailable = true,
											          upDownAvailable = true,
											          imageSupported = true
											        }},
											        hmiCapabilities = { 
											        					navigation = false,
											        					phoneCall  = false,
											        					steeringWheelLocation = "CENTER"
											        				}
											    }

				local params_VR_GetCapabilities = {vrCapabilities = { "TEXT" }}

				local params_VehInfo_GetVehicleType = { vehicleType =
																        {
																          make = "Ford",
																          model = "Fiesta",
																          modelYear = "2013",
																          trim = "SE"
																        }}
			----------------------------------------------------------------------------------------
		    ExpectRequest(tested_method, true, { available = true })

		    --VR:          APPLINK-25100 / APPLINK-25099
		    --UI:          APPLINK-25102 / APPLINK-25099
		    --TTS:         APPLINK-25139 / APPLINK-25134
		    --VehicleInfo: NotApplicable for start-up RPCs
		    --Navigation:  APPLINK - 25225 / APPLINK-25224
		    
			if(case > 0) then
				--TestedInterface.IsReady: available = false:
				-- RPC are not transfered
				if(TestedInterface == "VR" or TestedInterface == "UI" or TestedInterface == "TTS") then
					ExpectRequest(TestedInterface ..".GetLanguage" , true, { language = "EN-US" })
		    		:Times(0)

		    		ExpectRequest(TestedInterface ..".GetSupportedLanguages" , true, { language = "EN-US" })
		    		:Times(0)

		    		ExpectRequest(TestedInterface ..".GetCapabilities", true, { vrCapabilities = { "TEXT" } })
					:Times(0)
				end
				if(TestedInterface == "VehicleInfo" ) then
					ExpectRequest("VehicleInfo.GetVehicleType", true, params_VehInfo_GetVehicleType)
					:Times(0)
				end
			end

		    for i = 1, #isReady.NotTestedInterfaces do
		    	if(isReady.NotTestedInterfaces[i].interface == "VR" or isReady.NotTestedInterfaces[i].interface == "UI" or isReady.NotTestedInterfaces[i].interface == "TTS") then
			    	ExpectRequest(isReady.NotTestedInterfaces[i].interface ..".GetLanguage", true, { language = "EN-US" })
			    	:Timeout(20000)
			    	ExpectRequest(isReady.NotTestedInterfaces[i].interface ..".GetSupportedLanguages", true, { languages =
																					        {
																					          "EN-US","ES-MX","FR-CA","DE-DE","ES-ES","EN-GB","RU-RU","TR-TR","PL-PL",
																					          "FR-FR","IT-IT","SV-SE","PT-PT","NL-NL","ZH-TW","JA-JP","AR-SA","KO-KR",
																					          "PT-BR","CS-CZ","DA-DK","NO-NO"
																					        } })	    	
			    	:Timeout(20000)

					if  ( isReady.NotTestedInterfaces[i].interface == "UI") then 
						
						ExpectRequest("UI.GetCapabilities", true,   params_UI_GetCapabilities )
						:Timeout(20000)
					elseif( isReady.NotTestedInterfaces[i].interface == "TTS") then
						
						ExpectRequest("TTS.GetCapabilities", true, params_TTS_GetCapabilities)
						:Timeout(20000)
					elseif( isReady.NotTestedInterfaces[i].interface == "VR") then
						
						ExpectRequest("VR.GetCapabilities", true,   params_VR_GetCapabilities )
						:Timeout(20000)
					end
				end
				if(isReady.NotTestedInterfaces[i].interface == "VehicleInfo" ) then
					ExpectRequest("VehicleInfo.GetVehicleType", true, params_VehInfo_GetVehicleType)
					:Timeout(20000)
				end
		    end
	    
		    ExpectRequest("UI.ChangeRegistration", false, { }):Pin()
		    ExpectRequest("TTS.SetGlobalProperties", false, { }):Pin()
		    ExpectRequest("BasicCommunication.UpdateDeviceList", false, { }):Pin()
		    ExpectRequest("VR.ChangeRegistration", false, { }):Pin()
			
		    ExpectRequest("TTS.ChangeRegistration", false, { }):Pin()
		    
		    ExpectRequest("VehicleInfo.GetVehicleData", true, { vin = "52-452-52-752" })
			-- TODO: APPLINK-28499: Should VehicleInfo.GetVehicleData be expected with initHMI OnReady
			-- Update after clarification if needed.
			:Times(0)
			:Timeout(10000)

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
	    
		    for i = 1, #isReady.NotTestedInterfaces do
		    	ExpectRequest(isReady.NotTestedInterfaces[i].interface ..".IsReady", true, { available = true })
		    end

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

 	function isReady:StopStartSDL_HMI_MOBILE(self, case, TestCaseName)
		
			--Stop SDL
			Test["Precondition_StopSDL_" ..tostring(TestCaseName)] = function(self)

				userPrint(33, "Preconditions:")

				StopSDL()
			end
			
			--Start SDL
			Test["Precondition_StartSDL_" ..tostring(TestCaseName) ] = function(self)

				StartSDL(commonPreconditions:GetPathToSDL(), config.ExitOnCrash)
			end
			
			--InitHMI
			Test["Precondition_InitHMI_" ..tostring(TestCaseName)] = function(self)

				self:initHMI()
			end

			-- VR:          APPLINK-25286: [HMI_API] VR.IsReady
			-- UI:          APPLINK-25299: [HMI_API] UI.IsReady
			-- TTS:         APPLINK-25303: [HMI_API] TTS.IsReady
			-- VehicleInfo: APPLINK-25305: [HMI_API] VehicleInfo.IsReady
			-- Navigation:  APPLINK-25301: [HMI_API] Navi.IsReady
			Test["Precondition_initHMI_onReady_"..TestedInterface.."_IsReady_" .. tostring(TestCaseName)] = function(self)

				isReady:Common_initHMI_onReady_Interfaces_IsReady(self,case)
			end
			
			--ConnectMobile
			Test["Precondition_ConnectMobile_" ..tostring(TestCaseName)] = function(self)

				self:connectMobile()
			end
			
			--StartSession
			Test["Precondition_StartSession_"..tostring(TestCaseName)] = function(self)

				self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
				self.mobileSession:StartService(7)
			end
	end

	function isReady:StopStartSDL_HMI_MOBILE_available_false(self, case, value, TestCaseName)
		
			--Stop SDL
			Test["Precondition_StopSDL_" ..tostring(TestCaseName)] = function(self)

				userPrint(33, "Preconditions:")

				StopSDL()
			end
			
			--Start SDL
			Test["Precondition_StartSDL_" ..tostring(TestCaseName) ] = function(self)

				StartSDL(commonPreconditions:GetPathToSDL(), config.ExitOnCrash)
			end
			
			--InitHMI
			Test["Precondition_InitHMI_" ..tostring(TestCaseName)] = function(self)

				self:initHMI()
			end

			-- VR:          APPLINK-25286: [HMI_API] VR.IsReady
			-- UI:          APPLINK-25299: [HMI_API] UI.IsReady
			-- TTS:         APPLINK-25303: [HMI_API] TTS.IsReady
			-- VehicleInfo: APPLINK-25305: [HMI_API] VehicleInfo.IsReady
			-- Navigation:  APPLINK-25301: [HMI_API] Navi.IsReady
			Test["Precondition_initHMI_onReady_"..TestedInterface.."_IsReady_" .. tostring(TestCaseName)] = function(self)

				isReady:Common_initHMI_onReady_Interfaces_IsReady_available_false(self, case, value)
			end
			
			--ConnectMobile
			Test["Precondition_ConnectMobile_" ..tostring(TestCaseName)] = function(self)

				self:connectMobile()
			end
			
			--StartSession
			Test["Precondition_StartSession_"..tostring(TestCaseName)] = function(self)

				self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
				self.mobileSession:StartService(7)
			end
	end
return isReady
