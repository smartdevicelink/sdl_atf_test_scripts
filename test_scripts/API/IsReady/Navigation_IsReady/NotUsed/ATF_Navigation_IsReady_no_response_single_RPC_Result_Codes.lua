config.defaultProtocolVersion = 2


---------------------------------------------------------------------------------------------
---------------------------- Required Shared libraries --------------------------------------
---------------------------------------------------------------------------------------------

local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local commonPreconditions = require ('/user_modules/shared_testcases/commonPreconditions')

APIName = "NV.IsReady"

DefaultTimeout = 12
local TimeoutValue = 10000
local TimeDelay = 2000
local infoMsgUnsupported = "Navi is not supported by system"

---------------------------------------------------------------------------------------------
---------------------------- General Settings for configuration----------------------------
---------------------------------------------------------------------------------------------
Test = require('connecttest')

require('cardinalities')
local events = require('events') 
local mobile_session = require('mobile_session')
require('user_modules/AppTypes')

--TODO: waiting for confirm from APPLINK-28100 to update list of cases (HMI invalid response)
local TestCases = {
	
	{caseID = 1, description = ": HMI_Response_false"},
	
	{caseID = 2, description = ": HMI_does_not_response_request"},
	
	
	-- TCs from here check for invalid HMI response
	--caseID 3-4 are used to checking special cases
	{caseID = 3, description = ": InvalidHMIResponse_MissedAllParamaters"},
	{caseID = 4, description = ": InvalidHMIResponse_Invalid_Json"},
	
	
	--caseID 11-14 are used to checking "collerationID" parameter
	--11. IsMissed
	--12. IsNonexistent
	--13. IsWrongType
	--14. IsNegative 	
	{caseID = 11, description = ": InvalidHMIResponse_collerationID_IsMissed"},
	{caseID = 12, description = ": InvalidHMIResponse_collerationID_IsNonexistent"},
	{caseID = 13, description = ": InvalidHMIResponse_collerationID_IsWrongType"},
	{caseID = 14, description = ": InvalidHMIResponse_collerationID_IsNegative"},
	
	--caseID 21-27 are used to checking "method" parameter
	--21. IsMissed
	--22. IsNotValid
	--23. IsOtherResponse
	--24. IsEmpty
	--25. IsWrongType
	--26. IsInvalidCharacter - \n, \t, only spaces
	{caseID = 21, description = ": InvalidHMIResponse_method_IsMissed"},
	{caseID = 22, description = ": InvalidHMIResponse_method_IsNotValid"},
	{caseID = 23, description = ": InvalidHMIResponse_method_IsOtherResponse"},
	{caseID = 24, description = ": InvalidHMIResponse_method_IsEmpty"},
	{caseID = 25, description = ": InvalidHMIResponse_method_IsWrongType"},
	{caseID = 26, description = ": InvalidHMIResponse_method_IsInvalidCharacter_Splace"},
	{caseID = 26, description = ": InvalidHMIResponse_method_IsInvalidCharacter_Tab"},
	{caseID = 26, description = ": InvalidHMIResponse_method_IsInvalidCharacter_NewLine"},
	
	-- --caseID 31-35 are used to checking "resultCode" parameter
	-- --31. IsMissed
	-- --32. IsNotExist
	-- --33. IsEmpty
	-- --34. IsWrongType
	{caseID = 31, description = ": InvalidHMIResponse_resultCode_IsMissed"},
	{caseID = 32, description = ": InvalidHMIResponse_resultCode_IsNotExist"},
	{caseID = 33, description = ": InvalidHMIResponse_resultCode_IsWrongType"},
	{caseID = 34, description = ": InvalidHMIResponse_resultCode_INVALID_DATA"},
	{caseID = 35, description = ": InvalidHMIResponse_resultCode_DATA_NOT_AVAILABLE"},
	{caseID = 36, description = ": InvalidHMIResponse_resultCode_GENERIC_ERROR"},
	
	
	--caseID 41-45 are used to checking "message" parameter
	--41. IsMissed
	--42. IsLowerBound
	--43. IsUpperBound
	--44. IsOutUpperBound
	--45. IsEmpty/IsOutLowerBound
	--46. IsWrongType
	--47. IsInvalidCharacter - \n, \t, only spaces
	--TODO: waiting for confirm from APPLINK-28100 to update list of cases below	
--	{caseID = 41, description = ": InvalidHMIResponse_message_IsMissed"},
--	{caseID = 42, description = ": InvalidHMIResponse_message_IsLowerBound"},
--	{caseID = 43, description = ": InvalidHMIResponse_message_IsUpperBound"},
--	{caseID = 44, description = ": InvalidHMIResponse_message_IsOutUpperBound"},
--	{caseID = 45, description = ": InvalidHMIResponse_message_IsEmpty_IsOutLowerBound"},
--	{caseID = 46, description = ": InvalidHMIResponse_message_IsWrongType"},
--	{caseID = 47, description = ": InvalidHMIResponse_message_IsInvalidCharacter_Tab"},
--	{caseID = 48, description = ": InvalidHMIResponse_message_IsInvalidCharacter_OnlySpaces"},
--	{caseID = 49, description = ": InvalidHMIResponse_message_IsInvalidCharacter_Newline"},
	
	
	--caseID 51-55 are used to checking "available" parameter
	--51. IsMissed
	--52. IsWrongType
	{caseID = 51, description = ": InvalidHMIResponse_available_IsMissed"},
	{caseID = 52, description = ": InvalidHMIResponse_available_IsWrongType"}
	
}

-- List all resultCodes
local allResultCodes = {
	{success = true, resultCode = "SUCCESS", 			expected_resultCode = "SUCCESS", value = 0}, --0
	{success = true, resultCode = "WARNINGS", 			expected_resultCode = "WARNINGS", value = 21}, --21
	{success = true, resultCode = "WRONG_LANGUAGE", 		expected_resultCode = "WRONG_LANGUAGE", value = 16}, --16
	{success = true, resultCode = "RETRY", 				expected_resultCode = "RETRY", value = 7}, --7
	{success = true, resultCode = "SAVED", 				expected_resultCode = "SAVED", value = 25}, --25
	
	{success = false, resultCode = "", 		expected_resultCode = "INVALID_DATA", value = 11}, --not respond
	{success = false, resultCode = "ABC", 	expected_resultCode = "INVALID_DATA", value = 11},
	
	{success = false, resultCode = "UNSUPPORTED_REQUEST", 	expected_resultCode = "UNSUPPORTED_REQUEST", value = 1}, --1
	{success = false, resultCode = "UNSUPPORTED_RESOURCE", 	expected_resultCode = "UNSUPPORTED_RESOURCE", value = 2}, --2
	{success = false, resultCode = "DISALLOWED", 			expected_resultCode = "DISALLOWED", value = 3}, --3
	{success = false, resultCode = "USER_DISALLOWED", 		expected_resultCode = "USER_DISALLOWED", value = 23}, --23
	{success = false, resultCode = "REJECTED", 				expected_resultCode = "REJECTED", value = 4}, --4
	{success = false, resultCode = "ABORTED", 				expected_resultCode = "ABORTED", value = 5}, --5
	{success = false, resultCode = "IGNORED", 				expected_resultCode = "IGNORED", value = 6}, --6
	{success = false, resultCode = "IN_USE", 				expected_resultCode = "IN_USE", value = 8}, --8
	{success = false, resultCode = "DATA_NOT_AVAILABLE", expected_resultCode = "VEHICLE_DATA_NOT_AVAILABLE", value = 9}, --9	
	{success = false, resultCode = "TIMED_OUT", 					expected_resultCode = "TIMED_OUT", value = 10}, --10
	{success = false, resultCode = "INVALID_DATA", 				expected_resultCode = "INVALID_DATA", value = 11}, --11
	{success = false, resultCode = "CHAR_LIMIT_EXCEEDED", 		expected_resultCode = "CHAR_LIMIT_EXCEEDED", value = 12}, --12
	{success = false, resultCode = "INVALID_ID", 				expected_resultCode = "INVALID_ID", value = 13}, --13
	{success = false, resultCode = "DUPLICATE_NAME", 			expected_resultCode = "DUPLICATE_NAME", value = 14}, --14
	{success = false, resultCode = "APPLICATION_NOT_REGISTERED", expected_resultCode = "APPLICATION_NOT_REGISTERED", value = 15}, --15
	{success = false, resultCode = "OUT_OF_MEMORY", 				expected_resultCode = "OUT_OF_MEMORY", value = 17}, --17
	{success = false, resultCode = "TOO_MANY_PENDING_REQUESTS", 	expected_resultCode = "TOO_MANY_PENDING_REQUESTS", value = 18}, --18
	{success = false, resultCode = "GENERIC_ERROR", 				expected_resultCode = "GENERIC_ERROR", value = 22}, --22
	{success = false, resultCode = "TRUNCATED_DATA", 			expected_resultCode = "TRUNCATED_DATA", value = 24} --24
}

local successResultCodes = {
	{success = true, resultCode = "SUCCESS", value = 0},
	{success = true, resultCode = "WARNINGS", value = 21},
	{success = true, resultCode = "WRONG_LANGUAGE", value = 16},
	{success = true, resultCode = "RETRY", value = 7},
	{success = true, resultCode = "SAVED", value = 25}							
}

local erroneousResultCodes = {				
	{success = false, resultCode = "UNSUPPORTED_REQUEST", value = 1},
	{success = false, resultCode = "UNSUPPORTED_RESOURCE", value = 2},				
	{success = false, resultCode = "DISALLOWED", value = 3},
	{success = false, resultCode = "USER_DISALLOWED", value = 23},
	{success = false, resultCode = "REJECTED", value = 4},
	{success = false, resultCode = "ABORTED", value = 5},
	{success = false, resultCode = "IGNORED", value = 6},
	{success = false, resultCode = "IN_USE", value = 8},
	{success = false, resultCode = "DATA_NOT_AVAILABLE", value = 9},	
	{success = false, resultCode = "TIMED_OUT", value = 10},
	{success = false, resultCode = "INVALID_DATA", value = 11},
	{success = false, resultCode = "CHAR_LIMIT_EXCEEDED", value = 12},
	{success = false, resultCode = "INVALID_ID", value = 13},
	{success = false, resultCode = "DUPLICATE_NAME", value = 14},
	{success = false, resultCode = "APPLICATION_NOT_REGISTERED", value = 15},
	{success = false, resultCode = "OUT_OF_MEMORY", value = 17},
	{success = false, resultCode = "TOO_MANY_PENDING_REQUESTS", value = 18},
	{success = false, resultCode = "GENERIC_ERROR", value = 22},
	{success = false, resultCode = "TRUNCATED_DATA", value = 24}
}

---------------------------------------------------------------------------------------------
-------------------------------------------Common function-----------------------------------
---------------------------------------------------------------------------------------------
function sleep(iTimeout)
	os.execute("sleep "..tonumber(iTimeout))
end

function Test:initHMI_onReady_Navi_IsReady(case)
	--critical(true)
	local function ExpectRequest(name, mandatory, params)
		xmlReporter.AddMessage(debug.getinfo(1, "n").name, tostring(name))
		local event = events.Event()
		event.level = 2
		event.matches = function(self, data) return data.method == name end
		return
		EXPECT_HMIEVENT(event, name)
		:Times(mandatory and 1 or AnyNumber())
		--TODO: waiting for confirm from APPLINK-28100 to update list of cases (HMI invalid response)
		:Do(function(_, data)
			--if ( data.method == "Navigation.IsReady" ) then
			if (name == "Navigation.IsReady") then
				
				--response { available = false }
				if (case == 1) then 
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { available = false })
					
					--*****************************************************************************************************************************
					
					--timeout + not response			
				elseif (case == 2) then
					--response nothing
					
					--*****************************************************************************************************************************
					
					--invalid responses:
				elseif (case == 3) then --MissedAllParamaters
					self.hmiConnection:Send('{}')
					
				elseif (case == 4) then --Invalid_Json
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"Navigation.IsReady", "code":0}}')	
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc";"2.0","result":{"available":true,"method":"Navigation.IsReady", "code":0}}')				
					
					--*****************************************************************************************************************************
					
					--invalid responses: caseID 11-14 are used to checking "collerationID" parameter
					--11. collerationID_IsMissed
					--12. collerationID_IsNonexistent
					--13. collerationID_IsWrongType
					--14. collerationID_IsNegative 	
					
				elseif (case == 11) then --collerationID_IsMissed
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"Navigation.IsReady", "code":0}}')
					self.hmiConnection:Send('{"jsonrpc":"2.0","result":{"available":true,"method":"Navigation.IsReady", "code":0}}')
					
				elseif (case == 12) then --collerationID_IsNonexistent
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"Navigation.IsReady", "code":0}}')
					self.hmiConnection:Send('{"id":'..tostring(data.id + 10)..',"jsonrpc":"2.0","result":{"available":true,"method":"Navigation.IsReady", "code":0}}')
					
				elseif (case == 13) then --collerationID_IsWrongType
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"Navigation.IsReady", "code":0}}')
					self.hmiConnection:Send('{"id":"'..tostring(data.id)..'","jsonrpc":"2.0","result":{"available":true,"method":"Navigation.IsReady", "code":0}}')
					
				elseif (case == 14) then --collerationID_IsNegative
					self.hmiConnection:Send('{"id":'..tostring(-1)..',"jsonrpc":"2.0","result":{"available":true,"method":"Navigation.IsReady", "code":0}}')
					
					--*****************************************************************************************************************************
					
					--invalid responses: caseID 21-27 are used to checking "method" parameter
					--21. method_IsMissed
					--22. method_IsNotValid
					--23. method_IsOtherResponse
					--24. method_IsEmpty
					--25. method_IsWrongType
					--26. method_IsInvalidCharacter_Newline
					--27. method_IsInvalidCharacter_OnlySpaces
					--28. method_IsInvalidCharacter_Tab
					
				elseif (case == 21) then --method_IsMissed
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"Navigation.IsReady", "code":0}}')
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"code":0}}')
					
				elseif (case == 22) then --method_IsNotValid
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"Navigation.IsReady", "code":0}}')
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"Navigation.IsRea", "code":0}}')				
					
				elseif (case == 23) then --method_IsOtherResponse
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"Navigation.IsReady", "code":0}}')
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"UI.IsReady", "code":0}}')			
					
				elseif (case == 24) then --method_IsEmpty
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"Navigation.IsReady", "code":0}}')
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"", "code":0}}')							 
					
				elseif (case == 25) then --method_IsWrongType
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"Navigation.IsReady", "code":0}}')
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":123456789, "code":0}}')
					
				elseif (case == 26) then --method_IsInvalidCharacter_Newline
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"Navigation.IsReady", "code":0}}')
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"Navigation.IsR\neady", "code":0}}')
					
				elseif (case == 27) then --method_IsInvalidCharacter_OnlySpaces
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"Navigation.IsReady", "code":0}}')
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":" ", "code":0}}')
					
				elseif (case == 28) then --method_IsInvalidCharacter_Tab
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"Navigation.IsReady", "code":0}}')
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"Navigation.IsRe\tady", "code":0}}')		
					
					--*****************************************************************************************************************************
					
					--invalid responses: caseID 31-35 are used to checking "resultCode" parameter
					--31. resultCode_IsMissed
					--32. resultCode_IsNotExist
					--33. resultCode_IsWrongType
					--34. resultCode_INVALID_DATA (code = 11)
					--35. resultCode_DATA_NOT_AVAILABLE (code = 9)
					--36. resultCode_GENERIC_ERROR (code = 22)
					
				elseif (case == 31) then --resultCode_IsMissed
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"Navigation.IsReady", "code":0}}')
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"Navigation.IsReady"}}')
					
				elseif (case == 32) then --resultCode_IsNotExist
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"Navigation.IsReady", "code":0}}')
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"Navigation.IsReady", "code":123}}')
					
				elseif (case == 33) then --resultCode_IsWrongType
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"Navigation.IsReady", "code":0}}')
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"Navigation.IsReady", "code":"0"}}')
					
				elseif (case == 34) then --resultCode_INVALID_DATA
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"Navigation.IsReady", "code":0}}')
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"Navigation.IsReady", "code":11}}')
					
				elseif (case == 35) then --resultCode_DATA_NOT_AVAILABLE
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"Navigation.IsReady", "code":0}}')
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"Navigation.IsReady", "code":9}}')
					
				elseif (case == 36) then --resultCode_GENERIC_ERROR
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"Navigation.IsReady", "code":0}}')
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"Navigation.IsReady", "code":22}}')
					
					
					--*****************************************************************************************************************************
					
					--invalid responses: caseID 41-45 are used to checking "message" parameter
					--41. message_IsMissed
					--42. message_IsLowerBound
					--43. message_IsUpperBound
					--44. message_IsOutUpperBound
					--45. message_IsEmpty_IsOutLowerBound
					--46. message_IsWrongType
					--47. message_IsInvalidCharacter_Tab
					--48. message_IsInvalidCharacter_OnlySpaces
					--49. message_IsInvalidCharacter_Newline
					--TODO: waiting for confirm from APPLINK-28100 to update list of cases below						
				-- elseif (case == 41) then --message_IsMissed
					----self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"Navigation.IsReady"}, "message":"The data sent is invalid","code":11}}') --INVALID_DATA
					-- self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"Navigation.IsReady"}, "code":11}}')
					
				-- elseif (case == 42) then --message_IsLowerBound
					-- local messageValue = "a"
					----self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"Navigation.IsReady"}, "message":"The data sent is invalid","code":11}}') --INVALID_DATA
					-- self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"Navigation.IsReady"}, "message":"' .. messageValue ..'","code":11}}')
					
				-- elseif (case == 43) then --message_IsUpperBound
					-- local messageValue = string.rep("a", 1000)
					----self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"Navigation.IsReady"}, "message":"The data sent is invalid","code":11}}') --INVALID_DATA
					-- self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"Navigation.IsReady"}, "message":"' .. messageValue ..'","code":11}}')
					
				-- elseif (case == 44) then --message_IsOutUpperBound
					-- local messageValue = string.rep("a", 1001)
					----self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"Navigation.IsReady"}, "message":"The data sent is invalid","code":11}}') --INVALID_DATA
					-- self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"Navigation.IsReady"}, "message":"' .. messageValue ..'","code":11}}')
					
				-- elseif (case == 45) then --message_IsEmpty_IsOutLowerBound
					----self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"Navigation.IsReady"}, "message":"The data sent is invalid","code":11}}') --INVALID_DATA
					-- self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"Navigation.IsReady"}, "message":"","code":11}}')
					
				-- elseif (case == 46) then --message_IsWrongType
					----self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"Navigation.IsReady"}, "message":"The data sent is invalid","code":11}}') --INVALID_DATA
					-- self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"Navigation.IsReady"}, "message":123,"code":11}}')
					
				-- elseif (case == 47) then --message_IsInvalidCharacter_Tab
					----self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"Navigation.IsReady"}, "message":"The data sent is invalid","code":11}}') --INVALID_DATA
					-- self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"Navigation.IsReady"}, "message":"a\tb","code":11}}')
					
				-- elseif (case == 48) then --message_IsInvalidCharacter_OnlySpaces
					----self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"Navigation.IsReady"}, "message":"The data sent is invalid","code":11}}') --INVALID_DATA
					-- self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"Navigation.IsReady"}, "message":" ","code":11}}')
					
				-- elseif (case == 49) then --message_IsInvalidCharacter_Newline
					----self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"Navigation.IsReady"}, "message":"The data sent is invalid","code":11}}') --INVALID_DATA
					-- self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"Navigation.IsReady"}, "message":"a\n\b","code":11}}')
					
					--*****************************************************************************************************************************
					
					--invalid responses: caseID 51-55 are used to checking "available" parameter
					--51. available_IsMissed
					--52. available_IsWrongType
					
				elseif (case == 51) then --available_IsMissed
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"Navigation.IsReady", "code":0}}')
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"Navigation.IsReady", "code":"0"}}')
					
				elseif (case == 52) then --available_IsWrongType
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":true,"method":"Navigation.IsReady", "code":0}}')
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"available":"true","method":"Navigation.IsReady", "code":"0"}}')
				else
					print("***************************Error: Navigation.IsReady: Input value is not correct ***************************")
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
			button_capability("SEEKLEFT"),
			button_capability("SEEKRIGHT"),
			button_capability("TUNEUP"),
			button_capability("TUNEDOWN")
		},
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

local function StopStartSDL_StartMobileSession(caseid)
	--Stop SDL
	Test[APIName .."_Precondition_StopSDL"] = function(self)
		StopSDL()
	end
	
	--Start SDL
	Test[APIName.."_Precondition_StartSDL"] = function(self)
		StartSDL(config.pathToSDL, config.ExitOnCrash)
	end
	
	--InitHMI
	Test[APIName.."_Precondition_InitHMI"] = function(self)
		self:initHMI()
	end
	
	Test[APIName .."_initHMI_OnReady"] = function(self)
		self:initHMI_onReady_Navi_IsReady(caseid)	
	end
	
	if (caseid > 1) then -- Wait for timeout (HMI does not response Navigation.IsReady)
		Test[APIName .."_DefaultTimeout"] = function(self)
			sleep(DefaultTimeout)
		end
	end	
	
	--ConnectMobile
	Test[APIName .."_ConnectMobile"] = function(self)
		self:connectMobile()
	end
	--StartSession
	Test[APIName .."_StartSession"] = function(self)
		self.mobileSession= mobile_session.MobileSession(
		self,
		self.mobileConnection)
		self.mobileSession:StartService(7)
	end
	
end

local function UpdatePolicy()
	
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
	local PermissionLinesForBase4 = PermissionForSendLocation..PermissionForShowConstantTBT..PermissionForAlertManeuver..PermissionForUpdateTurnList..PermissionForGetWayPoints..PermissionForSubscribeWayPoints..PermissionForUnsubscribeWayPoints..PermissionForOnWayPointChange..PermissionForOnTBTClientState
	local PTName = testCasesForPolicyTable:createPolicyTableFile_temp(PermissionLinesForBase4, nil, nil, {"SendLocation","ShowConstantTBT","AlertManeuver","UpdateTurnList","GetWayPoints","SubscribeWayPoints","UnsubscribeWayPoints","OnWayPointChange","OnTBTClientState"})	
	-- TODO: Remove after implementation policy update
	--testCasesForPolicyTable:updatePolicy(PTName)	
	testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt(PTName)
end

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

commonFunctions:newTestCasesGroup("Preconditions")

--make backup copy of file sdl_preloaded_pt.json
commonPreconditions:BackupFile("sdl_preloaded_pt.json")

-- Precondition: replace preloaded file with new one
--os.execute('cp ./files/ptu_general.json ' .. tostring(config.pathToSDL) .. "sdl_preloaded_pt.json")

UpdatePolicy()


-- Precondition: remove policy table and log files
commonSteps:DeleteLogsFileAndPolicyTable()


-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK I----------------------------------------
--------------------------------Check normal cases of Mobile request---------------------------
-----------------------------------------------------------------------------------------------

-- Not applicable.



----------------------------------------------------------------------------------------------
----------------------------------------TEST BLOCK II-----------------------------------------
-----------------------------Check special cases of Mobile request----------------------------
----------------------------------------------------------------------------------------------

-- Not applicable.

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK III--------------------------------------
----------------------------------Check normal cases of HMI response---------------------------
-----------------------------------------------------------------------------------------------

-- Not applicable.

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK IV----------------------------------------
------------------------------Check special cases of HMI response-----------------------------
----------------------------------------------------------------------------------------------


--Begin of SpecialHMIResponse.2.2
-- Functional Requirement: APPLINK-25185 [Navigation Interface] SDL behavior in case HMI does not respond to Navi.IsReady_request
-- Description:
-- In case
-- SDL does NOT receive Navi.IsReady_response during <DefaultTimeout> from HMI 
-- and mobile app sends any Navi-related RPC
-- SDL must:
-- transfer this Navi-related RPC to HMI
-- respond with <received_resultCode_from_HMI> to mobile app
-- a. SDL must respond with "GENERIC_ERROR, success:false" in case HMI does NOT respond during <DefaultTimeout> at least to one component of RPC -> per APPLINK-17008
-- b. SDL behavior in case Navigation interface is not supported and navigation app registers at system
-- c. The same SDL behavior is applicable in case HMI sends invalid by any reason IsReady_response
-- Note: Incase AlertManeuver, refer to APPLINK-25117 for split RPC requirement (according to: APPLINK-27829)

local function sequence_check_Result_Code_single_RPC(successValue, resultCodeValue, expected_resultCodeValue)
	------------1. SendLocation		
	Test[APIName .. "_SendLocation_" .. resultCodeValue] = function(self)
		local HMI_result
		for i = 1, #allResultCodes do
			if(resultCodeValue == allResultCodes[i].resultCode) then
				HMI_result = allResultCodes[i].value
			end
		end

		local cid = self.mobileSession:SendRPC("SendLocation",
		{ 
			longitudeDegrees = 1.1,
			latitudeDegrees = 1.1
		})
		
		EXPECT_HMICALL("Navigation.SendLocation")
		:Do(function(_,data)
			if (successValue == true) then
				if(HMI_result == nil) then 
					self.hmiConnection:SendResponse(data.id, data.method, resultCodeValue, {})
				else
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"'..data.method..'","code":'..HMI_result..'}}')
				end					
				EXPECT_RESPONSE(cid, { success = true, resultCode = expected_resultCodeValue })
				:Timeout(TimeoutValue)	
			else
				if(HMI_result == nil) then 
					self.hmiConnection:SendError(data.id, data.method, resultCodeValue, "Navigation error message")
				else
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"message":"Navigation error message", "method":"'..data.method..'","code":'..HMI_result..'}}')
				end
				EXPECT_RESPONSE(cid, { success = false, resultCode = expected_resultCodeValue, info = "Navigation error message" })
				:Timeout(TimeoutValue)						
			end
		end)				
		
	end
	
	------------2. ShowConstantTBT
	Test[APIName .. "_ShowConstantTBT_" .. resultCodeValue] = function(self)
		local HMI_result
		for i = 1, #allResultCodes do
			if(resultCodeValue == allResultCodes[i].resultCode) then
				HMI_result = allResultCodes[i].value
			end
		end
		local cid = self.mobileSession:SendRPC("ShowConstantTBT",
		{ 
			navigationText1 = "NavigationText1"
		})
		
		EXPECT_HMICALL("Navigation.ShowConstantTBT")
		:Do(function(_,data)
			if (successValue == true) then
				if(HMI_result == nil) then 
					self.hmiConnection:SendResponse(data.id, data.method, resultCodeValue, {})
				else
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"'..data.method..'","code":'..HMI_result..'}}')
				end
				EXPECT_RESPONSE(cid, { success = true, resultCode = expected_resultCodeValue })
				:Timeout(TimeoutValue)	
			else
				if(HMI_result == nil) then 
					self.hmiConnection:SendError(data.id, data.method, resultCodeValue, "Navigation error message")
				else
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"message": "Navigation error message", "method":"'..data.method..'","code":'..HMI_result..'}}')
				end
				EXPECT_RESPONSE(cid, { success = false, resultCode = expected_resultCodeValue, info = "Navigation error message" })
				:Timeout(TimeoutValue)						
			end
		end)
	end
	
	------------4. UpdateTurnList
	Test[APIName .. "_UpdateTurnList_" .. resultCodeValue] = function(self)
		local HMI_result
		for i = 1, #allResultCodes do
			if(resultCodeValue == allResultCodes[i].resultCode) then
				HMI_result = allResultCodes[i].value
			end
		end
		local cid = self.mobileSession:SendRPC("UpdateTurnList",
		{
			--{
				turnList =
				{
					{
						navigationText ="Text",
						turnIcon =
						{
							value ="icon.png",
							imageType ="DYNAMIC",
						}
					}
				},
				softButtons =
				{
					{
						type ="BOTH",
						text ="Close",
						image =
						{
							value ="icon.png",
							imageType ="DYNAMIC",
						},
						isHighlighted = true,
						softButtonID = 111,
						systemAction ="DEFAULT_ACTION",
					}
				}
			--}
		})
		
		EXPECT_HMICALL("Navigation.UpdateTurnList")
		:Do(function(_,data)
			if (successValue == true) then
				if(HMI_result == nil) then 
					self.hmiConnection:SendResponse(data.id, data.method, resultCodeValue, {})
				else
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{ "method":"'..data.method..'","code":'..HMI_result..'}}')
				end
				EXPECT_RESPONSE(cid, { success = true, resultCode = expected_resultCodeValue })
				:Timeout(TimeoutValue)	
			else
				if(HMI_result == nil) then 
					self.hmiConnection:SendError(data.id, data.method, resultCodeValue, "Navigation error message")
				else
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"message":"Navigation error message", "method":"'..data.method..'","code":'..HMI_result..'}}')
				end
				EXPECT_RESPONSE(cid, { success = false, resultCode = expected_resultCodeValue, info = "Navigation error message" })
				:Timeout(TimeoutValue)						
			end
		end)
	end
	
	------------5. GetWayPoints
	Test[APIName .. "_GetWayPoints_" .. resultCodeValue] = function(self)
		local HMI_result
		for i = 1, #allResultCodes do
			if(resultCodeValue == allResultCodes[i].resultCode) then
				HMI_result = allResultCodes[i].value
			end
		end
		local cid = self.mobileSession:SendRPC("GetWayPoints",
		{
			wayPointType = "ALL"
		})

		local response ={}
		response["wayPoints"] =
		{{

			coordinate =
			{
				latitudeDegrees = 1.1,
				longitudeDegrees = 1.1
			},
			locationName = "Hotel",
			addressLines =	"Hotel 5 stars",
			locationDescription = "VIP Hotel",
			phoneNumber = "Phone39300434",
			locationImage =
			{
				value ="icon.png",
				imageType ="DYNAMIC",
			},
			searchAddress =
			{
				countryName = "countryName",
				countryCode = "countryCode",
				postalCode = "postalCode",
				administrativeArea = "administrativeArea",
				subAdministrativeArea = "subAdministrativeArea",
				locality = "locality",
				subLocality = "subLocality",
				thoroughfare = "thoroughfare",
				subThoroughfare = "subThoroughfare"
			}
		}}
		
		EXPECT_HMICALL("Navigation.GetWayPoints")
		:Do(function(_,data)
			if (successValue == true) then
				if(HMI_result == nil) then 
					self.hmiConnection:SendResponse(data.id, data.method, resultCodeValue, response)
				else
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"'..data.method..'","code":'..HMI_result..'}}')
				end
				EXPECT_RESPONSE(cid, { success = true, resultCode = expected_resultCodeValue, response })
				:Timeout(TimeoutValue)	
			else
				if(HMI_result == nil) then 
					self.hmiConnection:SendError(data.id, data.method, resultCodeValue, "Navigation error message")
				else
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"message":"Navigation error message", "method":"'..data.method..'","code":'..HMI_result..'}}')
				end
				EXPECT_RESPONSE(cid, { success = false, resultCode = expected_resultCodeValue, info = "Navigation error message" })
				:Timeout(TimeoutValue)						
			end
		end)
	end
	
	------------6. SubscribeWayPoints
	Test[APIName .. "_SubscribeWayPoints_" .. resultCodeValue] = function(self)
		local HMI_result
		for i = 1, #allResultCodes do
			if(resultCodeValue == allResultCodes[i].resultCode) then
				HMI_result = allResultCodes[i].value
			end
		end
		local cid = self.mobileSession:SendRPC("SubscribeWayPoints",
		{
		})
		
		EXPECT_HMICALL("Navigation.SubscribeWayPoints")
		:Do(function(_,data)
			if (successValue == true) then
				if(HMI_result == nil) then 
					self.hmiConnection:SendResponse(data.id, data.method, resultCodeValue, {})
				else
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"'..data.method..'","code":'..HMI_result..'}}')
				end

				EXPECT_RESPONSE(cid, { success = true, resultCode = expected_resultCodeValue })
				:Timeout(TimeoutValue)

				EXPECT_NOTIFICATION("OnHashChange")
				:Times(1)
				:Timeout(TimeoutValue)				
		
			else
				if(HMI_result == nil) then 
					self.hmiConnection:SendError(data.id, data.method, resultCodeValue, "Navigation error message")
				else
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"message":"Navigation error message", "method":"'..data.method..'","code":'..HMI_result..'}}')
				end

				EXPECT_RESPONSE(cid, { success = false, resultCode = expected_resultCodeValue, info = "Navigation error message" })
				:Timeout(TimeoutValue)						

				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
				:Timeout(TimeoutValue)				
			end
		end)
	end	
	------------Additional check: HMI send OnWayPointChange notification
	if (resultCodeValue == "SUCCESS") then
		Test[APIName .. "_Additional_Check: OnWayPointChange"] = function(self)
			local notification = 
			{
				wayPoints =
				{
					{
						coordinate={
							latitudeDegrees = -90,
							longitudeDegrees = -180
						},
						locationName="Ho Chi Minh",
						addressLines={"182 Le Dai Hanh"},
						locationDescription="Toa nha Flemington",
						phoneNumber="1231414",
						searchAddress={
							countryName="aaa",
							countryCode="084",
							postalCode="test",
							administrativeArea="aa",
							subAdministrativeArea="a",
							locality="a",
							subLocality="a",
							thoroughfare="a",
							subThoroughfare="a"
						}
					}
				}
			}
			self.hmiConnection:SendNotification("Navigation.OnWayPointChange", notification)	 		
			
			--mobile side: expected response
			EXPECT_NOTIFICATION("OnWayPointChange", notification)	
		end
	end
	--Postcondition	
	if (successValue == true) then 
		Test[APIName .. "_Postcondition_UnsubscribeWayPoints_SUCCESS"] = function(self)
			local cid1 = self.mobileSession:SendRPC("UnsubscribeWayPoints",{})
			EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
			:Do(function(_,data)
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			EXPECT_RESPONSE(cid1, { success = true, resultCode = "SUCCESS" })
			:Timeout(TimeoutValue)
			
			EXPECT_NOTIFICATION("OnHashChange")
			:Times(1)				
			:Timeout(TimeoutValue)			
		end
	end
	--end Postcondition		
	
	------------7. UnsubscribeWayPoints
	--Precondition	
	Test[APIName .. "_Precondition_SubscribeWayPoints_SUCCESS"] = function(self)
		local cid1 = self.mobileSession:SendRPC("SubscribeWayPoints",{})
		EXPECT_HMICALL("Navigation.SubscribeWayPoints")
		:Do(function(_,data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		EXPECT_RESPONSE(cid1, { success = true, resultCode = "SUCCESS" })
		:Timeout(TimeoutValue)
		
		EXPECT_NOTIFICATION("OnHashChange")
		:Times(1)				
		:Timeout(TimeoutValue)
	end
	--end Precondition	
	Test[APIName .. "_UnsubscribeWayPoints_" .. resultCodeValue] = function(self)
		local HMI_result
		for i = 1, #allResultCodes do
			if(resultCodeValue == allResultCodes[i].resultCode) then
				HMI_result = allResultCodes[i].value
			end
		end
		local cid = self.mobileSession:SendRPC("UnsubscribeWayPoints",
		{
		})
		
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
		:Do(function(_,data)
			if (successValue == true) then
				if(HMI_result == nil) then 
					self.hmiConnection:SendResponse(data.id, data.method, resultCodeValue, {})
				else
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"'..data.method..'","code":'..HMI_result..'}}')
				end

				EXPECT_RESPONSE(cid, { success = true, resultCode = expected_resultCodeValue })
				:Timeout(TimeoutValue)

				EXPECT_NOTIFICATION("OnHashChange")
				:Times(1)				
				:Timeout(TimeoutValue)				
			else
				if(HMI_result == nil) then 
					self.hmiConnection:SendError(data.id, data.method, resultCodeValue, "Navigation error message")
				else
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"message":"Navigation error message", "method":"'..data.method..'","code":'..HMI_result..'}}')
				end

				EXPECT_RESPONSE(cid, { success = false, resultCode = expected_resultCodeValue, info = "Navigation error message" })
				:Timeout(TimeoutValue)

				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
				:Timeout(TimeoutValue)				
			end
		end)
		
	end
	--Postcondition	
	if (successValue ~= true) then 
		Test[APIName .. "_Postcondition_UnsubscribeWayPoints_SUCCESS"] = function(self)
			local cid1 = self.mobileSession:SendRPC("UnsubscribeWayPoints",{})
			EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
			:Do(function(_,data)
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			EXPECT_RESPONSE(cid1, { success = true, resultCode = "SUCCESS" })
			:Timeout(TimeoutValue)
			
			EXPECT_NOTIFICATION("OnHashChange")
			:Times(1)				
			:Timeout(TimeoutValue)			
		end
	end
	--end Postcondition		
	
	------------8. StartStream
	--TODO: this code can make error for others because of APPLINK-22717. Currently in the suite should check it only with SUCCESS result code. For other result codes, please check separately.
	Test[APIName .. "_StartStream_" .. resultCodeValue] = function(self)
		local HMI_result
		for i = 1, #allResultCodes do
			if(resultCodeValue == allResultCodes[i].resultCode) then
				HMI_result = allResultCodes[i].value
			end
		end
		if(resultCodeValue == "SUCCESS") then
			self.mobileSession:StartService(11)
		
			EXPECT_HMICALL("Navigation.StartStream")
			:Do(function(_,data)
				if(HMI_result == nil) then 
					self.hmiConnection:SendResponse(data.id, data.method, resultCodeValue, {})
				else
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"'..data.method..'","code":'..HMI_result..'}}')
				end
			end)
			
			self.mobileSession:StartStreaming(11,"files/Wildlife.wmv")		
			
			EXPECT_HMINOTIFICATION("Navigation.OnVideoDataStreaming")
			:Times(2) --1 for available = true and 1 for available = false
			:Timeout(20000)	
		--TODO: open below code when APPLINK-22717 is closed or want to check this testcase separately		
		-- else
			-- self.mobileSession:StartService(11)
			
			-- EXPECT_HMICALL("Navigation.StartStream")
			-- :Do(function(_,data)
				-- if (successValue == true) then
					-- self.hmiConnection:SendResponse(data.id, data.method, resultCodeValue, {})
				-- else
					-- self.hmiConnection:SendError(data.id, data.method, resultCodeValue, "Navigation error message")
				-- end
			-- end)
			-- :Times(3)			

			-- EXPECT_HMINOTIFICATION("Navigation.OnVideoDataStreaming") --available = false
			-- :Timeout(20000)	
			
			-- EXPECT_HMICALL("Navigation.StopStream")
			-- :Timeout(20000)			
		 end
		
		commonTestCases:DelayedExp(4000)
	end	
	--Postcondition
	if(resultCodeValue == "SUCCESS") then	
		Test[APIName .. "Postcondition_StopStream_" .. resultCodeValue] = function(self)		
			self.mobileSession:StopService(11)
			
			EXPECT_HMICALL("Navigation.StopStream")
			:Do(function(_,data)
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
		end
	end
	--Postcondition	
	------------9. StopStream
	--Precondition
	Test[APIName .. "_Precondition_StartStream_SUCCESS"] = function(self)		
		self.mobileSession:StartService(11)
		EXPECT_HMICALL("Navigation.StartStream")
		:Do(function(_,data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)			
		commonTestCases:DelayedExp(2000)
	end
	--end Precondition		
	Test[APIName .. "_StopStream_" .. resultCodeValue] = function(self)		
		local HMI_result
		for i = 1, #allResultCodes do
			if(resultCodeValue == allResultCodes[i].resultCode) then
				HMI_result = allResultCodes[i].value
			end
		end
		commonTestCases:DelayedExp(TimeDelay)
 
		xmlReporter.AddMessage("StopService", 11)
		local stopService =
			self.mobileSession:Send(
			{
				frameType = 0,
				serviceType = 11,
				frameInfo = 4,
				sessionId = self.mobileSession.sessionId,
				binaryData = self.mobileSession.hashCode,
			})
			

		local event = events.Event()
		-- prepare event to expect
		event.matches = function(_, data)
			return data.frameType == 0 and
			data.serviceType == 11 and
			(data.sessionId == self.mobileSession.sessionId) and
			(data.frameInfo == 5 or -- End Service ACK
			data.frameInfo == 6) -- End Service NACK
		end

		local ret = self.mobileSession:ExpectEvent(event, "EndService ACK")
		:ValidIf(function(s, data)
			if data.frameInfo == 5 then -- End Service ACK
				print ("\27[32m End Service ACK received \27[0m ")				
				return true
			elseif data.frameInfo == 6 then -- End Service NACK
				print ("\27[32m End Service NACK received \27[0m ")			
				return false 
			else 
				return false 
			end
		end)
		
		EXPECT_HMICALL("Navigation.StopStream")
		:Do(function(_,data)
			if (successValue == true) then
				if(HMI_result == nil) then 
					self.hmiConnection:SendResponse(data.id, data.method, resultCodeValue, {})
				else
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"'..data.method..'","code":'..HMI_result..'}}')
				end
			else
				if(HMI_result == nil) then 
					self.hmiConnection:SendError(data.id, data.method, resultCodeValue, "Navigation error message")
				else
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"message":"Navigation error message", "method":"'..data.method..'","code":'..HMI_result..'}}')
				end
			end
		end)
	end	
	
	------------10. StartAudioStream
	--TODO: this code can make error for others because of APPLINK-22717. Currently in the suite should check it only with SUCCESS result code. For unsuccess result codes, please check separately.
	Test[APIName .. "_StartAudioStream_" .. resultCodeValue] = function(self)
			
		if(resultCodeValue == "SUCCESS") then
			self.mobileSession:StartService(10)

			EXPECT_HMICALL("Navigation.StartAudioStream")
			:Do(function(_,data)
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
				
			self.mobileSession:StartStreaming(10,"files/Kalimba.mp3")
				
			EXPECT_HMINOTIFICATION("Navigation.OnAudioDataStreaming")
			:Times(2) --1 for available = true and 1 for available = false
			:Timeout(20000)	
		--TODO: open below code when APPLINK-22717 is closed or want to check this testcase separately				
		-- else
			-- self.mobileSession:StartService(10)
			
			-- EXPECT_HMICALL("Navigation.StartAudioStream")
			-- :Do(function(_,data)
				-- if (successValue == true) then
					-- self.hmiConnection:SendResponse(data.id, data.method, resultCodeValue, {})
				-- else
					-- self.hmiConnection:SendError(data.id, data.method, resultCodeValue, "Navigation error message")
				-- end
			-- end)
			-- :Times(3)
			
			-- EXPECT_HMINOTIFICATION("Navigation.OnAudioDataStreaming") --available = false
			-- :Timeout(20000)	

			-- EXPECT_HMICALL("Navigation.StopAudioStream")
			-- :Timeout(20000)			
		 end
			
		commonTestCases:DelayedExp(4000)
	end	
	--Postcondition
	if(resultCodeValue == "SUCCESS") then	
		Test[APIName .. "Postcondition_StopAudioStream_" .. resultCodeValue] = function(self)		
			self.mobileSession:StopService(10)
			
			EXPECT_HMICALL("Navigation.StopAudioStream")
			:Do(function(_,data)
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			
		end
	end
	--Postcondition
	
	------------11. StopAudioStream
	--Precondition
	Test[APIName .. "_Precondition_StartAudioStream_SUCCESS"] = function(self)
		self.mobileSession:StartService(10)
		EXPECT_HMICALL("Navigation.StartAudioStream")
		:Do(function(_,data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)			
		commonTestCases:DelayedExp(2000)
	end
	--end Precondition
	Test[APIName .. "_StopAudioStream_" .. resultCodeValue] = function(self)	
		local HMI_result
		for i = 1, #allResultCodes do
			if(resultCodeValue == allResultCodes[i].resultCode) then
				HMI_result = allResultCodes[i].value
			end
		end			
		commonTestCases:DelayedExp(TimeDelay)
		
		xmlReporter.AddMessage("StopService", 10)
		local stopService =
			self.mobileSession:Send(
			{
				frameType = 0,
				serviceType = 10,
				frameInfo = 4,
				sessionId = self.mobileSession.sessionId,
				binaryData = self.mobileSession.hashCode,
			})
			
		
		local event = events.Event()
		-- prepare event to expect
		event.matches = function(_, data)
			return data.frameType == 0 and
			data.serviceType == 10 and
			(data.sessionId == self.mobileSession.sessionId) and
			(data.frameInfo == 5 or -- End Service ACK
			data.frameInfo == 6) -- End Service NACK
		end

		local ret = self.mobileSession:ExpectEvent(event, "EndService ACK")
		:ValidIf(function(s, data)
			if data.frameInfo == 5 then -- End Service ACK
				print ("\27[32m End Service ACK received \27[0m ")				
				return true
			elseif data.frameInfo == 6 then -- End Service NACK
				print ("\27[32m End Service NACK received \27[0m ")			
				return false 
			else 
				return false 
			end
		end)
		
		EXPECT_HMICALL("Navigation.StopAudioStream")
		:Do(function(_,data)
			if (successValue == true) then
				if(HMI_result == nil) then 
					self.hmiConnection:SendResponse(data.id, data.method, resultCodeValue, {})	
				else
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"'..data.method..'","code":'..HMI_result..'}}')		
				end
			else
				if(HMI_result == nil) then 
					self.hmiConnection:SendError(data.id, data.method, resultCodeValue, "Navigation error message")		
				else
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"message":"Navigation error message", "method":"'..data.method..'","code":'..HMI_result..'}}')
				end
			end
		end)
	end			
	
	------------Additional check: HMI send OnTBTClientState notification
	if (resultCodeValue == "SUCCESS") then
		Test[APIName .. "_Additional_Check: OnTBTClientState"] = function(self)
			
			--hmi side: send request Navigation.OnTBTClientState 
			self.hmiConnection:SendNotification("Navigation.OnTBTClientState", {state = "ROUTE_UPDATE_REQUEST"})
			
			--mobile side: expect OnTBTClientState notification
			EXPECT_NOTIFICATION("OnTBTClientState", {state = "ROUTE_UPDATE_REQUEST"})
		end
	end
	
	------------		
end


--for i= 2, #TestCases do 
for i= 2, 2 do --TODO: Remove this row and use the row above after APPLINK-25898 closed. Currently, replace numbers "2" by value of TestCases.caseID you want to test.
	commonFunctions:newTestCasesGroup(APIName .. "_Test_suite: " .. TestCases[i].description)
	
	StopStartSDL_StartMobileSession(TestCases[i].caseID)
	commonSteps:RegisterAppInterface(APIName .. TestCases[i].description .. "_RegisterAppInterface")
	commonSteps:ActivationAppGenivi(_,APIName .. TestCases[i].description .. "_ActivationApp")
	commonSteps:PutFile("Precondition_PutFile", "icon.png")
	
	for j=1, #allResultCodes do
		commonFunctions:newTestCasesGroup(APIName .. TestCases[i].description .. " (" .. allResultCodes[j].resultCode ..")")
		sequence_check_Result_Code_single_RPC(allResultCodes[j].success, allResultCodes[j].resultCode, allResultCodes[j].expected_resultCode)
	end
	
	commonSteps:UnregisterApplication(APIName .. TestCases[i].description .. "_UnregisterAppInterface")	
end
--End of SpecialHMIResponse.2.2


-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK V----------------------------------------
-------------------------------------Checks All Result Codes-----------------------------------
-----------------------------------------------------------------------------------------------

--Not applicable.



----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VI----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------

--Not applicable.



----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VII---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------

-- Not applicable.


---------------------------------------------------------------------------------------------
-------------------------------------------Postcondition-------------------------------------
---------------------------------------------------------------------------------------------

--Print new line to separate Postconditions
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()
Test["Stop_SDL"] = function(self)
	-- TODO: should replace below code after APPLINK-25898 closed.
	--StopSDL()
	os.execute("kill -9 $(ps aux | grep -e smartDeviceLinkCore | awk '{print$2}')")
end
