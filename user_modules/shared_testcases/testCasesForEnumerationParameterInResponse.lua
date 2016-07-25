--This script contains all test cases to verify String enumeration parameter
--How to use:
	--1. local enumerationParameter = require('user_modules/shared_testcases/testCasesForEnumerationParameter')
	--2. enumerationParameter:verify_Enum_String_Parameter(Request, Parameter, ExistentValues, Mandatory)
---------------------------------------------------------------------------------------------

local testCasesForEnumerationParameter = {}
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')


---------------------------------------------------------------------------------------------
--Test cases to verify String Enumeration parameter
---------------------------------------------------------------------------------------------
--List of test cases for String enumeration parameter:
	--1. IsMissed
	--2. IsWrongDataType
	--3. IsExistentValues
	--4. IsNonExistentValue
	--5. IsEmpty	


--Contains all test cases
function testCasesForEnumerationParameter:verify_Enum_String_Parameter(Request, Parameter, ExistentValues, Mandatory)

		
		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup(Parameter)	
		
		--1. IsMissed
		local resultCode = "GENERIC_ERROR"
		if Mandatory == false then
			resultCode = "SUCCESS"
		end
		
		commonFunctions:TestCase(self, Request, Parameter, "IsMissed", nil, resultCode)	
		
		
		--2. IsWrongDataType
		commonFunctions:TestCase(self, Request, Parameter, "IsWrongDataType", 123, "GENERIC_ERROR")
		
		--3. IsExistentValues
		for i = 1, #ExistentValues do
			commonFunctions:TestCase(self, Request, Parameter, "IsExistentValues_"..ExistentValues[i], ExistentValues[i], "SUCCESS")
		end
		
		--4. IsNonexistentValue
		commonFunctions:TestCase(self, Request, Parameter, "IsNonexistentValue", "ANY", "GENERIC_ERROR")
		
		--5. IsEmpty
		commonFunctions:TestCase(self, Request, Parameter, "IsEmpty", "", "GENERIC_ERROR")
		
		
		
end
---------------------------------------------------------------------------------------------


return testCasesForEnumerationParameter
