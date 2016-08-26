--This script contains all test cases to verify Image Parameter
--How to use:
	--1. local imageParameter = require('user_modules/shared_testcases/testCasesForImageParameter')
	--2. imageParameter:verify_Image_Parameter(Request, Parameter, ImageValueBoundary, Mandatory)
---------------------------------------------------------------------------------------------

local testCasesForImageParameter = {}
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local enumerationParameter = require('user_modules/shared_testcases/testCasesForEnumerationParameterInResponse')

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
local function verify_image_value_Parameter(Response, Parameter, Boundary, Mandatory)


		local Response = commonFunctions:cloneTable(Response)	
		--print_table(Parameter)

		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup(Parameter)	

		--1. IsMissed
		local resultCode
		if Mandatory == true then
			resultCode = "GENERIC_ERROR"
		else
			resultCode = "SUCCESS"
		end
		
		commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsMissed", nil, resultCode)		
		
		--2. IsLowerBound
		commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsLowerBound", Boundary[1], "SUCCESS")
		
		
		--3. IsUpperBound - PutFile max length
		commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsUpperBound_PutFileMaxLength", Boundary[2], "SUCCESS")
		
		--4. IsOutLowerBound/IsEmpty
		--commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsOutLowerBound_IsEmpty", "", "GENERIC_ERROR")
		
		--5. IsOutUpperBound - PutFile max length
		commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsOutUpperBound_PutFileMaxLength", Boundary[2] .. "a", "SUCCESS")
		
		--6. IsWrongType
		commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsWrongType", 123, "GENERIC_ERROR")
		
		
		-- Uncomment after implementation APPLINK-24135
		--7. IsInvalidCharacters: Special characters validation: INVALID_DATA response should come according to APPLINK-7687
		-- local InvalidCharacters = 
		-- {
		-- 	{value = "a\nb", name = "NewLine"},
		-- 	{value = "a\tb", name = "Tab"},
		-- 	{value = "    ", name = "WhiteSpacesOnly"}
		-- }

		-- for i = 1, #InvalidCharacters do
		-- 	commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsInvalidCharacters_"..InvalidCharacters[i].name, InvalidCharacters[i].value, "GENERIC_ERROR")
		-- end
		
		--8. IsUpperBound - 65535 characters		
		commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsUpperBound", string.rep("a",65535), "SUCCESS")
		
		--9. IsOutUpperBound - 65536 characters
		commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsOutUpperBound", string.rep("a",65536), "GENERIC_ERROR")
end
---------------------------------------------------------------------------------------------

--Contains all test cases to verify image
function testCasesForImageParameter:verify_Image_Parameter(Response, Parameter, ImageValueBoundary, Mandatory)
	
		local Response = commonFunctions:cloneTable(Response)	
		
		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup(Parameter)	
		
		--1. IsMissed
		local resultCode
		if Mandatory == true then
			resultCode = "GENERIC_ERROR"
		else
			resultCode = "SUCCESS"
		end
		
		
		commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsMissed", nil, resultCode)	
		
		--2. IsEmpty
		commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsEmpty", {}, "GENERIC_ERROR")
		
		--3. IsWrongType
		commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsWrongDataType", 123, "GENERIC_ERROR")
				
		--4. ContainsWrongValues (Based on Irina Getmanets comment on SendLocation script 3,4 is duplicate)
		--commonFunctions:TestCase(self, Request, Parameter, "ContainsWrongValues", {123}, "INVALID_DATA")
		
		-------------------------------------------------------------------------------------------
		
		--Prepare for 5 and 6
		local TestingRequest = commonFunctions:cloneTable(Response)
		local image = {
						imageType = "STATIC",
						value = "icon.png"
					}
					
		commonFunctions:setValueForParameter(TestingRequest, Parameter, image)

		
		--5. image.imageType: type=ImageType ("STATIC", "DYNAMIC")
		local ExistentValues = {"STATIC", "DYNAMIC"}
		local parameter_imageType = commonFunctions:BuildChildParameter(Parameter, "imageType")
		
		
		--enumerationParameter:verify_Enum_String_Parameter(TestingRequest, parameter_imageType, ExistentValues, true)

		
		--6. image.value: type=String, minlength=0 maxlength=65535
		local parameter_value = commonFunctions:BuildChildParameter(Parameter, "value")
		
		verify_image_value_Parameter(TestingRequest, parameter_value, ImageValueBoundary, true) 
		
end
---------------------------------------------------------------------------------------------	


return testCasesForImageParameter
