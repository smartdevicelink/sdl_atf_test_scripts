--This script contains all test cases to verify MetadataTags parameter
--How to use:
	--1. local MetadataTagsParameter = require('user_modules/shared_testcases/testCasesForMetadataTagsParameter')
	--2. MetadataTagsParameter:verify_MetadataTags_Parameter(Request, Parameter, Mandatory)
---------------------------------------------------------------------------------------------


local testCasesForMetadataTagsParameter= {}

local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local arrayEnumerationParameter = require('user_modules/shared_testcases/testCasesForArrayEnumParameter')




---------------------------------------------------------------------------------------------
--Test cases to verify a MetadataTags parameter
---------------------------------------------------------------------------------------------
	--1. IsMissed
	--2. IsWrongDataType
	--3. mainField1: type="MetadataType", minsize="0" maxsize="5" array="true" mandatory="false"

	
function testCasesForMetadataTagsParameter:verify_MetadataTags_Parameter(Request, Parameter, Mandatory)

		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup(Parameter)	
		
		--1. IsMissed
		local resultCode = "INVALID_DATA"
		if Mandatory == false then
			resultCode = "SUCCESS"
		end
		
		commonFunctions:TestCase(self, Request, Parameter, "IsMissed", nil, resultCode)		
		
		
		--2. IsEmpty
--		commonFunctions:TestCase(self, Request, Parameter, "IsEmpty", {}, "INVALID_DATA")		
		
		
		--2. IsWrongDataType
		commonFunctions:TestCase(self, Request, Parameter, "IsWrongDataType", 123, "INVALID_DATA")
		
		--Check parameters in side MetadataTags:
		
		--3. mainField1: type="MetadataType", minsize="0", maxsize="5", array="true", mandatory="false"
		local Boundary = {0, 5}
		local ExistentValues = {
			"mediaTitle",
			"mediaArtist",
			"mediaAlbum",
			"mediaYear",
			"mediaGenre",
			"mediaStation",
			"rating",
			"currentTemperature",
			"maximumTemperature",
			"minimumTemperature",
			"weatherTerm",
			"humidity"
		}
		local Request2 = commonFunctions:cloneTable(Request)
		local metadataTags = {
			mainField1 = {"rating"},
			mainField2 = {"rating"},
			mainField3 = {"rating"},
			mainField4 = {"rating"},
		}
		commonFunctions:setValueForParameter(Request2, Parameter, metadataTags)

		local parameter_mainField1 = commonFunctions:BuildChildParameter(Parameter, "mainField1")
		arrayEnumerationParameter:verify_Array_Enum_Parameter(Request2, parameter_mainField1, Boundary, ExistentValues, false)
		
		local parameter_mainField2 = commonFunctions:BuildChildParameter(Parameter, "mainField2")
		arrayEnumerationParameter:verify_Array_Enum_Parameter(Request2, parameter_mainField2, Boundary, ExistentValues, false)

		local parameter_mainField3 = commonFunctions:BuildChildParameter(Parameter, "mainField3")
		arrayEnumerationParameter:verify_Array_Enum_Parameter(Request2, parameter_mainField3, Boundary, ExistentValues, false)

		local parameter_mainField4 = commonFunctions:BuildChildParameter(Parameter, "mainField4")
		arrayEnumerationParameter:verify_Array_Enum_Parameter(Request2, parameter_mainField4, Boundary, ExistentValues, false)


end


return testCasesForMetadataTagsParameter
