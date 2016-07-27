--This script contains all test cases to array String Parameter
--How to use:
	--1. local arrayStringParameterInNotification = require('user_modules/shared_testcases/testCasesForArrayStringParameterInNotification')
	--2. arrayStringParameterInNotification:verify_Array_String_Parameter(Notification, Parameter, Boundary,  ElementBoundary, Mandatory)
---------------------------------------------------------------------------------------------

local testCasesForArrayStringParameterInNotification = {}
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local stringParameterInNotification = require('user_modules/shared_testcases/testCasesForStringParameterInNotification')

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
	--7. Verify an item in array
---------------------------------------------------------------------------------------------


--Contains all test cases
function testCasesForArrayStringParameterInNotification:verify_Array_String_Parameter(Notification, Parameter, Boundary,  ElementBoundary, Mandatory, IsStringElementAcceptedSpecialCharacter)

		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup(Parameter)	
		
		--1. IsMissed
		local IsValidValue = false
		if Mandatory == nil then
			--no check mandatory
		else			
			if Mandatory == true then
				--HMI sends notification and check that SDL ignores the notification 
				commonFunctions:TestCaseForNotification(self, Notification, Parameter, "IsMissed", nil, false)	
			else
				--HMI sends notification and check that SDL ignores the notification
				commonFunctions:TestCaseForNotification(self, Notification, Parameter, "IsMissed", nil, true)	
			end		
		end
		
		
		--2. IsLowerBound
		if Boundary[1] > 0 then
			local value = commonFunctions:createArrayString(Boundary[1])
			commonFunctions:TestCaseForNotification(self, Notification, Parameter, "IsLowerBound", value, true)
		else
			-- Boundary = 0 ==> Is covered by _element_IsMissed_
		end
		
				
		--3. IsUpperBound
		local value = commonFunctions:createArrayString(Boundary[2])
		commonFunctions:TestCaseForNotification(self, Notification, Parameter, "IsUpperBound", value, true)
		
		--4. IsOutLowerBound/IsEmpty
		if Boundary[1] ==1 then
			local value = commonFunctions:createArrayString(Boundary[1]-1)
			commonFunctions:TestCaseForNotification(self, Notification, Parameter, "IsOutLowerBound_IsEmpty", value, false)
		
		elseif Boundary[1] >1 then
			local value = commonFunctions:createArrayString(Boundary[1]-1)
			commonFunctions:TestCaseForNotification(self, Notification, Parameter, "IsOutLowerBound", value, false)
			
			commonFunctions:TestCaseForNotification(self, Notification, Parameter, "IsEmpty", {}, false)			
		else
			--minsize = 0, no check out lower bound		
		end
		
		--5. IsOutUpperBound
		local value = commonFunctions:createArrayString(Boundary[2]+1)
		commonFunctions:TestCaseForNotification(self, Notification, Parameter, "IsOutUpperBound", value, false)
		
		--6. IsWrongType
		commonFunctions:TestCaseForNotification(self, Notification, Parameter, "IsWrongDataType", 123, false)
		
		
		--Verify an element in array		
		TestingNotification = commonFunctions:cloneTable(Notification)
		commonFunctions:setValueForParameter(TestingNotification, Parameter, {})	

		local parameter_arrayElement = commonFunctions:BuildChildParameter(Parameter, 1) -- element #1
		-- verify_String_Parameter(Notification, Parameter, Boundary, IsMandatory, IsAcceptedInvalidCharacters)
		if Boundary[1] >0 then
			stringParameterInNotification:verify_String_Parameter(TestingNotification, parameter_arrayElement, ElementBoundary, true, IsStringElementAcceptedSpecialCharacter)
		else 
			stringParameterInNotification:verify_String_Parameter(TestingNotification, parameter_arrayElement, ElementBoundary, false, IsStringElementAcceptedSpecialCharacter)
		end
end
---------------------------------------------------------------------------------------------

return testCasesForArrayStringParameterInNotification
