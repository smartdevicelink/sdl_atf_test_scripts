--This script contains all test cases to verify Image Parameter
--How to use:
	--1. local imageParameter = require('user_modules/shared_testcases/testCasesForImageParameterInNotification')
	--2. imageParameter:verify_Image_Parameter(Request, Parameter, ImageValueBoundary, Mandatory)
---------------------------------------------------------------------------------------------
local testCasesForImageParameter = {}
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local enumerationParameter = require('user_modules/shared_testcases/testCasesForEnumerationParameterInNotification')
local storagePath = config.pathToSDL..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"	
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
local function verify_image_value_Parameter(Notification, Parameter, Boundary, Mandatory)

		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup(Parameter)	

		--1. IsMissed
		local IsValidValue
		if Mandatory == true then
			IsValidValue = false
		else
			IsValidValue = true
		end

		commonFunctions:TestCaseForNotification(self, Notification, Parameter, "IsMissed", nil, IsValidValue)		

		--2. IsLowerBound
		commonFunctions:TestCaseForNotification(self, Notification, Parameter, "IsLowerBound", Boundary[1], true)


		--3. IsUpperBound - PutFile max length
		commonFunctions:TestCaseForNotification(self, Notification, Parameter, "IsUpperBound_PutFileMaxLength", Boundary[2], true)

		--4. IsLowerBound/IsEmpty
		commonFunctions:TestCaseForNotification(self, Notification, Parameter, "IsLowerBound_IsEmpty", "", true)

		--5. IsOutUpperBound - PutFile max length
		commonFunctions:TestCaseForNotification(self, Notification, Parameter, "IsOutUpperBound_PutFileMaxLength", Boundary[2] .. "a", true)

		--6. IsWrongType
		commonFunctions:TestCaseForNotification(self, Notification, Parameter, "IsWrongType", 123, false)

		--7. IsInvalidCharacters: Special characters validation: INVALID_DATA response should come according to APPLINK-7687
		local InvalidCharacters = 
		{
			{value = "a\nb", name = "NewLine"},
			{value = "a\tb", name = "Tab"},
			{value = "    ", name = "WhiteSpacesOnly"}
		}

		for i = 1, #InvalidCharacters do
			commonFunctions:TestCaseForNotification(self, Notification, Parameter, "IsInvalidCharacters_"..InvalidCharacters[i].name, InvalidCharacters[i].value, true)
		end

		--8. IsUpperBound - 65535 characters		
		commonFunctions:TestCaseForNotification(self, Notification, Parameter, "IsUpperBound", string.rep("a",65535), true)

		--9. IsOutUpperBound - 65536 characters
		commonFunctions:TestCaseForNotification(self, Notification, Parameter, "IsOutUpperBound", string.rep("a",65536), false)
end
---------------------------------------------------------------------------------------------

--Contains all test cases to verify image
function testCasesForImageParameter:verify_Image_Parameter(Notification, Parameter, ImageValueBoundary, Mandatory)
	
		
		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup(Parameter)	
		
		--1. IsMissed
		local IsValidValue
		if Mandatory == true then
			IsValidValue = false
		else
			IsValidValue = true
		end
		
		commonFunctions:TestCaseForNotification(self, Notification, Parameter, "IsMissed", nil, IsValidValue)	
		
		--2. IsEmpty
		commonFunctions:TestCaseForNotification(self, Notification, Parameter, "IsEmpty", {}, false)
		
		--3. IsWrongType
		commonFunctions:TestCaseForNotification(self, Notification, Parameter, "IsWrongDataType", 123, false)
			
	
		--Prepare for 4 and 5
		local Notification = commonFunctions:cloneTable(Notification)
		local image = {
				imageType = "STATIC",
				value = storagePath .."a.png"
				
			}
					
		commonFunctions:setValueForParameter(Notification, Parameter, image)
		
		--4. image.imageType: type=ImageType ("STATIC", "DYNAMIC")
		local ExistentValues = {"STATIC", "DYNAMIC"}
		local parameter_imageType = commonFunctions:BuildChildParameter(Parameter, "imageType")
		
		
		enumerationParameter:verify_Enumeration_Parameter(Notification, parameter_imageType, ExistentValues, true)

		--5. image.value: type=String, minlength=0 maxlength=65535
		local parameter_value = commonFunctions:BuildChildParameter(Parameter, "value")
		
		verify_image_value_Parameter(Notification, parameter_value, ImageValueBoundary, true) 
		
end
---------------------------------------------------------------------------------------------	


return testCasesForImageParameter
