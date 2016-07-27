--This script contains all test cases to array String Parameter
--How to use:
	--1. local arrayStringParameterInResponse = require('user_modules/shared_testcases/testCasesForArrayStringParameterInResponse')
	--2. arrayStringParameterInResponse:verify_Array_String_Parameter(Response, Parameter, Boundary,  ElementBoundary, Mandatory)
---------------------------------------------------------------------------------------------

local testCasesForArrayStringParameterInResponse = {}
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local stringParameterInResponse = require('user_modules/shared_testcases/testCasesForStringParameterInResponse')

---------------------------------------------------------------------------------------------
--Test cases to verify Array String Parameter
---------------------------------------------------------------------------------------------
--List of test cases for Array String type Parameter:
	--1. IsMissed
	--2. IsLowerBound
	--3. IsUpperBound
	--4. OutLowerBound/IsEmpty
	--5. OutUpperBound
	--6. IsWrongType
	--7. IsInvalidCharacters
---------------------------------------------------------------------------------------------


--Contains all test cases
function testCasesForArrayStringParameterInResponse:verify_Array_Struct_Parameter(Response, Parameter, Boundary,  Struct, Mandatory)


		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup(Parameter)	
		
		--1. IsMissed
		local resultCode
		if Mandatory == true then
			resultCode = "GENERIC_ERROR"
		else
			resultCode = "SUCCESS"
		end
		--print ("verify_Array_String_Parameter__________")
		--print_table (Response)
		commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsMissed", nil, resultCode)		
		
		--2. IsLowerBound
		local verification = "IsLowerBound"
		if Boundary[1] > 0 then
			verification = "IsLowerBound_IsEmpty"
			local value = commonFunctions:createArrayStruct(Boundary[1], Struct)
			commonFunctions:TestCaseForResponse(self, Response, Parameter, verification, value, "SUCCESS")
		else
			-- Boundary = 0 ==> Is covered by _element_IsMissed_
		end
		
		
		
		--3. IsUpperBound
		local value = commonFunctions:createArrayStruct(Boundary[2], Struct)
		commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsUpperBound", value, "SUCCESS")
		--print_table (Struct)
		
		--4. IsOutLowerBound/IsEmpty
		if Boundary[1] ==1 then
			local value = commonFunctions:createArrayStruct(Boundary[1]-1, Struct)
			commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsOutLowerBound_IsEmpty", value, "GENERIC_ERROR")
		
		elseif Boundary[1] >1 then
			local value = commonFunctions:createArrayStruct(Boundary[1]-1, Struct)
			commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsOutLowerBound", value, "GENERIC_ERROR")
			
			commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsEmpty", {}, "GENERIC_ERROR")			
		else
			--minsize = 0, no check out lower bound		
		end
		
		--5. IsOutUpperBound
		local value = commonFunctions:createArrayStruct(Boundary[2]+1, Struct)
		commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsOutUpperBound", value, "GENERIC_ERROR")
		
		--6. IsWrongType
		commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsWrongDataType", 123, "GENERIC_ERROR")
		
		
		--Verify an element in array		
		TestingResponse = commonFunctions:cloneTable(Response)
		commonFunctions:setValueForParameter(TestingResponse, Parameter, {})	

		local parameter_arrayElement = commonFunctions:BuildChildParameter(Parameter, 1) -- element #1

		--stringParameterInResponse:verify_String_Parameter(TestingResponse, parameter_arrayElement, ElementBoundary, nil) --nil: not check missed element
		
		
end
---------------------------------------------------------------------------------------------

return testCasesForArrayStringParameterInResponse
