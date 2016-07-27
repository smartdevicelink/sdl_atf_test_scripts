--This script contains all test cases to verify Double parameter
--How to use:
	--1. local integerParameter = require('user_modules/shared_testcases/testCasesForDoubleParameter')
	--2. integerParameter:verify_Double_Parameter(Request, Parameter, Boundary, Mandatory)
---------------------------------------------------------------------------------------------


local testCasesForDoubleParameter = {}
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')




---------------------------------------------------------------------------------------------
--Test cases to verify Double parameter
---------------------------------------------------------------------------------------------
--List of test cases for Double type parameter:
	--1. IsMissed
	--2. IsWrongType
	--3. IsLowerBound
	--4. IsUpperBound
	--5. IsOutLowerBound
	--6. IsOutUpperBound
	

--Contains all test cases
function testCasesForDoubleParameter:verify_Double_Parameter(Request, Parameter, Boundary, Mandatory, NamePrefix)
		
		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup(Parameter)	
		
		
		--1. IsMissed
		local resultCode
		if Mandatory == true then
			resultCode = "INVALID_DATA"
		else
			resultCode = "SUCCESS"
		end

		if NamePrefix == nil then
			NamePrefix = ""
		end
		
		
		commonFunctions:TestCase(self, Request, Parameter, tostring(NamePrefix) .. "IsMissed", nil, resultCode)	
		
		
		--2. IsWrongDataType
		commonFunctions:TestCase(self, Request, Parameter, tostring(NamePrefix) .. "IsWrongDataType", "123", "INVALID_DATA")
		
		--3. IsLowerBound
		commonFunctions:TestCase(self, Request, Parameter, tostring(NamePrefix) .. "IsLowerBound_Int", Boundary[1], "SUCCESS")

		local function Value_for_Double_cases(BoundValue)
			local valueForBound 

			BoundValue = tostring(BoundValue)
			IntBound = BoundValue:match("[-]?([(%d^.]+).?")

			if #IntBound == 1 then
				valueForBound = 0.0000000000001
			elseif #IntBound == 2 then
				valueForBound = 0.000000000001
			elseif #IntBound == 3 then
				valueForBound = 0.00000000001
			end

			return valueForBound
		end

		local ValueForLowerBound = Value_for_Double_cases(Boundary[1])
		commonFunctions:TestCase(self, Request, Parameter, tostring(NamePrefix) .. "IsLowerBound_Double", Boundary[1] + ValueForLowerBound, "SUCCESS")
		
		--4. IsUpperBound
		commonFunctions:TestCase(self, Request, Parameter, tostring(NamePrefix) .. "IsUpperBound_Int" , Boundary[2], "SUCCESS")

		local ValueForUpperBound = Value_for_Double_cases(Boundary[2])
		commonFunctions:TestCase(self, Request, Parameter, tostring(NamePrefix) .. "IsUpperBound_Double" , Boundary[2] - ValueForUpperBound, "SUCCESS")
		
		--5. IsOutLowerBound
		commonFunctions:TestCase(self, Request, Parameter, tostring(NamePrefix) .. "IsOutLowerBound", Boundary[1] - ValueForLowerBound, "INVALID_DATA")
		
		--6. IsOutUpperBound
		commonFunctions:TestCase(self, Request, Parameter, tostring(NamePrefix) .. "IsOutUpperBound", Boundary[2] + ValueForUpperBound, "INVALID_DATA")

		--7. Max double value
		commonFunctions:TestCase(self, Request, Parameter, tostring(NamePrefix) .. "MaxDoubleDecimalPlaces" , 0.00000000000000001, "SUCCESS")
		
end


return testCasesForDoubleParameter
