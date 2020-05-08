Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')
local json  = require('json')
local module = require('testbase')
----------------------------------------------------------------------------
--UPDATED:
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2
local storagePath = config.pathToSDL .. "storage/" ..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"	

-- User required files
require('user_modules/AppTypes')
local SDLConfig = require('user_modules/shared_testcases/SmartDeviceLinkConfigurations')

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local stringParameter = require('user_modules/shared_testcases/testCasesForStringParameter')
local enumerationParameter = require('user_modules/shared_testcases/testCasesForEnumerationParameter')
local imageParameter = require('user_modules/shared_testcases/testCasesForImageParameter')
local arraySoftButtonsParameter = require('user_modules/shared_testcases/testCasesForArraySoftButtonsParameter')
local arrayStringParameter = require('user_modules/shared_testcases/testCasesForArrayStringParameter')
local metadataTagsParameter = require('user_modules/shared_testcases/testCasesForMetadataTagsParameter')
require('user_modules/AppTypes')

---------------------------------------------------------------------------------------------
------------------------------------ Common Variables ---------------------------------------
---------------------------------------------------------------------------------------------
APIName = "Show" -- set request name
strMaxLengthFileName255 = string.rep("a", 251)  .. ".png" -- set max length file name
strMaxLengthInvalidFileName255 = string.rep("a", 251)  .. ".png" -- set max length file name
--local storagePath = config.pathToSDL .. SDLConfig:GetValue("AppStorageFolder") .. "/" .. tostring(config.application1.registerAppInterfaceParams.appID .. "_" .. tostring(config.deviceMAC) .. "/")

--Debug = {"graphic", "value"} --use to print request before sending to SDL.
Debug = {} -- empty {}: script will do not print request on console screen.

---------------------------------------------------------------------------------------------
-------------------------- Overwrite These Functions For This Script-------------------------
---------------------------------------------------------------------------------------------
--Specific functions for this script
--1. createRequest()
--2. createUIParameters(Request)
--3. verify_SUCCESS_Case(Request)
---------------------------------------------------------------------------------------------



--Create default request parameters
function Test:createRequest()

	return {
		
		customPresets =
		{
			"Preset1",
			"Preset2",
			"Preset3"													
		}
	}
	
end
---------------------------------------------------------------------------------------------

--Create UI expected result based on parameters from the request
function Test:createUIParameters(Request)

	local param =  {}

	param["alignment"] =  Request["alignment"]
	param["customPresets"] =  Request["customPresets"]
	
	--Convert showStrings parameter
	local j = 0
	for i = 1, 4 do	
		if Request["mainField" .. i] ~= nil then
			j = j + 1
			if param["showStrings"] == nil then
				param["showStrings"] = {}			
			end
			param["showStrings"][j] = {
				fieldName = "mainField" .. i,
				fieldText = Request["mainField" .. i]
			}
			if (Request["metadataTags"] ~= nil and
				Request["metadataTags"]["mainField" .. i] ~= nil) then
				if param["showStrings"][j]["fieldTypes"] == nil then
					param["showStrings"][j]["fieldTypes"] = {}
				end
				local numTypes = #Request["metadataTags"]["mainField" .. i]
				local k = 0
				for k = 1, numTypes do
					param["showStrings"][j]["fieldTypes"][k] = Request["metadataTags"]["mainField" .. i][k]
				end
			end
		end
	end
	
	--mediaClock
	if Request["mediaClock"] ~= nil then
		j = j + 1
		if param["showStrings"] == nil then
			param["showStrings"] = {}			
		end		
		param["showStrings"][j] = {
			fieldName = "mediaClock",
			fieldText = Request["mediaClock"]
		}
	end
	
	--mediaTrack
	if Request["mediaTrack"] ~= nil then
		j = j + 1
		if param["showStrings"] == nil then
			param["showStrings"] = {}			
		end				
		param["showStrings"][j] = {
			fieldName = "mediaTrack",
			fieldText = Request["mediaTrack"]
		}
	end
	
	--statusBar
	if Request["statusBar"] ~= nil then
		j = j + 1
		if param["showStrings"] == nil then
			param["showStrings"] = {}			
		end				
		param["showStrings"][j] = {
			fieldName = "statusBar",
			fieldText = Request["statusBar"]
		}
	end

	
--Updated: The check is commented here and added in respective sections due to changed expectations of file location
	-- param["graphic"] =  Request["graphic"]
	-- if param["graphic"] ~= nil and 
	-- 	param["graphic"].imageType ~= "STATIC" and
	-- 	param["graphic"].value ~= nil and
	-- 	param["graphic"].value ~= "" then
	-- 		param["graphic"].value = storagePath ..param["graphic"].value
	-- end	
	
	param["secondaryGraphic"] =  Request["secondaryGraphic"]
	if param["secondaryGraphic"] ~= nil and 
		param["secondaryGraphic"].imageType ~= "STATIC" and
		param["secondaryGraphic"].value ~= nil and
		param["secondaryGraphic"].value ~= "" then
			param["secondaryGraphic"].value = storagePath ..param["secondaryGraphic"].value
	end	
	
	--softButtons
	if Request["softButtons"]  ~= nil then
		param["softButtons"] =  Request["softButtons"]
		for i = 1, #param["softButtons"] do
		
			--if type = TEXT, image = nil, else type = IMAGE, text = nil
			if param["softButtons"][i].type == "TEXT" then			
				param["softButtons"][i].image =  nil

			elseif param["softButtons"][i].type == "IMAGE" then			
				param["softButtons"][i].text =  nil
			end
			
			
			
			--if image.imageType ~=STATIC, add app folder to image value 
			if param["softButtons"][i].image ~= nil and 
				param["softButtons"][i].image.imageType ~= "STATIC" then
				
				param["softButtons"][i].image.value = storagePath ..param["softButtons"][i].image.value
			end
			
		end
	end
	
		
	return param
	
	

end
---------------------------------------------------------------------------------------------

--This function sends a request from mobile and verify result on HMI and mobile for SUCCESS resultCode cases.
function Test:verify_SUCCESS_Case(Request)

	local temp = json.encode(Request)
	local cid = 0
	if string.find(temp, "{}") ~= nil or string.find(temp, "{{}}") ~= nil then						
		temp = string.gsub(temp, "{}", "[]")
		temp = string.gsub(temp, "{{}}", "[{}]")
		
		self.mobileSession.correlationId = self.mobileSession.correlationId + 1

		local msg = 
		{
			serviceType      = 7,
			frameInfo        = 0,
			rpcType          = 0,
			rpcFunctionId    = 13,
			rpcCorrelationId = self.mobileSession.correlationId,				
			payload          = temp
		}

		cid = self.mobileSession.correlationId

		self.mobileSession:Send(msg)
	else
		--mobile side: sending Show request
		cid = self.mobileSession:SendRPC("Show", Request)
	end

	-- TODO: remove after resolving APPLINK-16094
	---------------------------------------------
	if 
		(Request.graphic and
		#Request.graphic == 0) then
			Request.graphic = nil
	end

	if 
		(Request.secondaryGraphic and
		#Request.secondaryGraphic == 0) then
			Request.secondaryGraphic = nil
	end

	if 
		(Request.softButtons and
		#Request.softButtons == 0) then
			Request.softButtons = nil
	end

	if 
		(Request.customPresets and
		#Request.customPresets == 0) then
			Request.customPresets = nil
	end

	if Request.softButtons then
		for i=1,#Request.softButtons do
			if Request.softButtons[i].image then
				Request.softButtons[i].image = nil
			end
		end

	end
	---------------------------------------------
	
	UIParams = self:createUIParameters(Request)

	
	--hmi side: expect UI.Show request
	EXPECT_HMICALL("UI.Show", UIParams)
	:Do(function(_,data)
		--hmi side: sending UI.Show response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)


	--mobile side: expect SetGlobalProperties response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			
end

--This function sends a request from mobile and verify result on HMI and mobile for WARNINGS resultCode cases.
function Test:verify_WARNINGS_invalid_image_Case(Request)

  local temp = json.encode(Request)
  local cid = 0
  if string.find(temp, "{}") ~= nil or string.find(temp, "{{}}") ~= nil then            
    temp = string.gsub(temp, "{}", "[]")
    temp = string.gsub(temp, "{{}}", "[{}]")
    
    self.mobileSession.correlationId = self.mobileSession.correlationId + 1

    local msg = 
    {
      serviceType      = 7,
      frameInfo        = 0,
      rpcType          = 0,
      rpcFunctionId    = 13,
      rpcCorrelationId = self.mobileSession.correlationId,        
      payload          = temp
    }

    cid = self.mobileSession.correlationId

    self.mobileSession:Send(msg)
  else
    --mobile side: sending Show request
    cid = self.mobileSession:SendRPC("Show", Request)
  end

  -- TODO: remove after resolving APPLINK-16094
  ---------------------------------------------
  if 
    (Request.graphic and
    #Request.graphic == 0) then
      Request.graphic = nil
  end

  if 
    (Request.secondaryGraphic and
    #Request.secondaryGraphic == 0) then
      Request.secondaryGraphic = nil
  end

  if 
    (Request.softButtons and
    #Request.softButtons == 0) then
      Request.softButtons = nil
  end

  if 
    (Request.customPresets and
    #Request.customPresets == 0) then
      Request.customPresets = nil
  end

  if Request.softButtons then
    for i=1,#Request.softButtons do
      if Request.softButtons[i].image then
        Request.softButtons[i].image = nil
      end
    end

  end
  ---------------------------------------------
  
  UIParams = self:createUIParameters(Request)

  
  --hmi side: expect UI.Show request
  EXPECT_HMICALL("UI.Show", UIParams)
  :Do(function(_,data)
    --hmi side: sending UI.Show response
    self.hmiConnection:SendResponse(data.id, data.method, "WARNINGS", {info = "Requested image(s) not found."})
  end)


  --mobile side: expect SetGlobalProperties response
  EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS",info = "Requested image(s) not found." })
      
end
---------------------------------------------------------------------------------------------



---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
	
	--1. Activate application
	commonSteps:ActivationApp()

-- ToDO: Uncomment once policy flow implementation is completed 
	-- --2. Policy update
	--policyTable:updatePolicy("files/ptu_general.json")

	
	--3. PutFiles ("a", "icon.png", "action.png", strMaxLengthFileName255)
	commonSteps:PutFile("PutFile_MinLength", "a")
	commonSteps:PutFile("PutFile_icon.png", "icon.png")
	commonSteps:PutFile("PutFile_action.png", "action.png")
	commonSteps:PutFile("PutFile_MaxLength_255Characters", strMaxLengthFileName255)
-----------------------------------------------------------------------------------------
	

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK I----------------------------------------
--------------------------------Check normal cases of Mobile request---------------------------
-----------------------------------------------------------------------------------------------

--Requirement id in JAMA or JIRA: 	
	--SDLAQ-CRS-57: Show_Request_v2_0
	--SDLAQ-CRS-493: SUCCESS
	--SDLAQ-CRS-494: INVALID_DATA
	
--Verification criteria: Verify request with valid and invalid values of parameters.
-----------------------------------------------------------------------------------------------

	--List of parameters in the request:
	--1. mainField1: type=String, maxlength=500, mandatory=false
	--2. mainField2, type=String, maxlength=500, mandatory=false
	--3. mainField3, type=String, maxlength=500, mandatory=false
	--4. mainField4, type=String, maxlength=500, mandatory=false
	--5. statusBar, type=String, maxlength=500, mandatory=false
	--6. mediaClock, type=String, maxlength=500, mandatory=false
	--7. mediaTrack, type=String, maxlength=500, mandatory=false
	--8. alignment, type=TextAlignment, mandatory=false
	--9. graphic, type=Image, mandatory=false
	--10. secondaryGraphic, type=Image, mandatory=false
	--11. softButtons, type=SoftButton, mandatory=false, minsize=0, array=true, maxsize=8
	--12. customPresets, type=String, maxlength=500, mandatory=false, minsize=0, maxsize=8, array=true
	-----------------------------------------------------------------------------------------------

	
-----------------------------------------------------------------------------------------------
--Common Test cases check all parameters with lower bound and upper bound
--1. All parameters are lower bound
--2. All parameters are upper bound
-----------------------------------------------------------------------------------------------

    Test["Show_AllParametersWithInvalidImage_WARNINGS"] = function(self)
  
    --mobile side: request parameters
    local RequestParams = 
    {
      mainField1 = "a",
      mainField2 = "a",
      mainField3 = "a",
      mainField4 = "a",
      statusBar= "a",
      mediaClock = "a",
      mediaTrack = "a",
      alignment = "CENTERED",
      graphic = 
      { 
        imageType = "DYNAMIC",
        value = "invalidimange.png"
      },
      secondaryGraphic = 
      { 
        imageType = "DYNAMIC",
        value = "invalidimange.png"
      },
      softButtons = {},
      customPresets = {},
      metadataTags =
      {
        mainField1 = {},
        mainField2 = {},
        mainField3 = {},
        mainField4 = {}
      }
    }
    
    self:verify_WARNINGS_invalid_image_Case(RequestParams)
    
  end

	Test["Show_AllParametersLowerBound_SUCCESS"] = function(self)
	
		--mobile side: request parameters
		local RequestParams = 
		{
			mainField1 = "a",
			mainField2 = "a",
			mainField3 = "a",
			mainField4 = "a",
			statusBar= "a",
			mediaClock = "a",
			mediaTrack = "a",
			alignment = "CENTERED",
			graphic = 
			{	
				imageType = "DYNAMIC",
				value = "a"
			},
			secondaryGraphic = 
			{	
				imageType = "DYNAMIC",
				value = "a"
			},
			softButtons = {},
			customPresets = {},
			metadataTags =
			{
				mainField1 = {},
				mainField2 = {},
				mainField3 = {},
				mainField4 = {}
			}
		}
		
		self:verify_SUCCESS_Case(RequestParams)
		
	end
	-----------------------------------------------------------------------------------------
	
	Test["Show_AllParametersUpperBound_SUCCESS"] = function(self)
	
		--mobile side: request parameters
		local string500Characters = commonFunctions:createString(500)
		local string499Characters = commonFunctions:createString(499)
		local RequestParams = 
		{
			mainField1 = string500Characters,
			mainField2 = string500Characters,
			mainField3 = string500Characters,
			mainField4 = string500Characters,
			statusBar= string500Characters,
			mediaClock = string500Characters,
			mediaTrack = string500Characters,
			alignment = "CENTERED",
			graphic = 
			{	
				imageType = "DYNAMIC",
				value = strMaxLengthFileName255
			},
			secondaryGraphic = 
			{	
				imageType = "DYNAMIC",
				value = strMaxLengthFileName255
			},
			softButtons = 
			{
				{
					text = "1" .. string499Characters,
					systemAction = "KEEP_CONTEXT",
					type = "BOTH",
					isHighlighted = true,																
					image =
					{
					   imageType = "DYNAMIC",
					   value = strMaxLengthFileName255
					},																
					softButtonID = 1
				},
				{
					text = "2" .. string499Characters,
					systemAction = "KEEP_CONTEXT",
					type = "BOTH",
					isHighlighted = true,																
					image =
					{
					   imageType = "DYNAMIC",
					   value = strMaxLengthFileName255
					},																
					softButtonID = 2
				},
				{
					text = "3" .. string499Characters,
					systemAction = "KEEP_CONTEXT",
					type = "BOTH",
					isHighlighted = true,																
					image =
					{
					   imageType = "DYNAMIC",
					   value = strMaxLengthFileName255
					},																
					softButtonID = 3
				},
				{
					text = "4" .. string499Characters,
					systemAction = "KEEP_CONTEXT",
					type = "BOTH",
					isHighlighted = true,																
					image =
					{
					   imageType = "DYNAMIC",
					   value = strMaxLengthFileName255
					},																
					softButtonID = 4
				},
				{
					text = "5" .. string499Characters,
					systemAction = "KEEP_CONTEXT",
					type = "BOTH",
					isHighlighted = true,																
					image =
					{
					   imageType = "DYNAMIC",
					   value = strMaxLengthFileName255
					},																
					softButtonID = 5
				},
				{
					text = "6" .. string499Characters,
					systemAction = "KEEP_CONTEXT",
					type = "BOTH",
					isHighlighted = true,																
					image =
					{
					   imageType = "DYNAMIC",
					   value = strMaxLengthFileName255
					},																
					softButtonID = 6
				},
				{
					text = "7" .. string499Characters,
					systemAction = "KEEP_CONTEXT",
					type = "BOTH",
					isHighlighted = true,																
					image =
					{
					   imageType = "DYNAMIC",
					   value = strMaxLengthFileName255
					},																
					softButtonID = 7
				},
				{
					text = "8" .. string499Characters,
					systemAction = "KEEP_CONTEXT",
					type = "BOTH",
					isHighlighted = true,																
					image =
					{
					   imageType = "DYNAMIC",
					   value = strMaxLengthFileName255
					},																
					softButtonID = 8
				}
			},
			customPresets = 
			{
				"1" .. string499Characters,
				"2" .. string499Characters,
				"3" .. string499Characters,
				"4" .. string499Characters,
				"5" .. string499Characters,
				"6" .. string499Characters,
				"7" .. string499Characters,
				"8" .. string499Characters,
			},	
			metadataTags =
			{
				mainField1 =
				{
					"mediaTitle",
					"mediaArtist",
					"mediaAlbum",
					"mediaYear",
					"mediaGenre"
				},
				mainField2 =
				{
					"mediaTitle",
					"mediaArtist",
					"mediaAlbum",
					"mediaYear",
					"mediaGenre"
				},
				mainField3 =
				{
					"mediaTitle",
					"mediaArtist",
					"mediaAlbum",
					"mediaYear",
					"mediaGenre"
				},
				mainField4 =
				{
					"mediaTitle",
					"mediaArtist",
					"mediaAlbum",
					"mediaYear",
					"mediaGenre"
				}
			 }
		}
		
		self:verify_SUCCESS_Case(RequestParams)
		
	end
	-----------------------------------------------------------------------------------------

  -----------------------------------------------------------------------------------------
  
  Test["Show_AllParametersUpperBound_WARNINGS"] = function(self)
  
    --mobile side: request parameters
    local string500Characters = commonFunctions:createString(500)
    local string499Characters = commonFunctions:createString(499)
    local RequestParams = 
    {
      mainField1 = string500Characters,
      mainField2 = string500Characters,
      mainField3 = string500Characters,
      mainField4 = string500Characters,
      statusBar= string500Characters,
      mediaClock = string500Characters,
      mediaTrack = string500Characters,
      alignment = "CENTERED",
      graphic = 
      { 
        imageType = "DYNAMIC",
        value = strMaxLengthFileName255
      },
      secondaryGraphic = 
      { 
        imageType = "DYNAMIC",
        value = strMaxLengthFileName255
      },
      softButtons = 
      {
        {
          text = "1" .. string499Characters,
          systemAction = "KEEP_CONTEXT",
          type = "BOTH",
          isHighlighted = true,                               
          image =
          {
             imageType = "DYNAMIC",
             value = strMaxLengthFileName255
          },                                
          softButtonID = 1
        },
        {
          text = "2" .. string499Characters,
          systemAction = "KEEP_CONTEXT",
          type = "BOTH",
          isHighlighted = true,                               
          image =
          {
             imageType = "DYNAMIC",
             value = strMaxLengthFileName255
          },                                
          softButtonID = 2
        },
        {
          text = "3" .. string499Characters,
          systemAction = "KEEP_CONTEXT",
          type = "BOTH",
          isHighlighted = true,                               
          image =
          {
             imageType = "DYNAMIC",
             value = strMaxLengthFileName255
          },                                
          softButtonID = 3
        },
        {
          text = "4" .. string499Characters,
          systemAction = "KEEP_CONTEXT",
          type = "BOTH",
          isHighlighted = true,                               
          image =
          {
             imageType = "DYNAMIC",
             value = strMaxLengthInvalidFileName255
          },                                
          softButtonID = 4
        },
        {
          text = "5" .. string499Characters,
          systemAction = "KEEP_CONTEXT",
          type = "BOTH",
          isHighlighted = true,                               
          image =
          {
             imageType = "DYNAMIC",
             value = strMaxLengthInvalidFileName255
          },                                
          softButtonID = 5
        },
        {
          text = "6" .. string499Characters,
          systemAction = "KEEP_CONTEXT",
          type = "BOTH",
          isHighlighted = true,                               
          image =
          {
             imageType = "DYNAMIC",
             value = strMaxLengthInvalidFileName255
          },                                
          softButtonID = 6
        },
        {
          text = "7" .. string499Characters,
          systemAction = "KEEP_CONTEXT",
          type = "BOTH",
          isHighlighted = true,                               
          image =
          {
             imageType = "DYNAMIC",
             value = strMaxLengthInvalidFileName255
          },                                
          softButtonID = 7
        },
        {
          text = "8" .. string499Characters,
          systemAction = "KEEP_CONTEXT",
          type = "BOTH",
          isHighlighted = true,                               
          image =
          {
             imageType = "DYNAMIC",
             value = strMaxLengthFileName255
          },                                
          softButtonID = 8
        }
      },
      customPresets = 
      {
        "1" .. string499Characters,
        "2" .. string499Characters,
        "3" .. string499Characters,
        "4" .. string499Characters,
        "5" .. string499Characters,
        "6" .. string499Characters,
        "7" .. string499Characters,
        "8" .. string499Characters,
      },  
      metadataTags =
      {
        mainField1 =
        {
          "mediaTitle",
          "mediaArtist",
          "mediaAlbum",
          "mediaYear",
          "mediaGenre"
        },
        mainField2 =
        {
          "mediaTitle",
          "mediaArtist",
          "mediaAlbum",
          "mediaYear",
          "mediaGenre"
        },
        mainField3 =
        {
          "mediaTitle",
          "mediaArtist",
          "mediaAlbum",
          "mediaYear",
          "mediaGenre"
        },
        mainField4 =
        {
          "mediaTitle",
          "mediaArtist",
          "mediaAlbum",
          "mediaYear",
          "mediaGenre"
        }
       }
    }
    
    self:verify_WARNINGS_invalid_image_Case(RequestParams)
    
  end
  -----------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
--Test cases for parameter 1-7: mainField1, mainField2, mainField3, mainField4, statusBar, mediaClock, mediaTrack: type=String, maxlength=500, mandatory=false
-----------------------------------------------------------------------------------------------
--List of test cases for String type parameter:
	--1. IsMissed
	--2. LowerBound
	--3. UpperBound
	--4. OutLowerBound/IsEmpty
	--5. OutUpperBound
	--6. IsWrongType
	--7. IsInvalidCharacters
-----------------------------------------------------------------------------------------------

	local Request = Test:createRequest()
	local Boundary = {0, 500}
	
	
	stringParameter:verify_String_Parameter(Request, {"mainField1"}, Boundary, false)		
	stringParameter:verify_String_Parameter(Request, {"mainField2"}, Boundary, false)	
	stringParameter:verify_String_Parameter(Request, {"mainField3"}, Boundary, false)	
	stringParameter:verify_String_Parameter(Request, {"mainField4"}, Boundary, false)	
	stringParameter:verify_String_Parameter(Request, {"statusBar"}, Boundary, false)	
	stringParameter:verify_String_Parameter(Request, {"mediaClock"}, Boundary, false)	
	stringParameter:verify_String_Parameter(Request, {"mediaTrack"}, Boundary, false)	
	
	
-----------------------------------------------------------------------------------------------
--Test cases for parameter 8: alignment, type=TextAlignment, mandatory=false
-----------------------------------------------------------------------------------------------
--List of test cases for TextAlignment (enumeration) type parameter:
	--1. IsMissed
	--2. IsExistentValues
	--3. IsNonExistentValues
	--4. IsWrongType
	--5. IsEmpty	
-----------------------------------------------------------------------------------------------

	local Request = Test:createRequest()
	local ExistentValues = {"LEFT_ALIGNED", "RIGHT_ALIGNED", "CENTERED"}		
	enumerationParameter:verify_Enum_String_Parameter(Request, {"alignment"}, ExistentValues, false)
	

-----------------------------------------------------------------------------------------------
--List of test cases for parameter 9-10: graphic, secondaryGraphic: type=Image, mandatory=false
-----------------------------------------------------------------------------------------------
--List of test cases for Image type parameter:
	--1. IsMissed
	--2. IsEmpty
	--3. IsWrongType
	--4. ContainsWrongValues
	--5. image.imageType: type=ImageType ("STATIC", "DYNAMIC")
	--6. image.value: type=String, minlength=0 maxlength=65535
-----------------------------------------------------------------------------------------------	

	local Request = Test:createRequest()
	imageParameter:verify_Image_Parameter(Request, {"graphic"}, {"a", strMaxLengthFileName255}, false)
	imageParameter:verify_Image_Parameter(Request, {"secondaryGraphic"}, {"a", strMaxLengthFileName255}, false)
	


-----------------------------------------------------------------------------------------------
--List of test cases for parameter 11: softButtons, type=SoftButton, mandatory=false, minsize=0, array=true, maxsize=8
-----------------------------------------------------------------------------------------------
--List of test cases for softButtons type parameter:
	--1. IsMissed
	--2. IsEmpty
	--3. IsWrongType
	--4. IsLowerBound
	--5. IsUpperBound
	--6. IsOutLowerBound
	--7. IsOutUpperBound
	--8. Check parameters in side a button
		--"type" type="SoftButtonType">
		--"text" minlength="0" maxlength="500" type="String" mandatory="false"
		--"image" type="Image" mandatory="false"
		--"isHighlighted" type="Boolean" defvalue="false" mandatory="false"
		--"softButtonID" type="Integer" minvalue="0" maxvalue="65535"
		--"systemAction" type="SystemAction" defvalue="DEFAULT_ACTION" mandatory="false"
-----------------------------------------------------------------------------------------------		
	
	local Request = Test:createRequest()
	local Boundary = {0, 8}
	arraySoftButtonsParameter:verify_softButtons_Parameter(Request, {"softButtons"}, Boundary, {"a", strMaxLengthFileName255}, false)

	
-----------------------------------------------------------------------------------------------
--List of test cases for parameter 12: customPresets, type=String, maxlength=500, mandatory=false, minsize=0, maxsize=8, array=true
-----------------------------------------------------------------------------------------------
--List of test cases for softButtons type parameter:
	--1. IsMissed
	--2. IsEmpty
	--3. IsWrongType
	--4. IsLowerBound
	--5. IsUpperBound
	--6. IsOutLowerBound
	--7. IsOutUpperBound  
-----------------------------------------------------------------------------------------------

	local Request = {mainField1 = "abc"}
	local ArrayBoundary = {0, 10}
	local ElementBoundary = {1, 500}
	arrayStringParameter:verify_Array_String_Parameter(Request, {"customPresets"}, ArrayBoundary, ElementBoundary, false)

-----------------------------------------------------------------------------------------------
--List of test cases for parameter 13: metadataTags, type=MetadataTags, mandatory=false
-----------------------------------------------------------------------------------------------
--List of test cases for metadataTags type parameter:
	--1. IsMissed
	--2. IsEmpty
	--3. IsWrongType
	--4. IsLowerBound
	--5. IsUpperBound
	--6. IsOutLowerBound
	--7. IsOutUpperBound  
-----------------------------------------------------------------------------------------------

	local Request = Test:createRequest()
	Request.mainField1 = "mainField1"
	Request.mainField2 = "mainField2"
	Request.mainField3 = "mainField3"
	Request.mainField4 = "mainField4"

	metadataTagsParameter:verify_MetadataTags_Parameter(Request, {"metadataTags"}, false)


----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK II----------------------------------------
-----------------------------Check special cases of Mobile request----------------------------
----------------------------------------------------------------------------------------------

--Requirement id in JAMA or JIRA: 	
	--SDLAQ-CRS-57: Show_Request_v2_0
	--SDLAQ-CRS-494: INVALID_DATA
	--SDLAQ-CRS-493: SUCCESS
	--SDLAQ-CRS-921: SoftButtons

-----------------------------------------------------------------------------------------------

--List of test cases for softButtons type parameter:
	--1. InvalidJSON (SDLAQ-CRS-494: INVALID_DATA)
	--2. CorrelationIdIsDuplicated (SDLAQ-CRS-493: SUCCESS)
	--3. FakeParams and FakeParameterIsFromAnotherAPI (APPLINK-14765 SDL must cut off the fake parameters from requests, responses and notifications received from HMI)
	--4. MissedAllParameters (SDLAQ-CRS-494: INVALID_DATA)
-----------------------------------------------------------------------------------------------

local function SpecialRequestChecks()
end 
--Begin Test case NegativeRequestCheck
--Description: Check negative request


	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("TestCaseGroupForAbnormal")
	
	--Begin Test case NegativeRequestCheck.1
	--Description: Invalid JSON
	
		--replace ":' by ";"
		--local Payload = '{"softButtons";{{"softButtonID":3,"type":"BOTH","text":"Close","systemAction":"DEFAULT_ACTION","isHighlighted":true,"image":{"imageType":"DYNAMIC","value":"icon.png"}},{"softButtonID":4,"type":"TEXT","text":"Keep","systemAction":"KEEP_CONTEXT","isHighlighted":true},{"softButtonID":5,"type":"IMAGE","systemAction":"STEAL_FOCUS","image":{"imageType":"DYNAMIC","value":"icon.png"}}},"ttsChunks":{{"type":"TEXT","text":"TTSChunk"}},"progressIndicator":true,"playTone":true,"alertText2":"alertText2","alertText1":"alertText1","duration":3000,"alertText3" "alertText3"}'
		-- local Payload = '{"softButtons";{
		-- 									{"softButtonID":3,
		-- 									 "type":"BOTH",
		-- 									 "text":"Close",
		-- 									 "systemAction":"DEFAULT_ACTION",
		-- 									 "isHighlighted":true,
		-- 									 },
		-- 									{"softButtonID":4,
		-- 									 "type":"TEXT",
		-- 									 "text":"Keep",
		-- 									 "systemAction":"KEEP_CONTEXT",
		-- 									 "isHighlighted":true},
		-- 									{"softButtonID":5,
		-- 									 "type":"IMAGE",
		-- 									 "systemAction":"STEAL_FOCUS",
		-- 									}
		-- 								 },
		-- 					"ttsChunks":{{"type":"TEXT","text":"TTSChunk"}},
		-- 					"progressIndicator":true,
		-- 					"playTone":true,
		-- 					"alertText2":"alertText2",
		-- 					"alertText1":"alertText1",
		-- 					"duration":3000,
		-- 					"alertText3" 
		-- 					"alertText3"}'
		
		commonTestCases:VerifyInvalidJsonRequest(13, Payload)	

	--End Test case NegativeRequestCheck.1


	--Begin Test case NegativeRequestCheck.2
	--Description: Check CorrelationId duplicate value
		--[[ToDo: APPLINK-13892 ATF: Send(msg) convert parameter in quote ("xxx") to \"
		--
		function Test:Show_CorrelationIdIsDuplicated()
		
			--mobile side: sending Show request
			local cid = self.mobileSession:SendRPC("Show",
			{
				mainField1 = "Show1"
			})
			
			--request from mobile side
			local msg = 
			{
			  serviceType      = 7,
			  frameInfo        = 0,
			  rpcType          = 0,
			  rpcFunctionId    = 13,
			  rpcCorrelationId = cid,
			  payload          = '{"mainField2":"Show2"}'
			}
			
			
			--hmi side: expect UI.Show request
			EXPECT_HMICALL("UI.Show",
							{
								showStrings = 
								{							
									{
										fieldName = "mainField1",
										fieldText = "Show1"
									}
								}
							},
							{
								showStrings = 
								{							
									{
										fieldName = "mainField2",
										fieldText = "Show2"
									}
								}
							}
							)
			:Do(function(exp,data)
				if exp.occurences == 1 then
					self.mobileSession:Send(msg)
				end

				--hmi side: sending UI.Show response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			:Times(2)
			
			--response on mobile side
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
			:Times(2)
			
		end
	]]
	--End Test case NegativeRequestCheck.2

	
	--Begin Test case NegativeRequestCheck.3
	--Description: Fake parameters check
	
		--Requirement id in JAMA: APPLINK-14765 SDL must cut off the fake parameters from requests, responses and notifications received from HMI
		--Verification criteria: SDL must cut off the fake parameters from requests, responses and notifications received from HMI

		--Begin Test case NegativeRequestCheck.3.1
		--Description: Fake parameters is not from any API
	
		function Test:Show_FakeParams_IsNotFromAnyAPI()						

			--mobile side: sending Show request	
			local param  = 	{
								mediaClock = "00:00:01",
								mainField1 = "Show1",
								fakeParam = "icon.png",
								graphic =
								{
									value = "action.png",
									imageType = "DYNAMIC",
									fakeParam = "icon.png",
								},
								softButtons =
								{
									{
										text = "Close",
										systemAction = "DEFAULT_ACTION",
										type = "BOTH",
										isHighlighted = true,																
										image =
										{
										   imageType = "DYNAMIC",
										   value = "icon.png"
										},																
										softButtonID = 3,
										fakeParam = "icon.png",
									}
								},
								customPresets =
								{
									"Preset1",
									"Preset2",
									"Preset3"													
								}
							}
			
							
			local cid = self.mobileSession:SendRPC("Show", param)
			
			param.fakeParam = nil 
			param.graphic.fakeParam = nil
			param.softButtons[1].fakeParam = nil

			-- TODO: remove after resolving APPLINK-16052
			param.softButtons[1].image = nil
			---------------------------------------------
			
			--hmi side: expect the request
			UIParams = self:createUIParameters(param)
			EXPECT_HMICALL("UI.Show", UIParams)
			:ValidIf(function(_,data)

				local result = true
				if data.params.fakeParam or 
					data.params.graphic.fakeParam or
					data.params.softButtons.fakeParam or
					data.params.softButtons[1].fakeParam then
						commonFunctions:printError(" SDL re-sends fakeParam parameters to HMI")
						result =false
				else 				
				
				end

				local path  = "bin/storage/"..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"
                local value_Icon = path .. "action.png"
          
                if(data.params.graphic.imageType == "DYNAMIC") then
                    
                else
                    print("\27[31m imageType of menuIcon is WRONG. Expected: DYNAMIC; Real: " .. data.params.graphic.imageType .. "\27[0m")
                    resullt = false
                end

                if(string.find(data.params.graphic.value, value_Icon) ) then
                    
                else
                    print("\27[31m value of menuIcon is WRONG. Expected: ~".. value_Icon .. "; Real: " .. data.params.graphic.value .. "\27[0m")
                    result = false
                end

				return result
			end)
			:Do(function(_,data)
				--hmi side: sending the response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			
			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			
		end						
		
		
		--End Test case NegativeRequestCheck.3.1
		-----------------------------------------------------------------------------------------

		--Begin Test case NegativeRequestCheck.3.2
		--Description: Fake parameters is not from another API
		
		function Test:Show_FakeParameterIsFromAnotherAPI()						

			--mobile side: sending Show request		
			local param  = 	{
								mediaClock = "00:00:01",
								mainField1 = "Show1",
								syncFileName = "icon.png",
								graphic =
								{
									value = "action.png",
									imageType = "DYNAMIC",
									syncFileName = "icon.png",
								},
								softButtons =
								{
									{
										text = "Close",
										systemAction = "DEFAULT_ACTION",
										type = "BOTH",
										isHighlighted = true,																
										image =
										{
										   imageType = "DYNAMIC",
										   value = "icon.png"
										},																
										softButtonID = 3,
										syncFileName = "icon.png",
									}
								},
								customPresets =
								{
									"Preset1",
									"Preset2",
									"Preset3"													
								}
							}
							
			local cid = self.mobileSession:SendRPC("Show", param)
			
			param.syncFileName = nil 
			param.graphic.syncFileName = nil
			param.softButtons[1].syncFileName = nil

			-- TODO: remove after resolving APPLINK-16052
			param.softButtons[1].image = nil
			---------------------------------------------
			
			--hmi side: expect the request
			UIParams = self:createUIParameters(param)
			EXPECT_HMICALL("UI.Show", UIParams)
			:ValidIf(function(_,data)
				if data.params.syncFileName or 
					data.params.graphic.syncFileName or
					data.params.softButtons[1].syncFileName then
						commonFunctions:printError(" SDL re-sends syncFileName parameters of SetAppIcon request to HMI")
						return false
				else 
					return true
				end
			end)
			:Do(function(_,data)
				--hmi side: sending the response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			
			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			
		end	
			
		--End Test case NegativeRequestCheck.3.2
		-----------------------------------------------------------------------------------------
		
	--End Test case NegativeRequestCheck.3


	--Begin Test case NegativeRequestCheck.4
	--Description: All parameters missing
	
		--Requirement id in JAMA: SDLAQ-CRS-494
		--Verification criteria: "3.1. The request with no parameters is sent, the response with INVALID_DATA result code is returned."

		commonTestCases:VerifyRequestIsMissedAllParameters()
		
	--End Test case NegativeRequestCheck.4

	-----------------------------------------------------------------------------------------
     
        --Start Test case NegativeRequestCheck.5 
            
        -- SDLAQ-CRS-921->1 
        --Begin Test case NegativeRequestCheck.5.1
	--Begin Test case NegativeRequestCheck.5.1.1
	--Description: SoftButtonType is IMAGE and image paramer is wrong -> the request will be rejected as INVALID_DATA

			function Test:Show_IMAGESoftButton_AndImageWrong()

				--mobile side: sending the request

				local Request = 	{
								mediaClock = "00:00:01",
								mainField1 = "Show1",
								softButtons =
								{
									{
										text = "Close",
										systemAction = "DEFAULT_ACTION",
										type = "IMAGE",
										isHighlighted = true,																
										image =
										{
										   imageType = "DYNAMIC",
										   value = 123                 ---123 is wrong, "icon.png" is correct
										},																
										softButtonID = 1
									}
								}
							}

				local cid = self.mobileSession:SendRPC("Show", Request)
									
				--hmi side: expect the request
				local UIParams = self:createUIParameters(Request)
				EXPECT_HMICALL("UI.Show", UIParams)
                                :Times(0)		
							
				--mobile side: expect response 
				EXPECT_RESPONSE(cid, {  success = false, resultCode = "INVALID_DATA"})
				
			end

	--End Test case NegativeRequestCheck.5.1.1


        --Begin Test case NegativeRequestCheck.5.1.2
	--Description: SoftButtonType is IMAGE and image paramer is not defined -> the request will receive INVALID_DATA

		function Test:Show_IMAGESoftButton_AndImageNotDefined()

				--mobile side: sending the request

				local Request = 	{
								mediaClock = "00:00:01",
								mainField1 = "Show1",
								softButtons =
								{
									{
										text = "Close",
										systemAction = "DEFAULT_ACTION",
										type = "IMAGE",
										isHighlighted = true,																
	
										softButtonID = 1
									}
								}
							}

				local cid = self.mobileSession:SendRPC("Show", Request)
									
				--hmi side: expect the request
				local UIParams = self:createUIParameters(Request)
				EXPECT_HMICALL("UI.Show", UIParams)
                                :Times(0)		
							
				--mobile side: expect response 
				EXPECT_RESPONSE(cid, {  success = false, resultCode = "INVALID_DATA"})

         
		end
	--End Test case NegativeRequestCheck.5.1.2
       --End Test case NegativeRequestCheck.5.1

---------------------------------------------------------------------------------------------------
     
	-- SDLAQ-CRS-921->2
	--Begin Test case NegativeRequestCheck.5.2
	--Description:  Mobile sends SoftButtons with Text=“” (empty string) and Type=TEXT, SDL rejects it as INVALID_DATA 

		
	function Test:Show_TEXTSoftButton_AndEmptyText()

				--mobile side: sending the request

				local Request = 	{
								mediaClock = "00:00:01",
								mainField1 = "Show1",
								softButtons =
								{
									{
										text = "", --text is empty string
										systemAction = "DEFAULT_ACTION",
										type = "TEXT",
										isHighlighted = true,																
										image =
										{
										   imageType = "DYNAMIC",
										   value = "icon.png"                
										},	
										softButtonID = 1
									}
								}
							}

				local cid = self.mobileSession:SendRPC("Show", Request)
									
				--hmi side: expect the request
				local UIParams = self:createUIParameters(Request)
				EXPECT_HMICALL("UI.Show", UIParams)
                                :Times(0)		
							
				--mobile side: expect response 
				EXPECT_RESPONSE(cid, {  success = false, resultCode = "INVALID_DATA"})
				
			end


	--End Test case NegativeRequestCheck.5.2

------------------------------------------------------------------------------------------------

  	-- SDLAQ-CRS-921->3
	--Begin Test case NegativeRequestCheck.5.3
	--Description:  Mobile sends SoftButtons with Type=TEXT that exclude 'Text' parameter, SDL rejects it as INVALID_DATA 

		function Test:Show_TEXTSoftButton_AndTextExcluded()

				--mobile side: sending the request

				local Request = 	{
								mediaClock = "00:00:01",
								mainField1 = "Show1",
								softButtons =
								{
									{
										--text is excluded
										systemAction = "DEFAULT_ACTION",
										type = "TEXT",
										isHighlighted = true,																
										image =
										{
										   imageType = "DYNAMIC",
										   value = "icon.png"                
										},	
										softButtonID = 1
									}
								}
							}

				local cid = self.mobileSession:SendRPC("Show", Request)
									
				--hmi side: expect the request
				local UIParams = self:createUIParameters(Request)
				EXPECT_HMICALL("UI.Show", UIParams)
                                :Times(0)		
							
				--mobile side: expect response 
				EXPECT_RESPONSE(cid, {  success = false, resultCode = "INVALID_DATA"})
				
			end

	--End Test case NegativeRequestCheck.5.3

---------------------------------------------------------------------------------------------

	-- SDLAQ-CRS-921->4
	--Begin Test case NegativeRequestCheck.5.4
	--Begin Test case NegativeRequestCheck.5.4.1
	--Description:  Mobile sends SoftButtons with Type=BOTH and 'text' is wrong, SDL rejects it as INVALID_DATA 

		function Test:Show_BOTHSoftButton_AndTextIsWrong()

				--mobile side: sending the request

				local Request = 	{
								mediaClock = "00:00:01",
								mainField1 = "Show1",
								softButtons =
								{
									{
										text = 123,                     --text value is wrong
										systemAction = "DEFAULT_ACTION",
										type = "BOTH",
										isHighlighted = true,																
										image =
										{
										   imageType = "DYNAMIC",
										   value = "icon.png"                
										},	
										softButtonID = 1
									}
								}
							}

				local cid = self.mobileSession:SendRPC("Show", Request)
									
				--hmi side: expect the request
				local UIParams = self:createUIParameters(Request)
				EXPECT_HMICALL("UI.Show", UIParams)
                                :Times(0)		
							
				--mobile side: expect response 
				EXPECT_RESPONSE(cid, {  success = false, resultCode = "INVALID_DATA"})
				
			end

	--End Test case NegativeRequestCheck.5.4.1
     

        --Begin Test case NegativeRequestCheck.5.4.2
	--Description:  Mobile sends SoftButtons with Type=BOTH and 'text' not defined, SDL rejects it as INVALID_DATA 

		function Test:Show_BOTHSoftButtonAndTextIsNotDefined()

			--mobile side: sending the request

				local Request = 	{
								mediaClock = "00:00:01",
								mainField1 = "Show1",
								softButtons =
								{
									{
										                   
										type = "BOTH",
										isHighlighted = true,																
										image =
										{
										   imageType = "DYNAMIC",
										   value = "icon.png"                
										},	
										softButtonID = 1
									}
								}
							}

				local cid = self.mobileSession:SendRPC("Show", Request)
									
				--hmi side: expect the request
				local UIParams = self:createUIParameters(Request)
				EXPECT_HMICALL("UI.Show", UIParams)
                                :Times(0)		
							
				--mobile side: expect response 
				EXPECT_RESPONSE(cid, {  success = false, resultCode = "INVALID_DATA"})
				
			end

	--End Test case NegativeRequestCheck.5.4.2

	--Begin Test case NegativeRequestCheck.5.4.3
	--Description:  Mobile sends SoftButtons with Type=BOTH and 'image' is wrong, SDL rejects it as INVALID_DATA 

		function Test:Show_BOTHSoftButton_AndImageValueIsWrong()

				--mobile side: sending the request

				local Request = 	{
								mediaClock = "00:00:01",
								mainField1 = "Show1",
								softButtons =
								{
									{
										text = "First",                     
										systemAction = "DEFAULT_ACTION",
										type = "BOTH",
										isHighlighted = true,																
										image =
										{
										   imageType = "DYNAMIC",
										   value = 123               --image value is wrong     
										},	
										softButtonID = 1
									}
								}
							}

				local cid = self.mobileSession:SendRPC("Show", Request)
									
				--hmi side: expect the request
				local UIParams = self:createUIParameters(Request)
				EXPECT_HMICALL("UI.Show", UIParams)
                                :Times(0)		
							
				--mobile side: expect response 
				EXPECT_RESPONSE(cid, {  success = false, resultCode = "INVALID_DATA"})
				
			end

	--End Test case NegativeRequestCheck.5.4.3

        --Begin Test case NegativeRequestCheck.5.4.4
	--Description:  Mobile sends SoftButtons with Type=BOTH and 'image' not defined, SDL rejects it as INVALID_DATA 

	function Test:Show_BOTHSoftButtonAndImageIsNotDefined()

			--mobile side: sending the request

				local Request = 	{
								mediaClock = "00:00:01",
								mainField1 = "Show1",
								softButtons =
								{
									{
										text = "First",
                                                                                systemAction = "DEFAULT_ACTION",                    
										type = "BOTH",
										isHighlighted = true,												
										softButtonID = 1
									}
								}
							}

				local cid = self.mobileSession:SendRPC("Show", Request)
									
				--hmi side: expect the request
				local UIParams = self:createUIParameters(Request)
				EXPECT_HMICALL("UI.Show", UIParams)
                                :Times(0)		
							
				--mobile side: expect response 
				EXPECT_RESPONSE(cid, {  success = false, resultCode = "INVALID_DATA"})
				
			end

	--End Test case NegativeRequestCheck.5.4.4

      --End Test case NegativeRequestCheck.5.4


 	-- SDLAQ-CRS-921->8
	--Begin Test case NegativeRequestCheck.5.5
	--Description:  Mobile sends SoftButtons with Type=IMAGE and with invalid value of 'text' parameter, SDL rejects it as INVALID_DATA 

		function Test:Show_IMAGESoftButtonAndInvalidText()

			--mobile side: sending the request

				local Request = 	{
								mediaClock = "00:00:01",
								mainField1 = "Show1",
								softButtons =
								{
									{
										text = 123, --invalid text value
                                                                                systemAction = "DEFAULT_ACTION",                    
										type = "IMAGE",
										isHighlighted = true,																
										image =
										{
										   imageType = "DYNAMIC",
										   value = "icon.png"         
										},                           	
										softButtonID = 1
									}
								}
							}

				local cid = self.mobileSession:SendRPC("Show", Request)
									
				--hmi side: expect the request
				local UIParams = self:createUIParameters(Request)
				EXPECT_HMICALL("UI.Show", UIParams)
                                :Times(0)		
							
				--mobile side: expect response 
				EXPECT_RESPONSE(cid, {  success = false, resultCode = "INVALID_DATA"})
				
			end

	 --End Test case NegativeRequestCheck.5.5

      -- SDLAQ-CRS-921->9
	--Begin Test case NegativeRequestCheck.5.6
	--Description:  Mobile sends SoftButtons with Type=TEXT and with invalid value of 'image', SDL rejects it as INVALID_DATA 

		function Test:Show_TEXTSoftButtonAndInvalidImageValue()

			--mobile side: sending the request

				local Request = 	{
								mediaClock = "00:00:01",
								mainField1 = "Show1",
								softButtons =
								{
									{
										text = "First",
                                                                                systemAction = "DEFAULT_ACTION",                    
										type = "TEXT",
										isHighlighted = true,																
										image =
										{
										   imageType = "DYNAMIC",
										   value = 123             --invalid image parameter         
										},                           	
										softButtonID = 1
									}
								}
							}

				local cid = self.mobileSession:SendRPC("Show", Request)
									
				--hmi side: expect the request
				local UIParams = self:createUIParameters(Request)
				EXPECT_HMICALL("UI.Show", UIParams)
                                :Times(0)		
							
				--mobile side: expect response 
				EXPECT_RESPONSE(cid, {  success = false, resultCode = "INVALID_DATA"})
				
			end

	 --End Test case NegativeRequestCheck.5.6


------------------------------------------------------------------------------------------

--End Test case NegativeRequestCheck


--Begin Test case PositiveRequestCheck
--Description: Check special positive request

     --Start Test case PositiveRequestCheck.1

          -- SDLAQ-CRS-921->5
	  --Begin Test case PositiveRequestCheck.1.1
	  --Description:  Mobile sends SoftButtons with Text=“” (empty string) and Type=BOTH, SDL must transfer to HMI, the resultCode returned to mobile app must depend on resultCode from HMI`s response.

         	function Test:Show_BOTHSoftButton_AndTextEmpty()				

			--mobile side: sending Show request	
			local param  = 	{
								mediaClock = "00:00:01",
								mainField1 = "Show1",	
								softButtons =
								{
									{
										text = "",                         --text is empty
										systemAction = "DEFAULT_ACTION",
										type = "BOTH",
										isHighlighted = true,																
										image =
										{
										   imageType = "DYNAMIC",
										   value = "icon.png"
										},																
										softButtonID = 3
									}
								}
							}
			
							
			local cid = self.mobileSession:SendRPC("Show", param)
			
			-- TODO: remove after resolving APPLINK-16052
			param.softButtons[1].image = nil
			---------------------------------------------
			
			--hmi side: expect the request
			UIParams = self:createUIParameters(param)
			EXPECT_HMICALL("UI.Show", UIParams)


			:Do(function(_,data)
				--hmi side: sending the response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			
			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			
		end						

          --End Test case PositiveRequestCheck.1.1

	  -- SDLAQ-CRS-921->6
	  --Begin Test case PositiveRequestCheck.1.2

	  --Begin Test case PositiveRequestCheck.1.2.1
	  --Description:  Mobile sends SoftButtons with Type=TEXT and omitted image, SDL must omit image in request to HMI, the resultCode returned to mobile app must depend on resultCode from HMI`s response.

         	function Test:Show_TEXTSoftButton_AndImageOmitted()				

			--mobile side: sending Show request	
			local param  = 	{
								mediaClock = "00:00:01",
								mainField1 = "Show1",	
								softButtons =
								{
									{
										text = "First",                        
										systemAction = "DEFAULT_ACTION",
										type = "TEXT",
										isHighlighted = true,																
														--image is omitted												
										softButtonID = 3
									}
								}
							}
			
							
			local cid = self.mobileSession:SendRPC("Show", param)
			
			-- TODO: remove after resolving APPLINK-16052
			param.softButtons[1].image = nil
			---------------------------------------------
			
			--hmi side: expect the request
			UIParams = self:createUIParameters(param)
			EXPECT_HMICALL("UI.Show", UIParams)


			:Do(function(_,data)
				--hmi side: sending the response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			
			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			
		end		

          --End Test case PositiveRequestCheck.1.2.1

          --Begin Test case PositiveRequestCheck.1.2.2
	  --Description:  Mobile sends SoftButtons with Type=TEXT and valid image, SDL must omit image in request to HMI, the resultCode returned to mobile app must depend on resultCode from HMI`s response.

         	function Test:Show_TEXTSoftButton_AndImageValid()				

			--mobile side: sending Show request	
			local param  = 	{
								mediaClock = "00:00:01",
								mainField1 = "Show1",	
								softButtons =
								{
									{
										text = "First",                        
										systemAction = "DEFAULT_ACTION",
										type = "TEXT",
										isHighlighted = true,																
										image =
										{
										   imageType = "DYNAMIC",
										   value = "icon.png"
										},																
										softButtonID = 3
									}
								}
							}
			
							
			local cid = self.mobileSession:SendRPC("Show", param)
			
			-- TODO: remove after resolving APPLINK-16052
			param.softButtons[1].image = nil
			---------------------------------------------
			
			--hmi side: expect the request
			UIParams = self:createUIParameters(param)
			EXPECT_HMICALL("UI.Show", UIParams)


			:Do(function(_,data)
				--hmi side: sending the response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			
			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			
		end		

          --End Test case PositiveRequestCheck.1.2.2

	--Begin Test case PositiveRequestCheck.1.2.3
	  --Description:  Mobile sends SoftButtons with Type=TEXT and not-defined image, SDL must omit image in request to HMI, the resultCode returned to mobile app must depend on resultCode from HMI`s response.

         	function Test:Show_TEXTSoftButton_AndImageNotDefined()				

			--mobile side: sending Show request	
			local param  = 	{
								mediaClock = "00:00:01",
								mainField1 = "Show1",	
								softButtons =
								{
									{
										text = "First",                        
										systemAction = "DEFAULT_ACTION",
										type = "TEXT",
										isHighlighted = true,  																
										softButtonID = 3
									}
								}
							}
			
							
			local cid = self.mobileSession:SendRPC("Show", param)
			
			-- TODO: remove after resolving APPLINK-16052
			param.softButtons[1].image = nil
			---------------------------------------------
			
			--hmi side: expect the request
			UIParams = self:createUIParameters(param)
			EXPECT_HMICALL("UI.Show", UIParams)


			:Do(function(_,data)
				--hmi side: sending the response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			
			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			
		end      

          --End Test case PositiveRequestCheck.1.2.3
     --End Test case PositiveRequestCheck.1.2


 	  -- SDLAQ-CRS-921->7
	  --Begin Test case PositiveRequestCheck.1.3
	  --Begin Test case PositiveRequestCheck.1.3.1
	  --Description:  Mobile sends SoftButtons with Type=IMAGE and valid text, SDL must omit text in request to HMI, the resultCode returned to mobile app must depend on resultCode from HMI`s response.

         	function Test:Show_IMAGESoftButton_AndValidText()				

			--mobile side: sending Show request	
			local param  = 	{
								mediaClock = "00:00:01",
								mainField1 = "Show1",	
								softButtons =
								{
									{
										text = "First",                        
										systemAction = "DEFAULT_ACTION",
										type = "IMAGE",
										isHighlighted = true,																
										image =  
                                                      					{ 
                                                         					value = "icon.png",                         
                                                        					imageType = "DYNAMIC"
                                                     					 },  																
										softButtonID = 3
									}
								}
							}
			
							
			local cid = self.mobileSession:SendRPC("Show", param)
			
			-- TODO: remove after resolving APPLINK-16052
			param.softButtons[1].image = nil
			---------------------------------------------
			
			--hmi side: expect the request
			UIParams = self:createUIParameters(param)
			EXPECT_HMICALL("UI.Show", UIParams)


			:Do(function(_,data)
				--hmi side: sending the response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			
			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			
		end

          --End Test case PositiveRequestCheck.1.3.1

          --Begin Test case PositiveRequestCheck.1.3.2
	  --Description:  Mobile sends SoftButtons with Type=IMAGE and omitted text, SDL must omit text in request to HMI, the resultCode returned to mobile app must depend on resultCode from HMI`s response.

         	function Test:Show_IMAGESoftButton_AndTextOmitted()				

			--mobile side: sending Show request	
			local param  = 	{
								mediaClock = "00:00:01",
								mainField1 = "Show1",	
								softButtons =
								{
									{
														-- text is omitted	                       
										systemAction = "DEFAULT_ACTION",
										type = "IMAGE",
										isHighlighted = true,																
										image =  
                                                      					{ 
                                                         					value = "icon.png",                         
                                                        					imageType = "DYNAMIC"
                                                     					 },  																
										softButtonID = 3
									}
								}
							}
			
							
			local cid = self.mobileSession:SendRPC("Show", param)
			
			-- TODO: remove after resolving APPLINK-16052
			param.softButtons[1].image = nil
			---------------------------------------------
			
			--hmi side: expect the request
			UIParams = self:createUIParameters(param)
			EXPECT_HMICALL("UI.Show", UIParams)


			:Do(function(_,data)
				--hmi side: sending the response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			
			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			
		end

          --End Test case PositiveRequestCheck.1.3.2

          --Begin Test case PositiveRequestCheck.1.3.3
	  --Description:  Mobile sends SoftButtons with Type=IMAGE and not-defined text, SDL must omit text in request to HMI, the resultCode returned to mobile app must depend on resultCode from HMI`s response.

         	function Test:Show_IMAGESoftButton_AndNotDefinedText()				

			--mobile side: sending Show request	
			local param  = 	{
								mediaClock = "00:00:01",
								mainField1 = "Show1",	
								softButtons =
								{
									{
										                
										systemAction = "DEFAULT_ACTION",
										type = "IMAGE",
										isHighlighted = true,																
										image =  
                                                      					{ 
                                                         					value = "icon.png",                         
                                                        					imageType = "DYNAMIC"
                                                     					 },  																
										softButtonID = 3
									}
								}
							}
			
							
			local cid = self.mobileSession:SendRPC("Show", param)
			
			-- TODO: remove after resolving APPLINK-16052
			param.softButtons[1].image = nil
			---------------------------------------------
			
			--hmi side: expect the request
			UIParams = self:createUIParameters(param)
			EXPECT_HMICALL("UI.Show", UIParams)


			:Do(function(_,data)
				--hmi side: sending the response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			
			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			
		end

          --End Test case PositiveRequestCheck.1.3.1
       --End Test case PositiveRequestCheck.1.3

--End Test case PositiveRequestCheck

--end	
		--Begin Test case Show_MetadataTags_withNoFieldsProvided
	--Description: metadataTag parameter is provided, but no corresponding "mainField" is provided -> the request will receive a WARNINGS result code

		function Test:Show_MetadataTags_withNoFieldsProvided()

				--mobile side: sending the request

				local Request = {
									metadataTags = {
										mainField1 = {"mediaTitle"}
									}
								}
				local cid = self.mobileSession:SendRPC("Show", Request)
									
				--hmi side: expect the request
				local UIParams = self:createUIParameters(Request)
				EXPECT_HMICALL("UI.Show", UIParams)
								:Times(1)
							
				:Do(function(_,data)
					--hmi side: sending the response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)

				--mobile side: expect response 
				EXPECT_RESPONSE(cid, {  success = true, resultCode = "WARNINGS"})

		end
	--End Test case Show_MetadataTags_withNoFieldsProvided

SpecialRequestChecks()

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK III--------------------------------------
----------------------------------Check normal cases of HMI response---------------------------
-----------------------------------------------------------------------------------------------

--Requirement id in JAMA: SDLAQ-CRS-58: Show_Response_v2_0
--Verification Criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode

--Common Test cases for Response
--1. Check all mandatory parameters are missed
--2. Check all parameters are missed

--Print new line to separate new test cases group
commonFunctions:newTestCasesGroup("TestCaseGroupForResultCodeParameter")

--[=[ToDo: update according to APPLINK-13101
Test[APIName.."_Response_MissingMandatoryParameters_GENERIC_ERROR"] = function(self)

	--mobile side: sending the request
	local Request = Test:createRequest()
	local cid = self.mobileSession:SendRPC("Show", Request)

	
	--hmi side: expect the request
	UIParams = self:createUIParameters(Request)
	
	EXPECT_HMICALL("UI.Show", UIParams)
	:Do(function(_,data)
		--hmi side: sending the response
		--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.Show", "code":0}}')
		  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{}}')
	end)


	--mobile side: expect the response
	EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
	:Timeout(13000)
	
end
-----------------------------------------------------------------------------------------
	

Test[APIName.."_Response_MissingAllParameters_GENERIC_ERROR"] = function(self)

	--mobile side: sending the request
	local Request = Test:createRequest()
	local cid = self.mobileSession:SendRPC("Show", Request)

	
	--hmi side: expect the request
	UIParams = self:createUIParameters(Request)
	
	EXPECT_HMICALL("UI.Show", UIParams)
	:Do(function(_,data)
		--hmi side: sending the response
		--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.Show", "code":0}}')
		  self.hmiConnection:Send('{}')
	end)


	--mobile side: expect the response
	EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
	:Timeout(13000)
	
end
-----------------------------------------------------------------------------------------

]=]


-----------------------------------------------------------------------------------------------
--Parameter 1: resultCode
-----------------------------------------------------------------------------------------------
--List of test cases: 
	--1. IsMissed
	--2. IsValidValues
	--3. IsNotExist
	--4. IsEmpty
	--5. IsWrongType
	--6. IsInvalidCharacter - \n, \t
-----------------------------------------------------------------------------------------------

local function verify_resultCode_parameter()


	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("TestCaseGroupForResultCodeParameter")
	-----------------------------------------------------------------------------------------
	
	--1. IsMissed
	Test[APIName.."_Response_resultCode_IsMissed_SendResponse"] = function(self)
	
		--mobile side: sending the request
		local Request = Test:createRequest()
		local cid = self.mobileSession:SendRPC("Show", Request)

		
		--hmi side: expect the request
		UIParams = self:createUIParameters(Request)
		
		EXPECT_HMICALL("UI.Show", UIParams)
		:Do(function(_,data)
			--hmi side: sending the response
			--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.Show", "code":0}}')
			  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.Show"}}')
		end)


		--mobile side: expect the response
		-- TODO: update after resolving APPLINK-14765
		-- EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
		
	end
	-----------------------------------------------------------------------------------------
	
	Test[APIName.."_Response_resultCode_IsMissed_SendError"] = function(self)
	
		--mobile side: sending the request
		local Request = Test:createRequest()
		local cid = self.mobileSession:SendRPC("Show", Request)

		
		--hmi side: expect the request
		UIParams = self:createUIParameters(Request)
		
		EXPECT_HMICALL("UI.Show", UIParams)
		:Do(function(_,data)
			--hmi side: sending the response
			--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.Show","code":0}}')
			  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.Show"}}')			
		end)


		--mobile side: expect the response
		-- TODO: update after resolving APPLINK-14765
		-- EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
		
	end
	-----------------------------------------------------------------------------------------
	
	
	
	--2. IsValidValue
	local resultCodes = {
		{resultCode = "SUCCESS", success =  true},
		{resultCode = "INVALID_DATA", success =  false},
		{resultCode = "OUT_OF_MEMORY", success =  false},
		{resultCode = "TOO_MANY_PENDING_REQUESTS", success =  false},
		{resultCode = "APPLICATION_NOT_REGISTERED", success =  false},
		{resultCode = "GENERIC_ERROR", success =  false},
		{resultCode = "REJECTED", success =  false},
		{resultCode = "DISALLOWED", success =  false},
		{resultCode = "UNSUPPORTED_RESOURCE", success =  false},
		{resultCode = "ABORTED", success =  false}
	}
		
	for i =1, #resultCodes do
	
		Test[APIName.."_resultCode_IsValidValues_" .. resultCodes[i].resultCode .."_SendResponse"] = function(self)
			
			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("Show", Request)
			
			--hmi side: expect the request
			UIParams = self:createUIParameters(Request)
			
			EXPECT_HMICALL("UI.Show", UIParams)
			:Do(function(_,data)
				--hmi side: sending the response
				self.hmiConnection:SendResponse(data.id, data.method, resultCodes[i].resultCode, {})
			end)

			--mobile side: expect SetGlobalProperties response
			EXPECT_RESPONSE(cid, { success = resultCodes[i].success, resultCode = resultCodes[i].resultCode})							

		end		
		-----------------------------------------------------------------------------------------
		
		Test[APIName.."_resultCode_IsValidValues_" .. resultCodes[i].resultCode .."_SendError"] = function(self)
			
			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("Show", Request)
			
			--hmi side: expect the request
			UIParams = self:createUIParameters(Request)
			
			EXPECT_HMICALL("UI.Show", UIParams)
			:Do(function(_,data)
				--hmi side: sending the response
				self.hmiConnection:SendError(data.id, data.method, resultCodes[i].resultCode, "info")
			end)

			--mobile side: expect SetGlobalProperties response
			EXPECT_RESPONSE(cid, { success = resultCodes[i].success, resultCode = resultCodes[i].resultCode})							

		end	
		-----------------------------------------------------------------------------------------
		
	end
	-----------------------------------------------------------------------------------------

	
	
	--3. IsNotExist
	--4. IsEmpty
	--5. IsWrongType
	--6. IsInvalidCharacter - \n, \t		
	local testData = {	
		{value = "ANY", name = "IsNotExist"},
		{value = "", name = "IsEmpty"},
		{value = 123, name = "IsWrongType"},
		{value = "a\nb", name = "IsInvalidCharacter_NewLine"},
		{value = "a\tb", name = "IsInvalidCharacter_Tab"}}
	
	for i =1, #testData do
	
		Test[APIName.."_resultCode_" .. testData[i].name .."_SendResponse"] = function(self)
			
			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("Show", Request)
			
			--hmi side: expect the request
			UIParams = self:createUIParameters(Request)
			
			EXPECT_HMICALL("UI.Show", UIParams)
			:Do(function(_,data)
				--hmi side: sending the response
				self.hmiConnection:SendResponse(data.id, data.method, testData[i].value, {})
			end)

			--mobile side: expect SetGlobalProperties response
			-- TODO: update after resolving APPLINK-14765
			-- EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
			EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})					

		end
		-----------------------------------------------------------------------------------------
		
		Test[APIName.."_resultCode_" .. testData[i].name .."_SendError"] = function(self)
			
			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("Show", Request)
			
			--hmi side: expect the request
			UIParams = self:createUIParameters(Request)
			
			EXPECT_HMICALL("UI.Show", UIParams)
			:Do(function(_,data)
				--hmi side: sending the response
				self.hmiConnection:SendError(data.id, data.method, testData[i].value)
			end)

			--mobile side: expect SetGlobalProperties response
			-- TODO: update after resolving APPLINK-14765
			-- EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
			EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
						

		end
		-----------------------------------------------------------------------------------------
		
	end
	-----------------------------------------------------------------------------------------
		
end	

verify_resultCode_parameter()


-----------------------------------------------------------------------------------------------
--Parameter 2: method
-----------------------------------------------------------------------------------------------
--List of test cases: 
	--1. IsMissed
	--2. IsValidValue
	--3. IsNotExist
	--4. IsEmpty
	--5. IsWrongType
	--6. IsInvalidCharacter - \n, \t
-----------------------------------------------------------------------------------------------

local function verify_method_parameter()


	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("TestCaseGroupForMethodParameter")
	-----------------------------------------------------------------------------------------
	
	--1. IsMissed
	Test[APIName.."_Response_method_IsMissed_GENERIC_ERROR_SendResponse"] = function(self)
	
		--mobile side: sending the request
		local Request = Test:createRequest()
		local cid = self.mobileSession:SendRPC("Show", Request)

		
		--hmi side: expect the request
		UIParams = self:createUIParameters(Request)
		
		EXPECT_HMICALL("UI.Show", UIParams)
		:Do(function(_,data)
			--hmi side: sending the response
			--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.Show","code":0}}')
			  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0}}')
			  
		end)


		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)
		
	end
	
	Test[APIName.."_Response_method_IsMissed_GENERIC_ERROR_SendError"] = function(self)
	
		--mobile side: sending the request
		local Request = Test:createRequest()
		local cid = self.mobileSession:SendRPC("Show", Request)

		
		--hmi side: expect the request
		UIParams = self:createUIParameters(Request)
		
		EXPECT_HMICALL("UI.Show", UIParams)
		:Do(function(_,data)
			--hmi side: sending the response
			--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"UI.Show"},"code":22,"message":"The unknown issue occurred"}}')
			  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{},"code":22,"message":"The unknown issue occurred"}}')
			  
		end)


		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)
		
	end
	-----------------------------------------------------------------------------------------
	
	--2. IsValidValue: Covered by many test cases	
	
	--3. IsNotExist
	--4. IsEmpty
	--5. IsWrongType
	--6. IsInvalidCharacter - \n, \t		
	local Methods = {	
		{method = "ANY", name = "IsNotExist"},
		{method = "", name = "IsEmpty"},
		{method = 123, name = "IsWrongType"},
		{method = "a\nb", name = "IsInvalidCharacter_NewLine"},
		{method = "a\tb", name = "IsInvalidCharacter_Tab"}}
	
	for i =1, #Methods do
	
		Test[APIName.."_Response_method_" .. Methods[i].name .."_GENERIC_ERROR_SendResponse"] = function(self)
			
			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("Show", Request)
			
			--hmi side: expect the request
			UIParams = self:createUIParameters(Request)
			
			EXPECT_HMICALL("UI.Show", UIParams)
			:Do(function(_,data)
				--hmi side: sending the response
				--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				  self.hmiConnection:SendResponse(data.id, Methods[i].method, "SUCCESS", {})
				
			end)

			--mobile side: expect SetGlobalProperties response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
			:Timeout(13000)

		end
		-----------------------------------------------------------------------------------------
		
		Test[APIName.."_Response_method_" .. Methods[i].name .."_GENERIC_ERROR_SendError"] = function(self)
			
			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("Show", Request)
			
			--hmi side: expect the request
			UIParams = self:createUIParameters(Request)
			
			EXPECT_HMICALL("UI.Show", UIParams)
			:Do(function(_,data)
				--hmi side: sending the response
				--self.hmiConnection:SendError(data.id, data.method, "UNSUPPORTED_RESOURCE", "info")
				  self.hmiConnection:SendError(data.id, Methods[i].method, "UNSUPPORTED_RESOURCE", "info")
				
			end)

			--mobile side: expect SetGlobalProperties response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
			:Timeout(13000)
						

		end
		-----------------------------------------------------------------------------------------
		
	end
	-----------------------------------------------------------------------------------------
		
end	

verify_method_parameter()


-----------------------------------------------------------------------------------------------
--Parameter 3: info
-----------------------------------------------------------------------------------------------
--Requirement id in JAMA: APPLINK-14551: SDL behavior: cases when SDL must transfer "info" parameter via corresponding RPC to mobile app
--List of test cases: 
	--1. IsMissed
	--2. IsLowerBound
	--3. IsUpperBound
	--4. IsOutUpperBound
	--5. IsEmpty/IsOutLowerBound
	--6. IsWrongType
	--7. InvalidCharacter - \n, \t
-----------------------------------------------------------------------------------------------

local function verify_info_parameter()


	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("TestCaseGroupForInfoParameter")
	
	-----------------------------------------------------------------------------------------
	
	--1. IsMissed
	Test[APIName.."_info_IsMissed_SendResponse"] = function(self)
	
		--mobile side: sending the request
		local Request = Test:createRequest()
		local cid = self.mobileSession:SendRPC("Show", Request)

		
		--hmi side: expect the request
		UIParams = self:createUIParameters(Request)
		
		EXPECT_HMICALL("UI.Show", UIParams)
		:Do(function(_,data)
			--hmi side: sending the response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)


		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
		:ValidIf (function(_,data)
			    		if data.payload.info then
			    			commonFunctions:printError(" SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\"")
			    			return false
			    		else 
			    			return true
			    		end
			    	end)
	end
	-----------------------------------------------------------------------------------------
	
	Test[APIName.."_info_IsMissed_SendError"] = function(self)
	
		--mobile side: sending the request
		local Request = Test:createRequest()
		local cid = self.mobileSession:SendRPC("Show", Request)

		
		--hmi side: expect the request
		UIParams = self:createUIParameters(Request)
		
		EXPECT_HMICALL("UI.Show", UIParams)
		:Do(function(_,data)
			--hmi side: sending the response
			self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR")
		end)


		--mobile side: expect the response
		-- TODO: Update after resolving APPLINK-14765
		-- EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response"})
	end
	-----------------------------------------------------------------------------------------

	--2. IsLowerBound
	--3. IsUpperBound
	local testData = {	
		{value = "a", name = "IsLowerBound"},
		{value = commonFunctions:createString(1000), name = "IsUpperBound"}}
	
	for i =1, #testData do
	
		Test[APIName.."_info_" .. testData[i].name .."_SendResponse"] = function(self)
			
			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("Show", Request)
			
			--hmi side: expect the request
			UIParams = self:createUIParameters(Request)
			
			EXPECT_HMICALL("UI.Show", UIParams)
			:Do(function(_,data)
				--hmi side: sending the response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = testData[i].value})
			end)

			--mobile side: expect SetGlobalProperties response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = testData[i].value})							

		end
		-----------------------------------------------------------------------------------------
		
		Test[APIName.."_info_" .. testData[i].name .."_SendError"] = function(self)
			
			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("Show", Request)
			
			--hmi side: expect the request
			UIParams = self:createUIParameters(Request)
			
			EXPECT_HMICALL("UI.Show", UIParams)
			:Do(function(_,data)
				--hmi side: sending the response
				self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", testData[i].value)
			end)

			--mobile side: expect SetGlobalProperties response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = testData[i].value})					

		end
		-----------------------------------------------------------------------------------------
		
	end
	-----------------------------------------------------------------------------------------
	
	--TODO: Please note that TC fails due to APPLINK-11235, remove this comment once it is fixed 
	--4. IsOutUpperBound
	Test[APIName.."_info_IsOutUpperBound_SendResponse"] = function(self)
	
		local infoMaxLength = commonFunctions:createString(1000)
		
		--mobile side: sending the request
		local Request = Test:createRequest()
		local cid = self.mobileSession:SendRPC("Show", Request)
		
		--hmi side: expect the request
		UIParams = self:createUIParameters(Request)
		
		EXPECT_HMICALL("UI.Show", UIParams)
		:Do(function(_,data)
			--hmi side: sending the response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = infoMaxLength .. "1"})
		end)

		--mobile side: expect SetGlobalProperties response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = infoMaxLength})
		
	end
	-----------------------------------------------------------------------------------------
	--TODO: Please note that TC fails due to APPLINK-11235, remove this comment once it is fixed 
	Test[APIName.."_info_IsOutUpperBound_SendError"] = function(self)
	
		local infoMaxLength = commonFunctions:createString(1000)
		
		--mobile side: sending the request
		local Request = Test:createRequest()
		local cid = self.mobileSession:SendRPC("Show", Request)
		
		--hmi side: expect the request
		UIParams = self:createUIParameters(Request)
		
		EXPECT_HMICALL("UI.Show", UIParams)
		:Do(function(_,data)
			--hmi side: sending the response
			self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoMaxLength .."1")
		end)

		--mobile side: expect SetGlobalProperties response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = infoMaxLength})
		
	end
	-----------------------------------------------------------------------------------------
	
	-- TODO: update after resolving APPLINK-14551

	--5. IsEmpty/IsOutLowerBound	
	--6. IsWrongType
	--7. InvalidCharacter - \n, \t
	
	-- local testData = {	
	-- 	{value = "", name = "IsEmpty_IsOutLowerBound"},
	-- 	{value = 123, name = "IsWrongType"},
	-- 	{value = "a\nb", name = "IsInvalidCharacter_NewLine"},
	-- 	{value = "a\tb", name = "IsInvalidCharacter_Tab"}}
	
	-- for i =1, #testData do
	
		-- Test[APIName.."_info_" .. testData[i].name .."_SendResponse"] = function(self)
			
		-- 	--mobile side: sending the request
		-- 	local Request = Test:createRequest()
		-- 	local cid = self.mobileSession:SendRPC("Show", Request)
			
		-- 	--hmi side: expect the request
		-- 	UIParams = self:createUIParameters(Request)
			
		-- 	EXPECT_HMICALL("UI.Show", UIParams)
		-- 	:Do(function(_,data)
		-- 		--hmi side: sending the response
		-- 		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = testData[i].value})
		-- 	end)

		-- 	--mobile side: expect SetGlobalProperties response
		-- 	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
		-- 	:ValidIf (function(_,data)
		-- 					if data.payload.info then
		-- 						commonFunctions:printError(" SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\"")
		-- 						return false
		-- 					else 
		-- 						return true
		-- 					end
		-- 				end)				

		-- end
		-- -----------------------------------------------------------------------------------------
		
		-- Test[APIName.."_info_" .. testData[i].name .."_SendError"] = function(self)
			
		-- 	--mobile side: sending the request
		-- 	local Request = Test:createRequest()
		-- 	local cid = self.mobileSession:SendRPC("Show", Request)
			
		-- 	--hmi side: expect the request
		-- 	UIParams = self:createUIParameters(Request)
			
		-- 	EXPECT_HMICALL("UI.Show", UIParams)
		-- 	:Do(function(_,data)
		-- 		--hmi side: sending the response
		-- 		self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", testData[i].value)
		-- 	end)

		-- 	-- TODO: Update after resolving APPLINK-14765
		-- 	if testData[i].name == "IsWrongType" then
		-- 		-- TODO: Update after resolving APPLINK-14765
		-- 		--mobile side: expect SetGlobalProperties response
		-- 		-- EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		-- 		EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
		-- 		:ValidIf (function(_,data)
		-- 					if data.payload.info then
		-- 						commonFunctions:printError(" SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\"")
		-- 						return false
		-- 					else 
		-- 						return true
		-- 					end
							
		-- 				end)

		-- 	else
		-- 		--mobile side: expect SetGlobalProperties response
		-- 		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		-- 		:ValidIf (function(_,data)
		-- 					if data.payload.info then
		-- 						commonFunctions:printError(" SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\"")
		-- 						return false
		-- 					else 
		-- 						return true
		-- 					end
							
		-- 				end)
		-- 	end				

		-- end
		-----------------------------------------------------------------------------------------
		
	-- end
	-----------------------------------------------------------------------------------------
	
end	

verify_info_parameter()


-----------------------------------------------------------------------------------------------
--Parameter 4: correlationID 
-----------------------------------------------------------------------------------------------
--List of test cases: 
	--1. IsMissed
	--2. IsNonexistent
	--3. IsWrongType
	--4. IsNegative 
-----------------------------------------------------------------------------------------------

local function verify_correlationID_parameter()


	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("TestCaseGroupForCorrelationIDParameter")
	
	-----------------------------------------------------------------------------------------
	
	--1. IsMissed	
	Test[APIName.."_Response_CorrelationID_IsMissed_SendResponse"] = function(self)
	
		--mobile side: sending the request
		local Request = Test:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)

		
		--hmi side: expect the request
		UIParams = self:createUIParameters(Request)
		
		EXPECT_HMICALL("UI.Show", UIParams)
		:Do(function(_,data)
			--hmi side: sending the response
			--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.Show","code":0}}')
			  self.hmiConnection:Send('{"jsonrpc":"2.0","result":{"method":"UI.Show", "code":0}}')
			  
		end)


		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)
		
	end
	-----------------------------------------------------------------------------------------
	
	Test[APIName.."_Response_CorrelationID_IsMissed_SendError"] = function(self)
	
		--mobile side: sending the request
		local Request = self:createRequest()
		local cid = self.mobileSession:SendRPC("Speak", Request)

		
		--hmi side: expect the request
		EXPECT_HMICALL("UI.Show", Request)
		:Do(function(_,data)
			--hmi side: sending the response
			--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"UI.Show"},"code":22,"message":"The unknown issue occurred"}}')
			self.hmiConnection:Send('{"jsonrpc":"2.0","error":{"data":{"method":"UI.Show"},"code":22,"message":"The unknown issue occurred"}}')
	
		end)


		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)
		
	end
	-----------------------------------------------------------------------------------------

	
	--2. IsNonexistent
	Test[APIName.."_Response_CorrelationID_IsNonexistent_SendResponse"] = function(self)
	
		--mobile side: sending the request
		local Request = Test:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)

		
		--hmi side: expect the request
		UIParams = self:createUIParameters(Request)
		
		EXPECT_HMICALL("UI.Show", UIParams)
		:Do(function(_,data)
			--hmi side: sending the response
			--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.Show","code":0}}')
			  self.hmiConnection:Send('{"id":'..tostring(5555)..',"jsonrpc":"2.0","result":{"method":"UI.Show","code":0}}')
			  
		end)


		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)
		
	end
	-----------------------------------------------------------------------------------------
	
	Test[APIName.."_Response_CorrelationID_IsNonexistent_SendError"] = function(self)
	
		--mobile side: sending the request
		local Request = self:createRequest()
		local cid = self.mobileSession:SendRPC("Speak", Request)

		
		--hmi side: expect the request
		EXPECT_HMICALL("UI.Show", Request)
		:Do(function(_,data)
			--hmi side: sending the response
			--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"UI.Show"},"code":22,"message":"The unknown issue occurred"}}')
			self.hmiConnection:Send('{"id":'..tostring(5555)..',"jsonrpc":"2.0","error":{"data":{"method":"UI.Show"},"code":22,"message":"The unknown issue occurred"}}')
	
		end)


		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)
		
	end
	-----------------------------------------------------------------------------------------

	
	--3. IsWrongType
	Test[APIName.."_Response_CorrelationID_IsWrongType_SendResponse"] = function(self)
	
		--mobile side: sending the request
		local Request = Test:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)

		
		--hmi side: expect the request
		UIParams = self:createUIParameters(Request)
		
		EXPECT_HMICALL("UI.Show", UIParams)
		:Do(function(_,data)
			--hmi side: sending the response
			--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = "info message"})
			  self.hmiConnection:SendResponse(tostring(data.id), data.method, "SUCCESS", {info = "info message"})
			
		end)


		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)
				
	end
	-----------------------------------------------------------------------------------------
	
	Test[APIName.."_Response_CorrelationID_IsWrongType_SendError"] = function(self)
	
		--mobile side: sending the request
		local Request = Test:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)

		
		--hmi side: expect the request
		UIParams = self:createUIParameters(Request)
		
		EXPECT_HMICALL("UI.Show", UIParams)
		:Do(function(_,data)
			--hmi side: sending the response
			--self.hmiConnection:SendError(data.id, data.method, "REJECTED", "error message")
			  self.hmiConnection:SendError(tostring(data.id), data.method, "REJECTED", "error message")
			
		end)


		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)

	end
	-----------------------------------------------------------------------------------------

	--4. IsNegative 
	Test[APIName.."_Response_CorrelationID_IsNegative_SendResponse"] = function(self)
	
		--mobile side: sending the request
		local Request = Test:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)

		
		--hmi side: expect the request
		UIParams = self:createUIParameters(Request)
		
		EXPECT_HMICALL("UI.Show", UIParams)
		:Do(function(_,data)
			--hmi side: sending the response
			--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = "info message"})
			  self.hmiConnection:SendResponse(-1, data.method, "SUCCESS", {info = "info message"})
			
		end)


		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)
				
	end
	-----------------------------------------------------------------------------------------
	
	Test[APIName.."_Response_CorrelationID_IsNegative_SendError"] = function(self)
	
		--mobile side: sending the request
		local Request = Test:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)

		
		--hmi side: expect the request
		UIParams = self:createUIParameters(Request)
		
		EXPECT_HMICALL("UI.Show", UIParams)
		:Do(function(_,data)
			--hmi side: sending the response
			--self.hmiConnection:SendError(data.id, data.method, "REJECTED", "error message")
			  self.hmiConnection:SendError(-1, data.method, "REJECTED", "error message")
			
		end)


		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)

	end
	-----------------------------------------------------------------------------------------
	
end	

verify_correlationID_parameter()



----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK IV----------------------------------------
------------------------------Check special cases of HMI response-----------------------------
----------------------------------------------------------------------------------------------
--Requirement id in JAMA or JIRA: 	
	--SDLAQ-CRS-57: Show_Request_v2_0
	--SDLAQ-CRS-58: Show_Response_v2_0
	--SDLAQ-CRS-493: SUCCESS
	--SDLAQ-CRS-500: GENERIC_ERROR

-----------------------------------------------------------------------------------------------

--List of test cases for softButtons type parameter:
	--1. InvalidJsonSyntax (SDLAQ-CRS-500: GENERIC_ERROR)
	--2. InvalidStructure (SDLAQ-CRS-500: GENERIC_ERROR)
	--2. DuplicatedCorrelationId (SDLAQ-CRS-493: SUCCESS)
	--3. FakeParams and FakeParameterIsFromAnotherAPI (APPLINK-14765 SDL must cut off the fake parameters from requests, responses and notifications received from HMI)
	--4. MissedAllPArameters (SDLAQ-CRS-500: GENERIC_ERROR)
	--5. NoResponse (SDLAQ-CRS-500: GENERIC_ERROR)
	--6. SeveralResponsesToOneRequest with the same and different resultCode
-----------------------------------------------------------------------------------------------

local function SpecialResponseChecks()

--Begin Test case NegativeResponseCheck
--Description: Check all negative response cases

	
	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("NewTestCasesGroupForNegativeResponseCheck")

	--Begin Test case NegativeResponseCheck.1
	--Description: Invalid JSON
		
		--Requirement id in JAMA: SDLAQ-CRS-58
		--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
		
		--[[ToDo: Update after implemented CRS APPLINK-14756: SDL must cut off the fake parameters from requests, responses and notifications received from HMI
		
		function Test:Show_InvalidJsonSyntaxResponse()
		
			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("Show", Request)
			
			--hmi side: expect the request
			local UIParams = self:createUIParameters(Request)
			EXPECT_HMICALL("UI.Show", UIParams)
			:Do(function(_,data)
				--hmi side: sending the response
				--":" is changed by ";" after {"id"
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.Show", "code":0}}')
				  self.hmiConnection:Send('{"id";'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.Show", "code":0}}')
			end)
				
			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
			:Timeout(12000)
			
		end	
		
	--End Test case NegativeResponseCheck.1
	
	--Begin Test case NegativeResponseCheck.2
	--Description: Invalid structure of response
	
		--Requirement id in JAMA: SDLAQ-CRS-58
		--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode
			
		function Test:Show_InvalidStructureResponse()

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("Show", Request)
								
			--hmi side: expect the request
			local UIParams = self:createUIParameters(Request)
			EXPECT_HMICALL("UI.Show", UIParams)		
			:Do(function(_,data)
				--hmi side: sending the response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.Show", "code":0}}')
				self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0", "code":0, "result":{"method":"UI.Show"}}')
			end)							
		
			--mobile side: expect response 
			EXPECT_RESPONSE(cid, {  success = false, resultCode = "GENERIC_ERROR"})
			:Timeout(12000)
					
		end
		]]
	--End Test case NegativeResponseCheck.2


	--Begin Test case NegativeResponseCheck.3
	--Description: Check processing response with fake parameters
	
		--Verification criteria: When expected HMI function is received, send responses from HMI with fake parameter			
		--[[ToDo: Update after implemented CRS APPLINK-14756: SDL must cut off the fake parameters from requests, responses and notifications received from HMI
		
		--Begin Test case NegativeResponseCheck.3.1
		--Description: Parameter is not from API
		
		function Test:Show_FakeParamsInResponse()
		
			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("Show", Request)
								
			--hmi side: expect the request
			local UIParams = self:createUIParameters(Request)
			EXPECT_HMICALL("UI.Show", UIParams)		
			:Do(function(exp,data)
				--hmi side: sending the response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {fake = "fake"})
			end)
			
						
			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			:ValidIf (function(_,data)
				if data.payload.fake then
					commonFunctions:printError(" SDL resend fake parameter to mobile app ")
					return false
				else 
					return true
				end
			end)
						
		end								
		
		--End Test case NegativeResponseCheck.3.1
		
		
		--Begin Test case NegativeResponseCheck.3.2
		--Description: Parameter is not from another API
		
		function Test:Show_AnotherParameterInResponse()
		
			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("Show", Request)
								
			--hmi side: expect the request
			local UIParams = self:createUIParameters(Request)
			EXPECT_HMICALL("UI.Show", UIParams)		
			:Do(function(exp,data)
				--hmi side: sending the response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 5})
			end)
			
						
			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			:ValidIf (function(_,data)
				if data.payload.sliderPosition then
					commonFunctions:printError(" SDL resend fake parameter to mobile app ")
					return false
				else 
					return true
				end
			end)
						
		end								
		
		--End Test case NegativeResponseCheck.3.2
		]]
	--End Test case NegativeResponseCheck.3


	
	--Begin NegativeResponseCheck.4
	--Description: Check processing response without all parameters		
	--[[ToDo: xxxxxxxxxxxx
		function Test:Show_Response_MissedAllPArameters()	
		
			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("Show", Request)

			
			--hmi side: expect the request
			UIParams = self:createUIParameters(Request)
			
			EXPECT_HMICALL("UI.Show", UIParams)
			:Do(function(_,data)
				--hmi side: sending UI.Show response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.Show", "code":0}}')
				self.hmiConnection:Send('{}')
			end)
			
			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
			:Timeout(13000)
			
		end
	]]
	--End NegativeResponseCheck.4


	--Begin Test case NegativeResponseCheck.5
	--Description: Request without responses from HMI

		--Requirement id in JAMA: SDLAQ-CRS-500
		--Verification criteria: GENERIC_ERROR comes as a result code in response when all other codes aren't applicable or the unknown issue occurred.

		function Test:Show_NoResponse()

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("Show", Request)
								
			--hmi side: expect the request
			local UIParams = self:createUIParameters(Request)
			EXPECT_HMICALL("UI.Show", UIParams)		
			
			
			--mobile side: expect SetGlobalProperties response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
			:Timeout(12000)
		
		end
		
	--End NegativeResponseCheck.5
		

	--Begin Test case NegativeResponseCheck.6
	--Description: Several response to one request

		--Requirement id in JAMA: SDLAQ-CRS-58
			
		--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
		
		
		--Begin Test case NegativeResponseCheck.6.1
		--Description: Several response to one request
			
			function Test:Show_SeveralResponsesToOneRequest()

				--mobile side: sending the request
				local Request = Test:createRequest()
				local cid = self.mobileSession:SendRPC("Show", Request)
									
				--hmi side: expect the request
				local UIParams = self:createUIParameters(Request)
				EXPECT_HMICALL("UI.Show", UIParams)		
				:Do(function(exp,data)
					--hmi side: sending the response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					
				end)
				
							
				--mobile side: expect response 
				EXPECT_RESPONSE(cid, {  success = true, resultCode = "SUCCESS"})
				
			end									
			
		--End Test case NegativeResponseCheck.6.1
		
		
		
		--Begin Test case NegativeResponseCheck.6.2
		--Description: Several response to one request
			
			function Test:Show_SeveralResponsesToOneRequestWithConstractionsOfResultCode()

				--mobile side: sending the request
				local Request = Test:createRequest()
				local cid = self.mobileSession:SendRPC("Show", Request)
									
				--hmi side: expect the request
				local UIParams = self:createUIParameters(Request)
				EXPECT_HMICALL("UI.Show", UIParams)		
				:Do(function(exp,data)
					--hmi side: sending the response
					self.hmiConnection:SendResponse(data.id, data.method, "INVALID_DATA", {})
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})					
				end)
				
							
				--mobile side: expect response 
				EXPECT_RESPONSE(cid, {  success = false, resultCode = "INVALID_DATA"})
				
			end									
			
		--End Test case NegativeResponseCheck.6.2
		-----------------------------------------------------------------------------------------

	--End Test case NegativeResponseCheck.6
	
--End Test case NegativeResponseCheck	

end	

SpecialResponseChecks()

	
-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK V----------------------------------------
-------------------------------------Checks All Result Codes-----------------------------------
-----------------------------------------------------------------------------------------------

--Description: Check all resultCodes

--Requirement id in JAMA: 	
	--SDLAQ-CRS-493: SUCCESS
	--SDLAQ-CRS-494: INVALID_DATA	
	--OUT_OF_MEMORY: SDLAQ-CRS-495
	--TOO_MANY_PENDING_REQUESTS: SDLAQ-CRS-496
	--SDLAQ-CRS-500: GENERIC_ERROR	
	--SDLAQ-CRS-497: APPLICATION_NOT_REGISTERED
	--SDLAQ-CRS-498: REJECTED
	--SDLAQ-CRS-499: ABORTED	
	--SDLAQ-CRS-501: DISALLOWED
	--SDLAQ-CRS-1026: UNSUPPORTED_RESOURCE
	--SDLAQ-CRS-2905: WARNINGS
	
	
local function ResultCodeChecks()

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("NewTestCasesGroupForResultCodeChecks")
	
	
	--Check resultCode SUCCESS. It is checked by other test cases.
	--Check resultCode INVALID_DATA. It is checked by other test cases.
	--Check resultCode REJECTED, UNSUPPORTED_RESOURCE, ABORTED, WARNINGS: Covered by test case resultCode_IsValidValues	
	--Check resultCode GENERIC_ERROR. It is covered in Test:Show_NoResponse
	--Check resultCode OUT_OF_MEMORY. ToDo: Wait until requirement is clarified
	--Check resultCode TOO_MANY_PENDING_REQUESTS. It is moved to other script.
	-----------------------------------------------------------------------------------------

	--Begin Test case ResultCodeChecks.1
	--Description: Check resultCode APPLICATION_NOT_REGISTERED

		--Requirement id in JAMA: SDLAQ-CRS-497
		--Verification criteria: SDL sends APPLICATION_NOT_REGISTERED code when the app sends a request within the same connection before RegisterAppInterface has been performed yet.
				
		commonTestCases:verifyResultCode_APPLICATION_NOT_REGISTERED()

	--End Test case ResultCodeChecks.1
	-----------------------------------------------------------------------------------------


	--Begin Test case ResultCodeChecks.2
	--Description: Check resultCode DISALLOWED
			
		--Requirement id in JAMA: SDLAQ-CRS-501
		--Verification criteria: 
			--1. SDL must return "DISALLOWED, success:false" for Alert RPC to mobile app IN CASE Alert RPC is not included to policies assigned to this mobile app.
			--2. SDL must return "DISALLOWED, success:false" for Alert RPC to mobile app IN CASE Alert RPC contains softButton with SystemAction disallowed by policies assigned to this mobile app.
				
		
		--Begin Test case ResultCodeChecks.2.1
		--Description: Check resultCode DISALLOWED when HMI level is NONE
	
			--Covered by test case Show_HMIStatus_NONE
			
		--End Test case ResultCodeChecks.2.1
		
		--[[TODO debug after resolving APPLINK-13101
		
		--Begin Test case ResultCodeChecks.2.2
		--Description: Check resultCode DISALLOWED when request is not assigned to app

			policyTable:checkPolicyWhenAPIIsNotExist()
			
		--End Test case ResultCodeChecks.2.2
		
		--Begin Test case ResultCodeChecks.2.3
		--Description: Check resultCode DISALLOWED when request is assigned to app but user does not allow
			local keep_context = false
			local steal_focus = false
			policyTable:checkPolicyWhenUserDisallowed({"FULL", "LIMITED"}, keep_context, steal_focus)
			--> postcondition of this script: user allows the function group
			
		--End Test case ResultCodeChecks.2.3
		
		--Begin Test case ResultCodeChecks.2.4
		--Description: Check resultCode DISALLOWED when request is assigned to app, user allows but "keep_context" : false, "steal_focus" : false
		

			function Test:Show_resultCode_DISALLOWED_systemAction_Is_KEEP_CONTEXT() 

				--mobile side: send the request 	
				local cid = self.mobileSession:SendRPC("Show",
									{
										statusBar = "new status bar",
										softButtons = 
										{ 
											{ 
												type = "BOTH",
												text = "Close",
												 image = 
									
												{ 
													value = "icon.png",
													imageType = "DYNAMIC",
												}, 
												isHighlighted = true,
												softButtonID = 3,
												systemAction = "DEFAULT_ACTION",
											}, 
											
											{ 
												type = "TEXT",
												text = "Keep",
												isHighlighted = true,
												softButtonID = 4,
												systemAction = "KEEP_CONTEXT",
											}
										}
									
									})


			    --mobile side: expect the response
			    EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED" })
				
			end

			function Test:Show_resultCode_DISALLOWED_systemAction_Is_STEAL_FOCUS() 

				--mobile side: send the request 	
				local cid = self.mobileSession:SendRPC("Show",
									{
										statusBar = "new status bar",
										softButtons = 
										{ 
											{ 
												type = "BOTH",
												text = "Close",
												 image = 
									
												{ 
													value = "icon.png",
													imageType = "DYNAMIC",
												}, 
												isHighlighted = true,
												softButtonID = 3,
												systemAction = "DEFAULT_ACTION",
											}, 
											
											{ 
												type = "TEXT",
												text = "Keep",
												isHighlighted = true,
												softButtonID = 4,
												systemAction = "STEAL_FOCUS",
											}
										}
									})


			    --mobile side: expect the response
			    EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED" })
				
			end

			function Test:Show_resultCode_SUCCESS_systemAction_Is_DEFAULT_ACTION() 

				--mobile side: send the request 	

				local Request = 	{
											statusBar = "new status bar",
											softButtons = 
											{ 
												{ 
													type = "BOTH",
													text = "Close",
													 image = 
										
													{ 
														value = "icon.png",
														imageType = "DYNAMIC",
													}, 
													isHighlighted = true,
													softButtonID = 3,
													systemAction = "DEFAULT_ACTION",
												}
											}
										}

				self:verify_SUCCESS_Case(Request)	
							
			end

			
			--Postcondition: Update PT to allow Show request	
			local keep_context = true
			local steal_focus = true
			policyTable:updatePolicyAndAllowFunctionGroup({"FULL", "LIMITED", "BACKGROUND"}, keep_context, steal_focus)
			
		--End Test case ResultCodeChecks.2.4
	]]	
	--End Test case ResultCodeChecks.2
			
	-----------------------------------------------------------------------------------------

end

ResultCodeChecks()


----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VI----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------

--Description: TC's checks SDL behavior by processing
	-- different request sequence with timeout
	-- with emulating of user's actions	

--Requirement id in JAMA: Mentions in each test case
	
local function SequenceChecks()

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("NewTestCasesGroupForSequenceCheck")
	
	
	--Begin Test case SequenceChecks.1
	--Description: 	
		--Check for manual test case TC_Show_01
			--Call Show request from mobile app on HMI with one and eight SoftButtons
			--Check Media Application menu reflecting on UI after Show request with min and max number of SoftButtons
			--Check Media Application menu behavior by pressing SoftButton with DEFAULT_ACTION system action

		--Requirement id in JAMA: SDLAQ-TC-34
		--Verification criteria: 
			--Check Media Application menu reflecting on UI after Show request with min and max number of SoftButtons
			--Check Media Application menu behavior by pressing SoftButton with DEFAULT_ACTION system action

	

		--Begin Precondition: unsubscribe custom buttons
		function Test:Precondition_UnsubscribeCustomButtons() 

			local CorrIdUnsub = self.mobileSession:SendRPC("UnsubscribeButton",
													{
														buttonName = "CUSTOM_BUTTON"
													})

			--mobile response
			EXPECT_RESPONSE(CorrIdUnsub, { success = true, resultCode = "SUCCESS"})

		end
				
		function Test:Show_TC_Show_01_Step1_01()

			--mobile side: sending Show request
			local cid = self.mobileSession:SendRPC("Show",
													{
														mediaClock = "22:22",
														mainField1 = "Text1",
														mainField2 = "Text2",
														mainField3 = "Text3",
														mainField4 = "Text4",
														graphic =
														{
															value = "icon.png",
															imageType = "DYNAMIC"
														},
														softButtons =
														{
															 {
																text = "Clean",
																systemAction = "DEFAULT_ACTION",
																type = "TEXT",						
																softButtonID = 1
															 }
														 },															
														statusBar = "new status bar",
														mediaTrack = "Track1"
													})
			--hmi side: expect UI.Show request
			EXPECT_HMICALL("UI.Show", 
							{
								--Verification is done below 
								-- graphic = 
								-- {
								--  imageType = "DYNAMIC",
								--  value = storagePath .. "icon.png"
								-- },
								showStrings = 
								{							
									{
									fieldName = "mainField1",
									fieldText = "Text1"
									},
									{
									fieldName = "mainField2",
									fieldText = "Text2"
									},
									{
									fieldName = "mainField3",
									fieldText = "Text3"
									},
									{
									fieldName = "mainField4",
									fieldText = "Text4"
									},
									{
									fieldName = "mediaClock",
									fieldText = "22:22"
									},
									{
										fieldName = "mediaTrack",
										fieldText = "Track1"
									},
									{
										fieldName = "statusBar",
										fieldText = "new status bar"
									}
								},
								softButtons =
								{
									 {
										text = "Clean",
										systemAction = "DEFAULT_ACTION",
										type = "TEXT",															
										softButtonID = 1
									 }
								 }
							})
			:ValidIf(function(_,data)
                  local path  = "bin/storage/"..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"
                  local value_Icon = path .. "action.png"
          
                  if(data.params.graphic.imageType == "DYNAMIC") then
                      return true
                  else
                      print("\27[31m imageType of menuIcon is WRONG. Expected: DYNAMIC; Real: " .. data.params.graphic.imageType .. "\27[0m")
                      return false
                  end

                  if(string.find(data.params.graphic.value, value_Icon) ) then
                        return true
                    else
                        print("\27[31m value of menuIcon is WRONG. Expected: ~".. value_Icon .. "; Real: " .. data.params.graphic.value .. "\27[0m")
                        return false
                    end
              end)
			--UPDATED: According to APPLINK-20841 the In case SDL receives valid Show_request from mobile app and gets UI.Show ("SUCCESS") response from HMI, SDL must respond with (resultCode: SUCCESS, success:true) to mobile application
   				:Do(function(_,data)
					--hmi side: sending UI.Show response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)

			--mobile side: expect Show response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			
		end

		function Test:Show_TC_Show_01_Step1_02()

			--hmi side: send request to click on Clear softButton
			self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 1, appID = self.applications["Test Application"]})
			self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 1, appID = self.applications["Test Application"]})
			self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "SHORT", customButtonID = 1, appID = self.applications["Test Application"]})
			

			--mobile side: notifications are not sent to mobile app
			EXPECT_NOTIFICATION("OnButtonEvent", { customButtonID = 1, buttonEventMode = "BUTTONDOWN", buttonName = "CUSTOM_BUTTON"},
				{ customButtonID = 1, buttonEventMode = "BUTTONUP", buttonName = "CUSTOM_BUTTON"})
			:Times(0)
		
			EXPECT_NOTIFICATION("OnButtonPress", { customButtonID = 1, buttonPressMode = "SHORT", buttonName = "CUSTOM_BUTTON"})
			:Times(0)

			
		end
		
		function Test:Show_TC_Show_01_Step2_01()

			--mobile side: sending Show request
			local cid = self.mobileSession:SendRPC("Show",
													{
														mediaClock = "22:22",
														mainField1 = "Text1",
														mainField2 = "Text2",
														mainField3 = "Text3",
														mainField4 = "Text4",
														graphic =
														{
															value = "icon.png",
															imageType = "DYNAMIC"
														},
														softButtons =
														{
															{
																text = "Clean1",
																systemAction = "DEFAULT_ACTION",
																type = "TEXT",						
																softButtonID = 1
															},
															{
																text = "Clean2",
																systemAction = "DEFAULT_ACTION",
																type = "TEXT",						
																softButtonID = 2
															},
															{
																text = "Clean3",
																systemAction = "DEFAULT_ACTION",
																type = "TEXT",						
																softButtonID = 3
															},
															{
																text = "Clean4",
																systemAction = "DEFAULT_ACTION",
																type = "TEXT",						
																softButtonID = 4
															},
															{
																text = "Clean5",
																systemAction = "DEFAULT_ACTION",
																type = "TEXT",						
																softButtonID = 5
															},
															{
																text = "Clean6",
																systemAction = "DEFAULT_ACTION",
																type = "TEXT",						
																softButtonID = 6
															},
															{
																text = "Clean7",
																systemAction = "DEFAULT_ACTION",
																type = "TEXT",						
																softButtonID = 7
															},
															{
																text = "Clean8",
																systemAction = "DEFAULT_ACTION",
																type = "TEXT",						
																softButtonID = 8
															}
														 },															
														statusBar = "new status bar",
														mediaTrack = "Track1"
													})
			--hmi side: expect UI.Show request
			EXPECT_HMICALL("UI.Show", 
							{
								--Verification is done below 
								-- graphic = 
								-- {
								--  imageType = "DYNAMIC",
								--  value = storagePath .. "icon.png"
								-- },
								showStrings = 
								{							
									{
									fieldName = "mainField1",
									fieldText = "Text1"
									},
									{
									fieldName = "mainField2",
									fieldText = "Text2"
									},
									{
									fieldName = "mainField3",
									fieldText = "Text3"
									},
									{
									fieldName = "mainField4",
									fieldText = "Text4"
									},
									{
									fieldName = "mediaClock",
									fieldText = "22:22"
									},
									{
										fieldName = "mediaTrack",
										fieldText = "Track1"
									},
									{
										fieldName = "statusBar",
										fieldText = "new status bar"
									}
								},
								softButtons =
								{
									{
										text = "Clean1",
										systemAction = "DEFAULT_ACTION",
										type = "TEXT",						
										softButtonID = 1
									},
									{
										text = "Clean2",
										systemAction = "DEFAULT_ACTION",
										type = "TEXT",						
										softButtonID = 2
									},
									{
										text = "Clean3",
										systemAction = "DEFAULT_ACTION",
										type = "TEXT",						
										softButtonID = 3
									},
									{
										text = "Clean4",
										systemAction = "DEFAULT_ACTION",
										type = "TEXT",						
										softButtonID = 4
									},
									{
										text = "Clean5",
										systemAction = "DEFAULT_ACTION",
										type = "TEXT",						
										softButtonID = 5
									},
									{
										text = "Clean6",
										systemAction = "DEFAULT_ACTION",
										type = "TEXT",						
										softButtonID = 6
									},
									{
										text = "Clean7",
										systemAction = "DEFAULT_ACTION",
										type = "TEXT",						
										softButtonID = 7
									},
									{
										text = "Clean8",
										systemAction = "DEFAULT_ACTION",
										type = "TEXT",						
										softButtonID = 8
									}
								 }
							})
				:ValidIf(function(_,data)
                  local path  = "bin/storage/"..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"
                  local value_Icon = path .. "action.png"
          
                  if(data.params.graphic.imageType == "DYNAMIC") then
                      return true
                  else
                      print("\27[31m imageType of menuIcon is WRONG. Expected: DYNAMIC; Real: " .. data.params.graphic.imageType .. "\27[0m")
                      return false
                  end

                  if(string.find(data.params.graphic.value, value_Icon) ) then
                        return true
                    else
                        print("\27[31m value of menuIcon is WRONG. Expected: ~".. value_Icon .. "; Real: " .. data.params.graphic.value .. "\27[0m")
                        return false
                    end
              end)

				:Do(function(_,data)
					--hmi side: sending UI.Show response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
			
			--mobile side: expect Show response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			
		end
		
		function Test:Show_TC_Show_01_Step2_02()
		
			--hmi side: send request to click on Clear8 softButton
			self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 8, appID = self.applications["Test Application"]})
			self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 8, appID = self.applications["Test Application"]})
			self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "SHORT", customButtonID = 8, appID = self.applications["Test Application"]})
			

			--mobile side: notifications are not sent to mobile app
			EXPECT_NOTIFICATION("OnButtonEvent", { customButtonID = 8, buttonEventMode = "BUTTONDOWN", buttonName = "CUSTOM_BUTTON"},
				{ customButtonID = 1, buttonEventMode = "BUTTONUP", buttonName = "CUSTOM_BUTTON"})
			:Times(0)
		
			EXPECT_NOTIFICATION("OnButtonPress", { customButtonID = 8, buttonPressMode = "SHORT", buttonName = "CUSTOM_BUTTON"})
			:Times(0)
			
		end
								
	--End Test case SequenceChecks.1

	-----------------------------------------------------------------------------------------

	--Begin Test case SequenceChecks.2
	--Description: 	
		--Check for manual test case TC_Show_02: Call Show request with CustomPresets from mobile app on HMI

		--Requirement id in JAMA: SDLAQ-TC-80
		--Verification criteria: Call Show request with CustomPresets from mobile app on HMI

		function Test:Show_TC_Show_02_Step1_01()

			--mobile side: sending Show request
			local cid = self.mobileSession:SendRPC("Show",
													{
														mediaClock = "22:22",
														mainField1 = "Text1",
														mainField2 = "Text1",									
														statusBar = "new status bar",
														mediaTrack = "Track1",
														customPresets =
														{
															"GEN1"
														}
													})
			--hmi side: expect UI.Show request
			EXPECT_HMICALL("UI.Show", 
							{
								showStrings = 
								{							
									{
									fieldName = "mainField1",
									fieldText = "Text1"
									},
									{
									fieldName = "mainField2",
									fieldText = "Text1"
									},
									{
									fieldName = "mediaClock",
									fieldText = "22:22"
									},
									{
										fieldName = "mediaTrack",
										fieldText = "Track1"
									},
									{
										fieldName = "statusBar",
										fieldText = "new status bar"
									}
								},
								customPresets =
								{
									"GEN1"
								}
							})
				:Do(function(_,data)
					--hmi side: sending UI.Show response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
			
			--mobile side: expect Show response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })			
			
		end
		
		function Test:Show_TC_Show_02_Step1_02_Subscribe_Preset_1()				

			--mobile side: send SubscribeButton request to mark PRESET_1
			local cid = self.mobileSession:SendRPC("SubscribeButton",
													{
														buttonName = "PRESET_1"
													})
													
			--mobile side: expect SubscribeButton response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			
			EXPECT_NOTIFICATION("OnHashChange")			
			
		end
		
		function Test:Show_TC_Show_02_Step1_03()				

			--hmi side: Long click on \93GEN10\94 button in UI
			self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {mode = "BUTTONDOWN", name = "PRESET_1"})
			self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {mode = "BUTTONUP", name = "PRESET_1"})
			self.hmiConnection:SendNotification("Buttons.OnButtonPress", {mode = "SHORT", name = "PRESET_1"})
		
			--mobile side: Notifications are sent to mobile app
			EXPECT_NOTIFICATION("OnButtonEvent", { buttonEventMode = "BUTTONDOWN", buttonName = "PRESET_1"},
				{ buttonEventMode = "BUTTONUP", buttonName = "PRESET_1"})
			:Times(2)				
		
			EXPECT_NOTIFICATION("OnButtonPress", { buttonPressMode = "SHORT", buttonName = "PRESET_1"})
			
		end

		function Test:Show_TC_Show_02_Step2_01()

			--mobile side: sending Show request
			local cid = self.mobileSession:SendRPC("Show",
													{
														mediaClock = "22:22",
														mainField1 = "Text1",
														mainField2 = "Text1",									
														statusBar = "new status bar",
														mediaTrack = "Track1",
														customPresets =
														{
															"GEN1", "GEN2", "GEN3", "GEN4", "GEN5", "GEN6", "GEN7", "GEN8", "GEN9", "GEN10"
														}
													})
			--hmi side: expect UI.Show request
			EXPECT_HMICALL("UI.Show", 
							{
								showStrings = 
								{							
									{
									fieldName = "mainField1",
									fieldText = "Text1"
									},
									{
									fieldName = "mainField2",
									fieldText = "Text1"
									},
									{
									fieldName = "mediaClock",
									fieldText = "22:22"
									},
									{
										fieldName = "mediaTrack",
										fieldText = "Track1"
									},
									{
										fieldName = "statusBar",
										fieldText = "new status bar"
									}
								},
								customPresets =
								{
									"GEN1", "GEN2", "GEN3", "GEN4", "GEN5", "GEN6", "GEN7", "GEN8", "GEN9", "GEN10"
								}
							})
				:Do(function(_,data)
					--hmi side: sending UI.Show response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
			
			--mobile side: expect Show response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })			
			
		end
		
		function Test:Show_TC_Show_02_Step2_02()				

			--mobile side: send SubscribeButton request to mark PRESET_9
			local cid = self.mobileSession:SendRPC("SubscribeButton",
													{
														buttonName = "PRESET_9"
													})
													
			--mobile side: expect SubscribeButton response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			
			EXPECT_NOTIFICATION("OnHashChange")			
			
		end
		
		function Test:Show_TC_Show_02_Step2_03()				

			--hmi side: Long click on \93GEN10\94 button in UI
			self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {mode = "BUTTONDOWN", name = "PRESET_9"})
			self.hmiConnection:SendNotification("Buttons.OnButtonPress", {mode = "LONG", name = "PRESET_9"})
			self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {mode = "BUTTONUP", name = "PRESET_9"})
		
			--mobile side: Notifications are sent to mobile app
			EXPECT_NOTIFICATION("OnButtonEvent", { buttonEventMode = "BUTTONDOWN", buttonName = "PRESET_9"},
				{ buttonEventMode = "BUTTONUP", buttonName = "PRESET_9"})
			:Times(2)				
		
			EXPECT_NOTIFICATION("OnButtonPress", { buttonPressMode = "LONG", buttonName = "PRESET_9"})
			
		end

		
	--End Test case SequenceChecks.2

	-----------------------------------------------------------------------------------------

	--Begin Test case SequenceChecks.3
	--Description: Check for manual test case TC_Show_03: Call Show request from mobile app on HMI and check that MediaClock text is set, so any automatic media clock updates previously set with SetMediaClockTimer is stopped

		--Requirement id in JAMA: SDLAQ-TC-82
		--Verification criteria: Call Show request from mobile app on HMI and check that MediaClock text is set, so any automatic media clock updates previously set with SetMediaClockTimer is stopped
		
		--Note: Main purpose of this manual test case is checking Show request update clock what was set by SetMediaClockTimer.
		--When converting to ATF script, this test case just checks Show request is successed after SetMediaClockTimer request
		
		function Test:Show_TC_Show_03_Step1()

			--mobile side: sending Show request
			local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
													{
														startTime =	
														{ 
															hours = 00,
															minutes = 12,
															seconds = 34
														}, 
														updateMode = "COUNTUP"
													})
			--hmi side: expect UI.Show request
			EXPECT_HMICALL("UI.SetMediaClockTimer", 
							{
								startTime =	
								{ 
									hours = 00,
									minutes = 12,
									seconds = 34
								}, 
								updateMode = "COUNTUP"
							})
				:Do(function(_,data)
					--hmi side: sending UI.Show response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
			
			--mobile side: expect Show response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			
		end
		
		function Test:Show_TC_Show_03_Step2()

			--mobile side: sending Show request
			local cid = self.mobileSession:SendRPC("Show",
													{
														mediaClock = "23:23",
														mainField1 = "New Text",
														mainField2 = "Text",															
														statusBar = "next status bar",
														mediaTrack = "Track1"
													})
			--hmi side: expect UI.Show request
			EXPECT_HMICALL("UI.Show", 
							{
								showStrings = 
								{							
									{
									fieldName = "mainField1",
									fieldText = "New Text"
									},
									{
									fieldName = "mainField2",
									fieldText = "Text"
									},
									{
									fieldName = "mediaClock",
									fieldText = "23:23"
									},
									{
										fieldName = "mediaTrack",
										fieldText = "Track1"
									},
									{
										fieldName = "statusBar",
										fieldText = "next status bar"
									}
								}
							})
				:Do(function(_,data)
					--hmi side: sending UI.Show response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
			
			--mobile side: expect Show response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			
		end
		
		
	--End Test case SequenceChecks.3

	-----------------------------------------------------------------------------------------

	--Begin Test case SequenceChecks.4
	--Description: Check for manual test case TC_Show_05:
					--Checking that the HMI answer to SDL and SDL answer to mobile with resultCode:"WARNINGS", success:true 
					--And with info message if Show was sent with several parameters in request 
					--And "image" parameter of unsupported image type (STATIC in current HMI implementation).

		--Requirement id in JAMA: SDLAQ-TC-416
		--Verification criteria: 
				--Checking that the HMI answer to SDL and SDL answer to mobile with resultCode:"WARNINGS", success:true 
				--And with info message if Show was sent with several parameters in request 
				--And "image" parameter of unsupported image type (STATIC in current HMI implementation).
				
		--> Covered by test case Show_resultCode_WARNINGS
		
	--End Test case SequenceChecks.4

	-----------------------------------------------------------------------------------------

	--Begin Test case SequenceChecks.5
	--Description: Check for manual test case TC_Show_06: If HMI doesn't support STATIC, DYNAMIC or any image types which exist in request data, the \93Info\94 parameter in the response should provide further details, the other parts of RPC should be otherwise successful.
					--Used if UI isn't available now (not supported).
					--\93Info\94 parameter in the response should provide further details. When this error code is issued, UI commands are not processed, the general result of RPC should be success=false.

		--Requirement id in JAMA: SDLAQ-TC-416

		--Verification criteria: 
				--If HMI doesn't support STATIC, DYNAMIC or any image types which exist in request data, the \93Info\94 parameter in the response should provide further details, the other parts of RPC should be otherwise successful.
				--Used if UI isn't available now (not supported).
				--\93Info\94 parameter in the response should provide further details. When this error code is issued, UI commands are not processed, the general result of RPC should be success=false.
				
		--Covered by Show_resultCode_UNSUPPORTED_RESOURCE

	--End Test case SequenceChecks.5

	-----------------------------------------------------------------------------------------

	--Begin Test case SequenceChecks.6
	--Description: Check for manual test case TC_Show_07: 
					--Checking that the HMI answer to SDL and SDL answer to mobile with resultCode:"WARNINGS", success:true 
					--And with info message if Show was sent with several parameters in request 
					--And "SoftButton" parameter with image of unsupported image type (STATIC in current HMI implementation)

		--Requirement id in JAMA: SDLAQ-TC-418
		--Verification criteria: 
				--Checking that the HMI answer to SDL and SDL answer to mobile with resultCode:"WARNINGS", success:true 
				--And with info message if Show was sent with several parameters in request 
				--And "SoftButton" parameter with image of unsupported image type (STATIC in current HMI implementation)
					
		function Test:Show_TC_Show_07()

			--mobile side: sending Show request
			local cid = self.mobileSession:SendRPC("Show",
													{
														mediaClock = "22:22",
														mainField1 = "Text1",
														mainField2 = "Text2",
														mainField3 = "Text3",
														mainField4 = "Text4",															
														softButtons =
														{
															 {
																text = "Close",
																systemAction = "KEEP_CONTEXT",
																type = "BOTH",
																isHighlighted = true,																
																image =
																{
																   imageType = "STATIC",
																   value = "action.png"
																},																
																softButtonID = 1
															 }
														 },
														statusBar = "new status bar",
														mediaTrack = "Track1"
													})
			--hmi side: expect UI.Show request
			EXPECT_HMICALL("UI.Show", 
							{ 
								showStrings = 
								{							
									{
									fieldName = "mainField1",
									fieldText = "Text1"
									},
									{
									fieldName = "mainField2",
									fieldText = "Text2"
									},
									{
									fieldName = "mainField3",
									fieldText = "Text3"
									},
									{
									fieldName = "mainField4",
									fieldText = "Text4"
									},
									{
									fieldName = "mediaClock",
									fieldText = "22:22"
									},
									{
										fieldName = "mediaTrack",
										fieldText = "Track1"
									},
									{
										fieldName = "statusBar",
										fieldText = "new status bar"
									}
								},
								softButtons =
								{
									 {
										text = "Close",
										systemAction = "KEEP_CONTEXT",
										type = "BOTH",
										isHighlighted = true,																											
										softButtonID = 1
									 }
								 }
							})
				:Do(function(_,data)
					--hmi side: sending UI.Show response
					self.hmiConnection:SendError(data.id, data.method, "WARNINGS", "Unsupported STATIC type. Available data in request was processed.")
				end)														
			
			--mobile side: expect Show response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS", info = "Unsupported STATIC type. Available data in request was processed." })					
			
		end
			
	--End Test case SequenceChecks.6

	-----------------------------------------------------------------------------------------
	
	--Begin Test case SequenceChecks.7
	--Description: Check for manual test case TC_Show_08: 
					--Checking that the SDL answer to mobile with resultCode:"UNSUPPORTED_RESOURCE", success:false 
					--And with info message if Show was sent with one "SoftButtons" parameter 
					--With image of unsupported image type (STATIC in current HMI implementation)

		--Requirement id in JAMA: SDLAQ-TC-418
		--Verification criteria: 
				--Checking that the SDL answer to mobile with resultCode:"UNSUPPORTED_RESOURCE", success:false 
				--And with info message if Show was sent with one "SoftButtons" parameter 
				--With image of unsupported image type (STATIC in current HMI implementation)
		
		--Covered by Show_resultCode_UNSUPPORTED_RESOURCE
		
	--End Test case SequenceChecks.7

	-----------------------------------------------------------------------------------------		

	--Begin Test case SequenceChecks.8
	--Description: Check for manual test case TC_Show_09: 
					--Checking that the SDL answer to mobile with resultCode:"UNSUPPORTED_RESOURCE", success:false 
					--And with info message if Show was sent just with "image" parameter of unsupported image type 
					--And "SoftButtons" parameter with image of unsupported image type (STATIC in current HMI implementation)

		--Requirement id in JAMA: SDLAQ-TC-418
		--Verification criteria: 
				--Checking that the SDL answer to mobile with resultCode:"UNSUPPORTED_RESOURCE", success:false 
				--And with info message if Show was sent just with "image" parameter of unsupported image type 
				--And "SoftButtons" parameter with image of unsupported image type (STATIC in current HMI implementation)
		--Covered by Show_resultCode_UNSUPPORTED_RESOURCE
		
	--End Test case SequenceChecks.8

	-----------------------------------------------------------------------------------------		
	
	--Begin Test case SequenceChecks.9
	--Description: Check for manual test case TC_Show_10:
					--Check that applied to Show request SoftButtons with KEEP_CONTEXT, DEFAULT_ACTION and STEAL_FOCUS SystemActions make no action on HMI.
					--Note: According to APPLINK-6517 custom buttons subscribed by default.

		--Requirement id in JAMA: 
				--SDLAQ-TC-34
				--SDLAQ-CRS-926
				--SDLAQ-CRS-927

		--Verification criteria: 
				--Check that applied to Show request SoftButtons with KEEP_CONTEXT, DEFAULT_ACTION and STEAL_FOCUS SystemActions make no action on HMI.
				
		function Test:Show_TC_Show_10_Step1()

			--mobile side: sending Show request
			local cid = self.mobileSession:SendRPC("Show",
													{
														mediaClock = "12:34",
														mainField1 = "Show Line 1",
														mainField2 = "Show Line 2",
														mainField3 = "Show Line 3",
														mainField4 = "Show Line 4",
														-- graphic =
														-- {
														-- 	value = "action.png",
														-- 	imageType = "DYNAMIC"
														-- },
														softButtons =
														{
															 {
																text = "default_action",
																systemAction = "DEFAULT_ACTION",
																type = "TEXT",
																isHighlighted = true,																
																softButtonID = 1
															 },
															 {
																text = "keep_context",
																systemAction = "KEEP_CONTEXT",
																type = "TEXT",
																isHighlighted = true,																
																softButtonID = 2
															 },
															 {
																text = "steal_focus",
																systemAction = "STEAL_FOCUS",
																type = "TEXT",
																isHighlighted = true,																
																softButtonID = 3
															 }
														 },
														-- secondaryGraphic =
														-- {
														-- 	value = "action.png",
														-- 	imageType = "DYNAMIC"
														-- },
														statusBar = "status bar",
														mediaTrack = "Media Track",
														alignment = "CENTERED",
														customPresets =
														{
															"Preset1",
															"Preset2",
															"Preset3"													
														}
													})
			--hmi side: expect UI.Show request
			EXPECT_HMICALL("UI.Show", 
							{ 
								alignment = "CENTERED",
								customPresets = 
								{  
									"Preset1",
									"Preset2",
									"Preset3"
								},
								-- graphic = 
								-- {
								--  imageType = "DYNAMIC",
								--  value = storagePath .. "action.png"
								-- },
								-- secondaryGraphic = 
								-- {
								--  imageType = "DYNAMIC",
								--  value = storagePath .. "action.png"
								-- },
								showStrings = 
								{							
									{
									fieldName = "mainField1",
									fieldText = "Show Line 1"
									},
									{
									fieldName = "mainField2",
									fieldText = "Show Line 2"
									},
									{
									fieldName = "mainField3",
									fieldText = "Show Line 3"
									},
									{
									fieldName = "mainField4",
									fieldText = "Show Line 4"
									},
									{
									fieldName = "mediaClock",
									fieldText = "12:34"
									},
									{
										fieldName = "mediaTrack",
										fieldText = "Media Track"
									},
									{
										fieldName = "statusBar",
										fieldText = "status bar"
									}
								},
								softButtons =
								{
									 {
										text = "default_action",
										systemAction = "DEFAULT_ACTION",
										type = "TEXT",
										isHighlighted = true,																
										softButtonID = 1
									 },
									 {
										text = "keep_context",
										systemAction = "KEEP_CONTEXT",
										type = "TEXT",
										isHighlighted = true,																
										softButtonID = 2
									 },
									 {
										text = "steal_focus",
										systemAction = "STEAL_FOCUS",
										type = "TEXT",
										isHighlighted = true,																
										softButtonID = 3
									 }
								 }
							})
				:Do(function(_,data)
					--hmi side: sending UI.Show response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
			
			--mobile side: expect Show response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })			
			
		end

		
		--Step 2 is coverted by SequenceChecks.1

		function Test:Show_TC_Show_10_Step3()

			--hmi side: send request to click on "keep_context" SoftButton
			self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {appID = self.applications["Test Application"], customButtonID = 2, mode = "BUTTONDOWN", name = "CUSTOM_BUTTON"})
			self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {appID = self.applications["Test Application"], customButtonID = 2, mode = "BUTTONUP", name = "CUSTOM_BUTTON"})
			self.hmiConnection:SendNotification("Buttons.OnButtonPress", {appID = self.applications["Test Application"], customButtonID = 2, mode = "SHORT", name = "CUSTOM_BUTTON"})

			--mobile side: notifications are sent to mobile app
			EXPECT_NOTIFICATION("OnButtonEvent", { customButtonID = 2, buttonEventMode = "BUTTONDOWN", buttonName = "CUSTOM_BUTTON"},
				{ customButtonID = 2, buttonEventMode = "BUTTONUP", buttonName = "CUSTOM_BUTTON"})
			:Times(2)				
		
			EXPECT_NOTIFICATION("OnButtonPress", { customButtonID = 2, buttonPressMode = "SHORT", buttonName = "CUSTOM_BUTTON"})		
			
		end
		
		function Test:Show_TC_Show_10_Step4()

			--hmi side: send request to click on "steal_focus" SoftButton
			self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {appID = self.applications["Test Application"], customButtonID = 3, mode = "BUTTONDOWN", name = "CUSTOM_BUTTON"})
			self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {appID = self.applications["Test Application"], customButtonID = 3, mode = "BUTTONUP", name = "CUSTOM_BUTTON"})
			self.hmiConnection:SendNotification("Buttons.OnButtonPress", {appID = self.applications["Test Application"], customButtonID = 3, mode = "SHORT", name = "CUSTOM_BUTTON"})

			--mobile side: notifications are sent to mobile app
			EXPECT_NOTIFICATION("OnButtonEvent", { customButtonID = 3, buttonEventMode = "BUTTONDOWN", buttonName = "CUSTOM_BUTTON"},
				{ customButtonID = 3, buttonEventMode = "BUTTONUP", buttonName = "CUSTOM_BUTTON"})
			:Times(2)				
		
			EXPECT_NOTIFICATION("OnButtonPress", { customButtonID = 3, buttonPressMode = "SHORT", buttonName = "CUSTOM_BUTTON"})		
			
		end			
		
	--End Test case SequenceChecks.9

--------------------------------------------------------------------------------------------------------------------------------------------

        --Begin Test case SequenceCheck.10
	--Description: Check test case TC_SoftButtons_01(SDLAQ-TC-68)
	
		--Requirement id in JAMA: SDLAQ-CRS-869

		--Verification criteria: Checking short click on TEXT soft button

 		function Test:Show_TEXTSoftButtons_ShortClick()

			
				local Request = 
										{
											mediaClock = "22:22",
											mainField1 = "Text1",
											mainField2 = "Text2",
											mainField3 = "Text3",
											mainField4 = "Text4",
											softButtons =
											  {
												{
													systemAction = "KEEP_CONTEXT",
													type = "TEXT",
													isHighlighted = false,
													text = "First",			
													softButtonID = 1
												},
                                                                                                {
													systemAction = "DEFAULT_ACTION",
													type = "TEXT",
													isHighlighted = true,
													text = "Second",			
													softButtonID = 2
												},
                                                                                                 {
													systemAction = "DEFAULT_ACTION",
													type = "TEXT",
													isHighlighted = true,
													text = "Third",
													image =
													{
													   imageType = "DYNAMIC",
													   value = "icon.png"
													},																
													softButtonID = 3
												}
											  },															
											statusBar = "new status bar",
											mediaTrack = "Track1"
										}
			
			--mobile side: sending Show request
			local cid = self.mobileSession:SendRPC("Show", Request)			
  

			--hmi side: expect UI.Show request
			local UIParams = self:createUIParameters(Request)
			EXPECT_HMICALL("UI.Show", UIParams)
			
				:Do(function(_,data)
					--hmi side: sending UI.Show response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
			
			--mobile side: expect Show response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			

			--hmi side: send request to short click on "Second" softButton
			self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 2, appID = self.applications["Test Application"]})
			self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 2, appID = self.applications["Test Application"]})
			self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "SHORT", customButtonID = 2, appID = self.applications["Test Application"]})
			

			--mobile side: notifications are sent to mobile app
			EXPECT_NOTIFICATION("OnButtonEvent", { customButtonID = 2, buttonEventMode = "BUTTONDOWN", buttonName = "CUSTOM_BUTTON"},
				                             { customButtonID = 2, buttonEventMode = "BUTTONUP", buttonName = "CUSTOM_BUTTON"})
			:Times(2)
		
			EXPECT_NOTIFICATION("OnButtonPress", { customButtonID = 2, buttonPressMode = "SHORT", buttonName = "CUSTOM_BUTTON"})
			:Times(1)

			
		end
			
         --End Test case SequenceCheck.10
	-----------------------------------------------------------------------------------------

	--Begin Test case SequenceCheck.11
	--Description: Check test case TC_SoftButtons_01(SDLAQ-TC-68)
	
		--Requirement id in JAMA: SDLAQ-CRS-200

		--Verification criteria: Checking TEXT soft button reflecting on UI only if text is defined

                   function Test:Show_TEXTSoftButtonsAndTextMissing()

				--mobile side: sending the request

				local Request = 	{
								mediaClock = "00:00:01",
								mainField1 = "Show1",
								softButtons =
								{
									{
													systemAction = "DEFAULT_ACTION",
													type = "TEXT",
													isHighlighted = false,
													image =
													{
													   imageType = "DYNAMIC",
													   value = "action.png"
													},																
													softButtonID = 1
												}
								}
							}

				local cid = self.mobileSession:SendRPC("Show", Request)
									
				--hmi side: expect the request
				local UIParams = self:createUIParameters(Request)
				EXPECT_HMICALL("UI.Show", UIParams)
                                :Times(0)		
							
				--mobile side: expect response 
				EXPECT_RESPONSE(cid, {  success = false, resultCode = "INVALID_DATA"})
				
			end
			
         --End Test case SequenceCheck.11
	-----------------------------------------------------------------------------------------

	--Begin Test case SequenceCheck.12
	--Description: Check test case TC_SoftButtons_01(SDLAQ-TC-68)
	
		--Requirement id in JAMA: SDLAQ-CRS-870

		--Verification criteria: Checking long click on TEXT soft button

		function Test:Show_TEXTSoftButtons_LongClick()

			
				local Request = 
										{
											mediaClock = "22:22",
											mainField1 = "Text1",
											mainField2 = "Text2",
											mainField3 = "Text3",
											mainField4 = "Text4",
											softButtons =
											  {
												{
													systemAction = "KEEP_CONTEXT",
													type = "TEXT",
													isHighlighted = false,
													text = "First",			
													softButtonID = 1
												},
                                                                                                {
													systemAction = "DEFAULT_ACTION",
													type = "TEXT",
													isHighlighted = true,
													text = "Second",			
													softButtonID = 2
												},
                                                                                                 {
													systemAction = "DEFAULT_ACTION",
													type = "TEXT",
													isHighlighted = true,
													text = "Third",
													image =
													{
													   imageType = "DYNAMIC",
													   value = "icon.png"
													},																
													softButtonID = 3
												}
											  },															
											statusBar = "new status bar",
											mediaTrack = "Track1"
										}
			
			--mobile side: sending Show request
			local cid = self.mobileSession:SendRPC("Show", Request)			
  

			--hmi side: expect UI.Show request
			local UIParams = self:createUIParameters(Request)
			EXPECT_HMICALL("UI.Show", UIParams)
			
				:Do(function(_,data)
					--hmi side: sending UI.Show response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
			
			--mobile side: expect Show response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			

			--hmi side: send request to long click on "Third" softButton
			self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 3, appID = self.applications["Test Application"]})
			self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 3, appID = self.applications["Test Application"]})
			self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "LONG", customButtonID = 3, appID = self.applications["Test Application"]})
			

			--mobile side: notifications are sent to mobile app
			EXPECT_NOTIFICATION("OnButtonEvent", { customButtonID = 3, buttonEventMode = "BUTTONDOWN", buttonName = "CUSTOM_BUTTON"},
				                             { customButtonID = 3, buttonEventMode = "BUTTONUP", buttonName = "CUSTOM_BUTTON"})
			:Times(2)
		
			EXPECT_NOTIFICATION("OnButtonPress", { customButtonID = 3, buttonPressMode = "LONG", buttonName = "CUSTOM_BUTTON"})
			:Times(1)

			
		end

      --End Test case SequenceCheck.12
   -------------------------------------------------------------------------------------------

 --Begin Test case SequenceCheck.13
	--Description: Check test case TC_SoftButtons_01(SDLAQ-TC-68)
	
		--Requirement id in JAMA: SDLAQ-CRS-200

		--Verification criteria: Checking TEXT soft button reflecting on UI only if text is defined

   		 function Test:Show_TEXTSoftButtonsAndTextWithWhiteSpaces()	

				--mobile side: sending the request

				local Request = 	{
								mediaClock = "00:00:01",
								mainField1 = "Show1",
								softButtons =
								{
									 {
													systemAction = "DEFAULT_ACTION",
													type = "TEXT",
                                                                                                        text = " ",
													isHighlighted = false,
													image =
													{
													   imageType = "DYNAMIC",
													   value = "action.png"
													},																
													softButtonID = 1
												}
								}
							}

				local cid = self.mobileSession:SendRPC("Show", Request)
									
				--hmi side: expect the request
				local UIParams = self:createUIParameters(Request)
				EXPECT_HMICALL("UI.Show", UIParams)
                                :Times(0)		
							
				--mobile side: expect response 
				EXPECT_RESPONSE(cid, {  success = false, resultCode = "INVALID_DATA"})
				
			end		     


       --End Test case SequenceCheck.13
	-----------------------------------------------------------------------------------------

 	--Begin Test case SequenceCheck.14
	--Description: Check test case TC_SoftButtons_02(SDLAQ-TC-75)
	--Info: This TC will be failing till resolving APPLINK-16052 
	
		--Requirement id in JAMA: SDLAQ-CRS-869

		--Verification criteria: Checking short click on IMAGE soft button
		
		function Test:Show_IMAGESoftButtons_ShortClick()

			
				local Request = 
										{
											mediaClock = "22:22",
											mainField1 = "Text1",
											mainField2 = "Text2",
											mainField3 = "Text3",
											mainField4 = "Text4",
											softButtons =
											  {
												{
													systemAction = "KEEP_CONTEXT",
													type = "IMAGE",
													isHighlighted = true,
													-- image =
													-- {
													--    imageType = "DYNAMIC",
													--    value = "icon.png"
													-- },		
													softButtonID = 1
												},
                                                                                             {
													systemAction = "DEFAULT_ACTION",
													type = "IMAGE",
													isHighlighted = true,
													text = "Second",
													-- image =
													-- {
													--    imageType = "DYNAMIC",
													--    value = "action.png"
													-- },																
													softButtonID = 2
												}
											  },															
											statusBar = "new status bar",
											mediaTrack = "Track1"
										}
			
			--mobile side: sending Show request
			local cid = self.mobileSession:SendRPC("Show", Request)			
  

			--hmi side: expect UI.Show request
			local UIParams = self:createUIParameters(Request)
			EXPECT_HMICALL("UI.Show", UIParams)
			
				:Do(function(_,data)
					--hmi side: sending UI.Show response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
			
			--mobile side: expect Show response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			

			--hmi side: send request to short click on "Action.png" softButton
			self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 2, appID = self.applications["Test Application"]})
			self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 2, appID = self.applications["Test Application"]})
			self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "SHORT", customButtonID = 2, appID = self.applications["Test Application"]})
			

			--mobile side: notifications are sent to mobile app
			EXPECT_NOTIFICATION("OnButtonEvent", { customButtonID = 2, buttonEventMode = "BUTTONDOWN", buttonName = "CUSTOM_BUTTON"},
				                             { customButtonID = 2, buttonEventMode = "BUTTONUP", buttonName = "CUSTOM_BUTTON"})
			:Times(2)
		
			EXPECT_NOTIFICATION("OnButtonPress", { customButtonID = 2, buttonPressMode = "SHORT", buttonName = "CUSTOM_BUTTON"})
			:Times(1)

			
		end

  	 --End Test case SequenceCheck.14
	-----------------------------------------------------------------------------------------

	--Begin Test case SequenceCheck.15
	--Description: Check test case TC_SoftButtons_02(SDLAQ-TC-75)
	--Info: This TC will be failing till resolving APPLINK-16052 

		--Requirement id in JAMA: SDLAQ-CRS-200

		--Verification criteria: Checking IMAGE soft button reflecting on UI only if image is defined 

                      function Test:Show_IMAGESoftButtonsAndImageNotExist()	

				--mobile side: sending the request

				local Request = 	{
								mediaClock = "00:00:01",
								mainField1 = "Show1",
								softButtons =
								{
									
												
                                                                                                 {
													systemAction = "KEEP_CONTEXT",
													type = "IMAGE",
                                                                                                        text = "First",
													isHighlighted = false,		
													softButtonID = 1
												}, 
												{
													systemAction = "KEEP_CONTEXT",
													type = "IMAGE",
													isHighlighted = true,
													image =
													{
													   imageType = "DYNAMIC",
													   value = "aaa"                    --image doesn't exist
													},		
													softButtonID = 1
												},
											
								}
							}

				local cid = self.mobileSession:SendRPC("Show", Request)
									
				--hmi side: expect the request
				local UIParams = self:createUIParameters(Request)
				EXPECT_HMICALL("UI.Show", UIParams)
                                :Times(0)		
							
				--mobile side: expect response 
				EXPECT_RESPONSE(cid, {  success = false, resultCode = "INVALID_DATA"})
				
			end


         --End Test case SequenceCheck.15
       ----------------------------------------------------------------------------------------------

	--Begin Test case SequenceCheck.16
	--Description: Check test case TC_SoftButtons_02(SDLAQ-TC-75)
	--Info: This TC will be failing till resolving APPLINK-16052 

		--Requirement id in JAMA: SDLAQ-CRS-870

		--Verification criteria: Checking long click on IMAGE soft button

		function Test:Show_IMAGESoftButtons_LongClick()

			
				local Request = 
										{
											mediaClock = "22:22",
											mainField1 = "Text1",
											mainField2 = "Text2",
											mainField3 = "Text3",
											mainField4 = "Text4",
											softButtons =
											  {
												{
													systemAction = "KEEP_CONTEXT",
													type = "IMAGE",
													isHighlighted = true,
													image =
													{
													   imageType = "DYNAMIC",
													   value = "icon.png"
													},		
													softButtonID = 1
												},
                                                                                             {
													systemAction = "DEFAULT_ACTION",
													type = "IMAGE",
													isHighlighted = false,
													image =
													{
													   imageType = "DYNAMIC",
													   value = "action.png"
													},																
													softButtonID = 2
												}
											  },															
											statusBar = "new status bar",
											mediaTrack = "Track1"
										}
			
			--mobile side: sending Show request
			local cid = self.mobileSession:SendRPC("Show", Request)			
  

			--hmi side: expect UI.Show request
			local UIParams = self:createUIParameters(Request)
			EXPECT_HMICALL("UI.Show", UIParams)
			
				:Do(function(_,data)
					--hmi side: sending UI.Show response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
			
			--mobile side: expect Show response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			

			--hmi side: send request to long click on "Action.png" softButton
			self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 2, appID = self.applications["Test Application"]})
			self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 2, appID = self.applications["Test Application"]})
			self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "LONG", customButtonID = 2, appID = self.applications["Test Application"]})
			

			--mobile side: notifications are sent to mobile app
			EXPECT_NOTIFICATION("OnButtonEvent", { customButtonID = 2, buttonEventMode = "BUTTONDOWN", buttonName = "CUSTOM_BUTTON"},
				                             { customButtonID = 2, buttonEventMode = "BUTTONUP", buttonName = "CUSTOM_BUTTON"})
			:Times(2)
		
			EXPECT_NOTIFICATION("OnButtonPress", { customButtonID = 2, buttonPressMode = "LONG", buttonName = "CUSTOM_BUTTON"})
			:Times(1)

			
		end
	
         --End Test case SequenceCheck.16

	-----------------------------------------------------------------------------------------
	--Begin Test case SequenceCheck.17
	--Description: Check test case TC_SoftButtons_03(SDLAQ-TC-156)
	--Info: This TC will be failing till resolving APPLINK-16052
	
		--Requirement id in JAMA: SDLAQ-CRS-869

		--Verification criteria: Checking short click on BOTH soft button

		function Test:Show_BOTHSoftButtons_ShortClick()

			
				local Request = 
										{
											mediaClock = "22:22",
											mainField1 = "Text1",
											mainField2 = "Text2",
											mainField3 = "Text3",
											mainField4 = "Text4",
											softButtons =
											  {
												{
													systemAction = "DEFAULT_ACTION",
													type = "BOTH",
													isHighlighted = false,
													text = "First",	
													image =
													{
													   imageType = "DYNAMIC",
													   value = "icon.png"
													},		
													softButtonID = 1
												},
                                                                                                {
													systemAction = "KEEP_CONTEXT",
													type = "BOTH",
													text = "Second",
													isHighlighted = true,
													image =
													{
													   imageType = "DYNAMIC",
													   value = "icon.png"
													},			
													softButtonID = 2
												},
                                                                                                 {
													systemAction = "DEFAULT_ACTION",
													type = "BOTH",
                                                                                                        text = "Third",
													isHighlighted = true,
													image =
													{
													   imageType = "DYNAMIC",
													   value = "action.png"
													},																
													softButtonID = 3
												}
											  },															
											statusBar = "new status bar",
											mediaTrack = "Track1"
										}
			
			--mobile side: sending Show request
			local cid = self.mobileSession:SendRPC("Show", Request)			
  

			--hmi side: expect UI.Show request
			local UIParams = self:createUIParameters(Request)
			EXPECT_HMICALL("UI.Show", UIParams)
			
				:Do(function(_,data)
					--hmi side: sending UI.Show response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
			
			--mobile side: expect Show response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			

			--hmi side: send request to short click on "Action.png" softButton
			self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 3, appID = self.applications["Test Application"]})
			self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 3, appID = self.applications["Test Application"]})
			self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "SHORT", customButtonID = 3, appID = self.applications["Test Application"]})
			

			--mobile side: notifications are sent to mobile app
			EXPECT_NOTIFICATION("OnButtonEvent", { customButtonID = 3, buttonEventMode = "BUTTONDOWN", buttonName = "CUSTOM_BUTTON"},
				                             { customButtonID = 3, buttonEventMode = "BUTTONUP", buttonName = "CUSTOM_BUTTON"})
			:Times(2)
		
			EXPECT_NOTIFICATION("OnButtonPress", { customButtonID = 3, buttonPressMode = "SHORT", buttonName = "CUSTOM_BUTTON"})
			:Times(1)

			
		end

	 --End Test case SequenceCheck.17
	
----------------------------------------------------------------------------------------------------------------------

	--Begin Test case SequenceCheck.18
	--Description: Check test case TC_SoftButtons_03(SDLAQ-TC-156)
	--Info: This TC will be failing till resolving APPLINK-16052 
	
		--Requirement id in JAMA: SDLAQ-CRS-2912

		--Verification criteria: Check that On.ButtonEvent(CUSTOM_BUTTON) notification is not transferred from HMI to mobile app by SDL if CUSTOM_BUTTON is not subscribed 

		          
      	       function Test:UnsubscribeButton_CUSTOM_BUTTON_SUCCESS()
	
		--mobile side: send UnsubscribeButton request
		local cid = self.mobileSession:SendRPC("UnsubscribeButton",
			{
				buttonName = "CUSTOM_BUTTON"
			})

			--hmi side: expect OnButtonSubscription notification
			EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {name = "CUSTOM_BUTTON", isSubscribed = false})
			:Timeout(5000)

			-- Mobile side: expects SubscribeButton response 
			-- Mobile side: expects EXPECT_NOTIFICATION("OnHashChange") if SUCCESS	
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
	                --:Timeout(13000)
	
		end

		function Test:Show_BOTHSoftButtons_AfterUnsubscribe()

			
				local Request = 
										{
											mediaClock = "22:22",
											mainField1 = "Text1",
											mainField2 = "Text2",
											mainField3 = "Text3",
											mainField4 = "Text4",
											softButtons =
											  {
												{
													systemAction = "DEFAULT_ACTION",
													type = "BOTH",
													isHighlighted = true,
													text = "First",	
													image =
													{
													   imageType = "DYNAMIC",
													   value = "action.png"
													},		
													softButtonID = 1
												}
											  },															
											statusBar = "new status bar",
											mediaTrack = "Track1"
										}
			
			--mobile side: sending Show request
			local cid = self.mobileSession:SendRPC("Show", Request)			
  

			--hmi side: expect UI.Show request
			local UIParams = self:createUIParameters(Request)
			EXPECT_HMICALL("UI.Show", UIParams)
			
				:Do(function(_,data)
					--hmi side: sending UI.Show response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
			
			--mobile side: expect Show response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			

			--hmi side: send request to short click on "First" softButton
			self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 1, appID = self.applications["Test Application"]})
			self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 1, appID = self.applications["Test Application"]})
			self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "SHORT", customButtonID = 1, appID = self.applications["Test Application"]})
			

			--mobile side: notifications are sent to mobile app
			EXPECT_NOTIFICATION("OnButtonEvent", { customButtonID = 1, buttonEventMode = "BUTTONDOWN", buttonName = "CUSTOM_BUTTON"},
				                             { customButtonID = 1, buttonEventMode = "BUTTONUP", buttonName = "CUSTOM_BUTTON"})
			:Times(0)
		
			EXPECT_NOTIFICATION("OnButtonPress", { customButtonID = 1, buttonPressMode = "SHORT", buttonName = "CUSTOM_BUTTON"})
			:Times(0)

			
		end
	
 	--End Test case SequenceCheck.18

       ----------------------------------------------------------------------------------------------

	--Begin Test case SequenceCheck.19
	--Description: Check test case TC_SoftButtons_03(SDLAQ-TC-156)
	
		--Requirement id in JAMA: SDLAQ-CRS-200

		--Verification criteria: Checking BOTH soft button reflecting on UI only if image and text are defined 

		function Test:Show_BOTHSoftButtonImageNotDefined()	

				--mobile side: sending the request

				local Request = 	{
								mediaClock = "00:00:01",
								mainField1 = "Show1",
								softButtons =
								{
									
												
                                                                                                {
													systemAction = "DEFAULT_ACTION",
													type = "BOTH",
													isHighlighted = false,
													text = "First",			
													softButtonID = 1
												},
											
								}
							}

				local cid = self.mobileSession:SendRPC("Show", Request)
									
				--hmi side: expect the request
				local UIParams = self:createUIParameters(Request)
				EXPECT_HMICALL("UI.Show", UIParams)
                                :Times(0)		
							
				--mobile side: expect response 
				EXPECT_RESPONSE(cid, {  success = false, resultCode = "INVALID_DATA"})
				
			end		

        --End Test case SequenceCheck.19

-----------------------------------------------------------------------------------------------

        --Begin Test case SequenceCheck.20
	--Description: Check test case TC_SoftButtons_04(SDLAQ-TC-157)
	--Info: This TC will be failing till resolving APPLINK-16052 
	
		--Requirement id in JAMA: SDLAQ-CRS-870

		--Verification criteria: Checking long click on BOTH soft button


       		  function Test:Show_BOTHSoftButtons_LongClick()

			
				local Request = 
										{
											mediaClock = "22:22",
											mainField1 = "Text1",
											mainField2 = "Text2",
											mainField3 = "Text3",
											mainField4 = "Text4",
											softButtons =
											  {
												{
													type = "BOTH",
													isHighlighted = true,
													text = "First",	
													image =
													{
													   imageType = "DYNAMIC",
													   value = "icon.png"
													},		
													softButtonID = 1
												}
											  },															
											statusBar = "new status bar",
											mediaTrack = "Track1"
										}
			
			--mobile side: sending Show request
			local cid = self.mobileSession:SendRPC("Show", Request)			
  

			--hmi side: expect UI.Show request
			local UIParams = self:createUIParameters(Request)
			EXPECT_HMICALL("UI.Show", UIParams)

				:Do(function(_,data)
					--hmi side: sending UI.Show response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
			
			--mobile side: expect Show response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			

			--hmi side: send request to long click on "First" softButton
			self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 1, appID = self.applications["Test Application"]})
			self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 1, appID = self.applications["Test Application"]})
			self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "LONG", customButtonID = 1, appID = self.applications["Test Application"]})
			

			--mobile side: notifications are sent to mobile app
			EXPECT_NOTIFICATION("OnButtonEvent", { customButtonID = 1, buttonEventMode = "BUTTONDOWN", buttonName = "CUSTOM_BUTTON"},
				                             { customButtonID = 1, buttonEventMode = "BUTTONUP", buttonName = "CUSTOM_BUTTON"})
			:Times(2)
		
			EXPECT_NOTIFICATION("OnButtonPress", { customButtonID = 1, buttonPressMode = "LONG", buttonName = "CUSTOM_BUTTON"})
			:Times(1)

			
		end

		
        --End Test case SequenceCheck.20

----------------------------------------------------------------------------------------------

	--Begin Test case SequenceCheck.21
	--Description: Check test case TC_SoftButtons_03(SDLAQ-TC-156)
	
		--Requirement id in JAMA: SDLAQ-CRS-200

		--Verification criteria: Checking BOTH soft button reflecting on UI only if image and text are defined 

		function Test:Show_BOTHSoftButtonImageAndTextNotDefined()	

				--mobile side: sending the request

				local Request = 	{
								mediaClock = "00:00:01",
								mainField1 = "Show1",
								softButtons =
								{
									
												
                                                                                                {
													systemAction = "DEFAULT_ACTION",
													type = "BOTH",
													isHighlighted = false,			
													softButtonID = 1
												},
											
								}
							}

				local cid = self.mobileSession:SendRPC("Show", Request)
									
				--hmi side: expect the request
				local UIParams = self:createUIParameters(Request)
				EXPECT_HMICALL("UI.Show", UIParams)
                                :Times(0)		
							
				--mobile side: expect response 
				EXPECT_RESPONSE(cid, {  success = false, resultCode = "INVALID_DATA"})
				
			end		

        --End Test case SequenceCheck.21


end

SequenceChecks()


----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VII---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------

--Description: Check different HMIStatus

--Requirement id in JAMA: 	
	--SDLAQ-CRS-774: HMI Status Requirement for Show 
	--Verification criteria: Show request is allowed in FULL, LIMITED, BACKGROUND HMI level

--Verify resultCode in NONE, LIMITED, BACKGROUND hmi level
commonTestCases:verifyDifferentHMIStatus("DISALLOWED", "SUCCESS", "SUCCESS")

--ToDO: Please note that ActivationApp fails due to APPLINK-16046, remove comment once issue is fixed

return Test
