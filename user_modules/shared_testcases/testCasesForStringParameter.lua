--This script contains all test cases to verify String parameter
--How to use:
	--1. local stringParameter = require('user_modules/shared_testcases/testCasesForStringParameter')
	--2. stringParameter:verify_String_Parameter(Request, Parameter, Boundary, Mandatory)
---------------------------------------------------------------------------------------------


local testCasesForStringParameter = {}
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')



---------------------------------------------------------------------------------------------
--Test cases to verify String parameter
---------------------------------------------------------------------------------------------
--List of test cases for String type parameter:
	--1. IsMissed
	--2. IsWrongType
	--3. IsLowerBound/IsEmpty
	--4. IsOutLowerBound/IsEmpty
	--5. IsUpperBound
	--6. IsOutUpperBound
	--7. IsInvalidCharacters
---------------------------------------------------------------------------------------------
	
--1. verify_String_Parameter_Basic: verify basic cases
	--2. IsWrongType
	--3. IsLowerBound/IsEmpty
	--4. IsOutLowerBound/IsEmpty
	--5. IsUpperBound
	--6. IsOutUpperBound
function testCasesForStringParameter:verify_String_Parameter_Basic(Request, Parameter, Boundary)

	local Request = commonFunctions:cloneTable(Request)	
	
	--2. IsWrongDataType
	commonFunctions:TestCase(self, Request, Parameter, "IsWrongDataType", 123, "INVALID_DATA")
	
	
	--3. IsLowerBound/IsEmpty
	local verification = "IsLowerBound"
	if Boundary[1] == 0 then
		verification = "IsLowerBound_IsEmpty"
	end
	
	local value = commonFunctions:createString(Boundary[1])
	commonFunctions:TestCase(self, Request, Parameter, verification, value, "SUCCESS")
	
	
	--4. IsOutLowerBound/IsEmpty
	local value = commonFunctions:createString(Boundary[1] - 1)
	if Boundary[1] >= 2 then
		commonFunctions:TestCase(self, Request, Parameter, "IsOutLowerBound", value, "INVALID_DATA")
	elseif Boundary[1] == 1 then		
		commonFunctions:TestCase(self, Request, Parameter, "IsOutLowerBound_IsEmpty", value, "INVALID_DATA")
	else
		--minlength = 0, no check out lower bound
	end
	
	
	--5. IsUpperBound
	local value = commonFunctions:createString(Boundary[2])
	commonFunctions:TestCase(self, Request, Parameter, "IsUpperBound", value, "SUCCESS")
	
	
	--6. IsOutUpperBound
	local value = commonFunctions:createString(Boundary[2] + 1)
	commonFunctions:TestCase(self, Request, Parameter, "IsOutUpperBound", value, "INVALID_DATA")
		
end	

	
--2. verify_String_Parameter_Mandatory: verify mandatory and basic cases
	--1. IsMissed
	--2-6:
	
function testCasesForStringParameter:verify_String_Parameter_Mandatory(Request, Parameter, Boundary, Mandatory)

	local Request = commonFunctions:cloneTable(Request)	

	--Print new line to separate new test cases group
	-- commonFunctions:newTestCasesGroup(Parameter)	
	
	--1. IsMissed
	local resultCode
	if Mandatory == true then
		resultCode = "INVALID_DATA"
	else
		resultCode = "SUCCESS"
	end
	
	commonFunctions:TestCase(self, Request, Parameter, "IsMissed", nil, resultCode)		
	
	testCasesForStringParameter:verify_String_Parameter_Basic(Request, Parameter, Boundary, Mandatory)
	
end	

--3. verify_String_Parameter_AcceptSpecialCharacters: Contain basic cases and verify SUCCESS resultCode when containing spacial characters
function testCasesForStringParameter:verify_String_Parameter_AcceptSpecialCharacters(Request, Parameter, Boundary, Mandatory)

	local Request = commonFunctions:cloneTable(Request)	

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup(Parameter)	
	
	testCasesForStringParameter:verify_String_Parameter_Mandatory(Request, Parameter, Boundary, Mandatory)
	
	--7. IsSpecialCharacters
	commonFunctions:TestCase(self, Request, Parameter, "ContainsNewLineCharacter", "a\nb", "SUCCESS")
	commonFunctions:TestCase(self, Request, Parameter, "ContainsTabCharacter", "a\tb", "SUCCESS")
	commonFunctions:TestCase(self, Request, Parameter, "WhiteSpacesOnly", "   ", "SUCCESS")		
end	

	
--4. verify_String_Parameter: Contain basic cases and verify INVALID_DATA resultCode when containing spacial characters
function testCasesForStringParameter:verify_String_Parameter(Request, Parameter, Boundary, Mandatory)

		local Request = commonFunctions:cloneTable(Request)	

		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup(Parameter)	
		
		testCasesForStringParameter:verify_String_Parameter_Mandatory(Request, Parameter, Boundary, Mandatory)
		
		--7. IsInvalidCharacters: Special characters validation: INVALID_DATA response should come according to APPLINK-7687
		commonFunctions:TestCase(self, Request, Parameter, "ContainsNewLineCharacter", "a\nb", "INVALID_DATA")
		commonFunctions:TestCase(self, Request, Parameter, "ContainsTabCharacter", "a\tb", "INVALID_DATA")
		commonFunctions:TestCase(self, Request, Parameter, "WhiteSpacesOnly", "   ", "INVALID_DATA")

end	


---------------------------------------------------------------------------------------------
--Test cases to verify String parameter in ARRAY
---------------------------------------------------------------------------------------------

--1. verify_String_Element_InArray_Parameter
function testCasesForStringParameter:verify_String_Element_InArray_Parameter(Request, Parameter, Boundary)

		local Request = commonFunctions:cloneTable(Request)	

		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup(Parameter)	
		
		testCasesForStringParameter:verify_String_Parameter_Basic(Request, Parameter, Boundary)
		
		--7. IsInvalidCharacters: Special characters validation: INVALID_DATA response should come according to APPLINK-7687
		commonFunctions:TestCase(self, Request, Parameter, "ContainsNewLineCharacter", "a\nb", "INVALID_DATA")
		commonFunctions:TestCase(self, Request, Parameter, "ContainsTabCharacter", "a\tb", "INVALID_DATA")
		commonFunctions:TestCase(self, Request, Parameter, "WhiteSpacesOnly", "   ", "INVALID_DATA")

end	

--2. verify_String_Element_InArray_AcceptSpecialCharacters
function testCasesForStringParameter:verify_String_Element_InArray_AcceptSpecialCharacters(Request, Parameter, Boundary)

	local Request = commonFunctions:cloneTable(Request)	

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup(Parameter)	
	
	testCasesForStringParameter:verify_String_Parameter_Basic(Request, Parameter, Boundary)
	
	--7. IsSpecialCharacters
	commonFunctions:TestCase(self, Request, Parameter, "ContainsNewLineCharacter", "a\nb", "SUCCESS")
	commonFunctions:TestCase(self, Request, Parameter, "ContainsTabCharacter", "a\tb", "SUCCESS")
	commonFunctions:TestCase(self, Request, Parameter, "WhiteSpacesOnly", "   ", "SUCCESS")		
end	

return testCasesForStringParameter
