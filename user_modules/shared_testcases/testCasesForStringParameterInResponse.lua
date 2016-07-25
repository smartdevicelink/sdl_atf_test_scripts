--This script contains all test cases to verify String parameter in response
--How to use:
	--1. local stringParameterInResponse = require('user_modules/shared_testcases/testCasesForStringParameterInResponse')
	--2. stringParameterInResponse:verify_String_Parameter(Response, Parameter, Boundary, Mandatory)
---------------------------------------------------------------------------------------------


local testCasesForStringParameterInResponse = {}
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')



---------------------------------------------------------------------------------------------
--Test cases to verify String parameter in response
---------------------------------------------------------------------------------------------
--List of test cases for String type parameter:
	--1. IsMissed
	--2. IsWrongType
	--3. IsLowerBound/IsEmpty
	--4. IsOutLowerBound/IsEmpty
	--5. IsUpperBound
	--6. IsOutUpperBound
	--7. IsInvalidCharacters
	
	

--Contains all test cases with verify mandatory is false
function testCasesForStringParameterInResponse:verify_String_Parameter(Response, Parameter, Boundary, Mandatory, IsSupportedSpecialCharacters)

		local Response = commonFunctions:cloneTable(Response)	

		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup(Parameter)	
		
		--1. IsMissed
		if Mandatory == nil then
			--no check mandatory: in case string is element in array. We does not verify an element is missed. It is checked in test case checks bound of array.
		else
			
			local resultCode
			if Mandatory == true then
				resultCode = "GENERIC_ERROR"
			else
				resultCode = "SUCCESS"
			end		
			commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsMissed", nil, resultCode)	
		end
		
		--2. IsWrongDataType
		commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsWrongDataType", 123, "GENERIC_ERROR")
		
		
		--3. IsLowerBound/IsEmpty
		local verification = "IsLowerBound"
		if Boundary[1] == 0 then
			verification = "IsLowerBound_IsEmpty"
		end
		
		local value = commonFunctions:createString(Boundary[1])
		commonFunctions:TestCaseForResponse(self, Response, Parameter, verification, value, "SUCCESS")
		
		
		--4. IsOutLowerBound/IsEmpty
		local value = commonFunctions:createString(Boundary[1] - 1)
		if Boundary[1] >= 2 then
			commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsOutLowerBound", value, "GENERIC_ERROR")
		elseif Boundary[1] == 1 then		
			commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsOutLowerBound_IsEmpty", value, "GENERIC_ERROR")
		else
			--minlength = 0, no check out lower bound
		end
		
		
		--5. IsUpperBound
		local value = commonFunctions:createString(Boundary[2])
		commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsUpperBound", value, "SUCCESS")
		
		
		--6. IsOutUpperBound
		local value = commonFunctions:createString(Boundary[2] + 1)
		commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsOutUpperBound", value, "GENERIC_ERROR")
		
		-- Check special characters
		if IsSupportedSpecialCharacters == nil then
			-- do not check support special characters or not.
			print("Note: Do not check parameter supports special characters or not.")
			
		elseif IsSupportedSpecialCharacters == true then
			--7. Check support special characters
			commonFunctions:TestCaseForResponse(self, Response, Parameter, "ContainsNewLineCharacter", "a\nb", "SUCCESS")
			commonFunctions:TestCaseForResponse(self, Response, Parameter, "ContainsTabCharacter", "a\tb", "SUCCESS")
			commonFunctions:TestCaseForResponse(self, Response, Parameter, "WhiteSpacesOnly", "   ", "SUCCESS")
		else		
			--7. Check not support special characters: Special characters validation: GENERIC_ERROR response should come according to APPLINK-7687
			commonFunctions:TestCaseForResponse(self, Response, Parameter, "ContainsNewLineCharacter", "a\nb", "GENERIC_ERROR")
			commonFunctions:TestCaseForResponse(self, Response, Parameter, "ContainsTabCharacter", "a\tb", "GENERIC_ERROR")
			commonFunctions:TestCaseForResponse(self, Response, Parameter, "WhiteSpacesOnly", "   ", "GENERIC_ERROR")
		end
end


return testCasesForStringParameterInResponse