--This script contains all test cases to verify Image Parameter
--How to use:
	--1. local imageParameter = require('user_modules/shared_testcases/testCasesForImageParameter')
	--2. imageParameter:verify_Image_Parameter(Request, Parameter, ImageValueBoundary, Mandatory)
---------------------------------------------------------------------------------------------

local testCasesForImageParameter = {}
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local enumerationParameter = require('user_modules/shared_testcases/testCasesForEnumerationParameter')

---------------------------------------------------------------------------------------------
--Test cases to verify Image Parameter
---------------------------------------------------------------------------------------------
--List of test cases for Image type Parameter:
	--1. IsMissed
	--2. IsEmpty
	--3. IsWrongType
	--4. ContainsWrongValues
	--5. image.imageType: type=ImageType ("STATIC", "DYNAMIC")
	--6. image.value: type=String, minlength=0 maxlength=65535
	
---------------------------------------------------------------------------------------------
--Test cases to verify image value Parameter
---------------------------------------------------------------------------------------------


--Contains all test cases to verify value Parameter of a image
local function verify_image_value_Parameter(Request, Parameter, Boundary, Mandatory)

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
		
		--2. IsLowerBound
		commonFunctions:TestCase(self, Request, Parameter, "IsLowerBound", Boundary[1], "SUCCESS")
		
		
		--3. IsUpperBound - PutFile max length
		commonFunctions:TestCase(self, Request, Parameter, "IsUpperBound_PutFileMaxLength", Boundary[2], "SUCCESS")
		
		--4. IsOutLowerBound/IsEmpty
		commonFunctions:TestCase(self, Request, Parameter, "IsOutLowerBound_IsEmpty", "", "INVALID_DATA")
		
		--5. IsOutUpperBound - PutFile max length
		commonFunctions:TestCase(self, Request, Parameter, "IsOutUpperBound_PutFileMaxLength", Boundary[2] .. "a", "SUCCESS")
		
		--6. IsWrongType
		commonFunctions:TestCase(self, Request, Parameter, "IsWrongType", 123, "INVALID_DATA")
		
		--7. IsInvalidCharacters: Special characters validation: INVALID_DATA response should come according to APPLINK-7687
		local InvalidCharacters = 
		{
			{value = "a\nb", name = "NewLine"},
			{value = "a\tb", name = "Tab"},
			{value = "    ", name = "WhiteSpacesOnly"}
		}

		for i = 1, #InvalidCharacters do
			commonFunctions:TestCase(self, Request, Parameter, "IsInvalidCharacters_"..InvalidCharacters[i].name, InvalidCharacters[i].value, "INVALID_DATA")
		end
		
		--8. IsUpperBound - 65535 characters		
		commonFunctions:TestCase(self, Request, Parameter, "IsUpperBound", string.rep("a",65535), "SUCCESS")
		
		--9. IsOutUpperBound - 65536 characters
		commonFunctions:TestCase(self, Request, Parameter, "IsOutUpperBound", string.rep("a",65536), "INVALID_DATA")
end
---------------------------------------------------------------------------------------------

--Contains all test cases to verify image
function testCasesForImageParameter:verify_Image_Parameter(Request, Parameter, ImageValueBoundary, Mandatory)
	
		
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
		
		--2. IsEmpty
		commonFunctions:TestCase(self, Request, Parameter, "IsEmpty", {}, "INVALID_DATA")
		
		--3. IsWrongType
		commonFunctions:TestCase(self, Request, Parameter, "IsWrongDataType", 123, "INVALID_DATA")
				
		--4. ContainsWrongValues (Based on Irina Getmanets comment on SendLocation script 3,4 is duplicate)
		--commonFunctions:TestCase(self, Request, Parameter, "ContainsWrongValues", {123}, "INVALID_DATA")
		
		-------------------------------------------------------------------------------------------
		
		--Prepare for 5 and 6
		local TestingRequest = commonFunctions:cloneTable(Request)
		local image = {
						imageType = "STATIC",
						value = "icon.png"
					}
					
		commonFunctions:setValueForParameter(TestingRequest, Parameter, image)

		
		--5. image.imageType: type=ImageType ("STATIC", "DYNAMIC")
		local ExistentValues = {"STATIC", "DYNAMIC"}
		local parameter_imageType = commonFunctions:BuildChildParameter(Parameter, "imageType")
		
		
		enumerationParameter:verify_Enum_String_Parameter(TestingRequest, parameter_imageType, ExistentValues, true)

		
		--6. image.value: type=String, minlength=0 maxlength=65535
		local parameter_value = commonFunctions:BuildChildParameter(Parameter, "value")
		
		verify_image_value_Parameter(TestingRequest, parameter_value, ImageValueBoundary, true) 
		
end
---------------------------------------------------------------------------------------------	


return testCasesForImageParameter
