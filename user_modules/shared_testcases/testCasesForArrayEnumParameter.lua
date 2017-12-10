--This script contains all test cases for a parameter consisting of an array of enums
--How to use:
	--1. local arrayEnumParameter = require('user_modules/shared_testcases/testCasesForArrayEnumParameter')
	--2. arrayEnumParameter:verify_Array_Enum_Parameter(Request, Parameter, Boundary, ElementExistentValues, Mandatory)
---------------------------------------------------------------------------------------------

local testCasesForArrayEnumParameter = {}
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local enumerationParameter = require('user_modules/shared_testcases/testCasesForEnumerationParameter')


---------------------------------------------------------------------------------------------
--Test cases to verify Array Enum Parameter
---------------------------------------------------------------------------------------------
--List of test cases for Enum type Parameter:
	--1. IsMissed
	--2. IsLowerBound
	--3. IsUpperBound
	--4. OutLowerBound/IsEmpty
	--5. OutUpperBound
	--6. IsWrongType
	------------------------
	--7. Check an element of array Enum
	
	

--Verify array only:
	--1. IsMissed
	--2. IsLowerBound
	--3. IsUpperBound
	--4. OutLowerBound/IsEmpty
	--5. OutUpperBound
	--6. IsWrongType
function testCasesForArrayEnumParameter:verify_Array_Enum_Parameter_Only(Request, Parameter, Boundary,  ElementExistentValues, Mandatory)


		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup(Parameter)	
		
		--1. IsMissed
		local resultCode
		if Mandatory == true then
			resultCode = "INVALID_DATA"
		else
			resultCode = "SUCCESS"
		end
		
		
		commonFunctions:TestCase(self, Request, Parameter, "IsMissed", nil, resultCode)		

		local defaultEnumValue = ElementExistentValues[i]
		
		--2. IsLowerBound
		local verification = "IsLowerBound"
		if Boundary[1] > 0 then
			verification = "IsLowerBound_IsEmpty"
			local value = commonFunctions:createArrayEnum(Boundary[1], defaultEnumValue)
			commonFunctions:TestCase(self, Request, Parameter, verification, value, "SUCCESS")
		else
			-- Boundary = 0 ==> Is covered by _element_IsMissed_
		end
		
		
		
		--3. IsUpperBound
		local value = commonFunctions:createArrayEnum(Boundary[2], defaultEnumValue)
		commonFunctions:TestCase(self, Request, Parameter, "IsUpperBound", value, "SUCCESS")
		
		--4. IsOutLowerBound/IsEmpty
		if Boundary[1] ==1 then
			local value = commonFunctions:createArrayEnum(Boundary[1]-1, defaultEnumValue)
			commonFunctions:TestCase(self, Request, Parameter, "IsOutLowerBound_IsEmpty", value, "INVALID_DATA")
		
		elseif Boundary[1] >1 then
			local value = commonFunctions:createArrayEnum(Boundary[1]-1, defaultEnumValue)
			commonFunctions:TestCase(self, Request, Parameter, "IsOutLowerBound", value, "INVALID_DATA")
			
			commonFunctions:TestCase(self, Request, Parameter, "IsEmpty", {}, "INVALID_DATA")			
		else
			--minsize = 0, no check out lower bound		
		end
		
		--5. IsOutUpperBound
		local value = commonFunctions:createArrayEnum(Boundary[2]+1, defaultEnumValue)
		commonFunctions:TestCase(self, Request, Parameter, "IsOutUpperBound", value, "INVALID_DATA")
		
		--6. IsWrongType
		commonFunctions:TestCase(self, Request, Parameter, "IsWrongDataType", 123, "INVALID_DATA")
				
		
end
---------------------------------------------------------------------------------------------


--Contains all test cases
function testCasesForArrayEnumParameter:verify_Array_Enum_Parameter(Request, Parameter, Boundary,  ElementExistentValues, Mandatory)

		--Verify array only
		testCasesForArrayEnumParameter:verify_Array_Enum_Parameter_Only(Request, Parameter, Boundary,  ElementExistentValues, Mandatory)
		
		
		--Verify an element in array		
		local TestingRequest = commonFunctions:cloneTable(Request)
		commonFunctions:setValueForParameter(TestingRequest, Parameter, {})	

		local parameter_arrayElement = commonFunctions:BuildChildParameter(Parameter, 1)--ElementExistentValues[1])

		--Verify an element in a Enum array.
		--2. IsWrongType
		--3. IsExistentValues
		--4. IsNonExistentValue
		--5. IsEmpty
		enumerationParameter:verify_Enum_String_Parameter(TestingRequest, parameter_arrayElement, ElementExistentValues, false)
		
		
end

return testCasesForArrayEnumParameter
---------------------------------------------------------------------------------------------
