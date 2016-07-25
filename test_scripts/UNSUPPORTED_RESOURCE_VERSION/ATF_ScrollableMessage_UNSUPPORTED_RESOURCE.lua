--------------------------------------------------------------------------------
-- Preconditions before ATF start
--------------------------------------------------------------------------------
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
--------------------------------------------------------------------------------
--Precondition: preparation connecttest_UI_unavailable.lua
os.execute(  'cp ./modules/connecttest.lua  ./user_modules/connecttest_UI_unavailable.lua')

f = assert(io.open('./user_modules/connecttest_UI_unavailable.lua', "r"))

  fileContent = f:read("*all")
  f:close()

 -- update hmiCapabilities in UI.GetLanguage
	local pattern1 = 'ExpectRequest%s-%(%s-"%s-UI.GetLanguage%s-".-%{'
	local ResultPattern2 = fileContent:match(pattern1)

	if ResultPattern2 == nil then 
    	print(" \27[31m ExpectRequest UI.GetLanguage call is not found in /user_modules/connecttest_UI_unavailable.lua \27[0m ")
  	else
	    fileContent  =  string.gsub(fileContent, pattern1, 'ExpectRequest("UI.GetLanguage", false, {')
  	end

-- update hmiCapabilities in UI.ChangeRegistration
	local pattern1 = 'ExpectRequest%s-%(%s-"%s-UI.ChangeRegistration%s-".-%{'
	local ResultPattern2 = fileContent:match(pattern1)

	if ResultPattern2 == nil then 
    	print(" \27[31m ExpectRequest UI.ChangeRegistration call is not found in /user_modules/connecttest_UI_unavailable.lua \27[0m ")
  	else
	    fileContent  =  string.gsub(fileContent, pattern1, 'ExpectRequest("UI.ChangeRegistration", false, {')
  	end

-- update hmiCapabilities in UI.GetSupportedLanguages
	local pattern1 = 'ExpectRequest%s-%(%s-"%s-UI.GetSupportedLanguages%s-".-%{'
	local ResultPattern2 = fileContent:match(pattern1)

	if ResultPattern2 == nil then 
    	print(" \27[31m ExpectRequest UI.GetSupportedLanguages call is not found in /user_modules/connecttest_UI_unavailable.lua \27[0m ")
  	else
	    fileContent  =  string.gsub(fileContent, pattern1, 'ExpectRequest("UI.GetSupportedLanguages", false, {')
  	end

-- update hmiCapabilities in UI.GetCapabilities
	local pattern1 = 'ExpectRequest%s-%(%s-"%s-UI.GetCapabilities%s-".-%{'
	local ResultPattern2 = fileContent:match(pattern1)

	if ResultPattern2 == nil then 
    	print(" \27[31m ExpectRequest UI.GetCapabilities call is not found in /user_modules/connecttest_UI_unavailable.lua \27[0m ")
  	else
	    fileContent  =  string.gsub(fileContent, pattern1, 'ExpectRequest("UI.GetCapabilities", false, {')
  	end

-- update hmiCapabilities in UI.IsReady
	local pattern1 = 'ExpectRequest%s-%(%s-"%s-UI.IsReady%s-".-%{.-%}%s-%)'
	local ResultPattern2 = fileContent:match(pattern1)

	if ResultPattern2 == nil then 
    	print(" \27[31m ExpectRequest UI.IsReady call is not found in /user_modules/connecttest_UI_unavailable.lua \27[0m ")
  	else
	    fileContent  =  string.gsub(fileContent, pattern1, 'ExpectRequest("UI.IsReady", true, { available = false })')
  	end


f = assert(io.open('./user_modules/connecttest_UI_unavailable.lua', "w"))
f:write(fileContent)
f:close()
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

Test = require('user_modules/connecttest_UI_unavailable')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')

local hmi_connection = require('hmi_connection')
local websocket      = require('websocket_connection')
local module         = require('testbase')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')


---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
require('user_modules/AppTypes')

APIName = "ScrollableMessage" -- set request name


---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

	--Print new line to separate Preconditions
	commonFunctions:newTestCasesGroup("Preconditions")

	-- Precondition: removing user_modules/connecttest_UI_unavailable.lua
	function Test:Precondition_remove_user_connecttest()
	 	os.execute( "rm -f ./user_modules/connecttest_UI_unavailable.lua" )
	end

	--1. Delete app_info.dat, logs and policy table
	commonSteps:DeleteLogsFileAndPolicyTable()

	--1. Activate application
	commonSteps:ActivationApp()


	--2. PutFiles ("action.png")
	commonSteps:PutFile("PutFile_icon.png", "action.png")

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK V----------------------------------------
-------------------------------------Checks All Result Codes-----------------------------------
-----------------------------------------------------------------------------------------------

--Begin Test suit ResultCodeChecks


--Print new line to separate test suite
commonFunctions:newTestCasesGroup("Test suit For ResultCodeChecks")


--Description: Check UNSUPPORTED_RESOURCE resultCode

	--Requirement id in JAMA: SDLAQ-CRS-1036

    --Verification criteria:  Used if UI isn't available now (not supported). General request result "success" should be "false".

		function Test:ScrollableMessage_UNSUPPORTED_RESOURCE()

			local Request =
			{
				scrollableMessageBody = "abc",
				softButtons =
				{
					{
						softButtonID = 1,
						text = "Button1",
						type = "IMAGE",
						image =
						{
							value = "action.png",
							imageType = "DYNAMIC"
						},
						isHighlighted = false,
						systemAction = "DEFAULT_ACTION"
					}
				},
				timeout = 5000
			}

		--request from mobile side
		local cid= self.mobileSession:SendRPC("ScrollableMessage", Request)

		--response on mobile side
		EXPECT_RESPONSE(cid, { success = false, resultCode = "UNSUPPORTED_RESOURCE", info = "Destination controller not found!"})
		:Timeout(12000)
	end
--End Test suit ResultCodeChecks


 return Test
