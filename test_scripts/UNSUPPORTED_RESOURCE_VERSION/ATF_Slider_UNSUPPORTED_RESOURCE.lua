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
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
require('user_modules/AppTypes')

APIName = "Slider" -- set request name


---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

	-- Precondition: removing user_modules/connecttest_UI_unavailable.lua
	function Test:Precondition_remove_user_connecttest()
	 	os.execute( "rm -f ./user_modules/connecttest_UI_unavailable.lua" )
	end

	--1. Activate application
	commonSteps:ActivationApp()



-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK V----------------------------------------
-------------------------------------Checks All Result Codes-----------------------------------
-----------------------------------------------------------------------------------------------

--Begin Test suit ResultCodeChecks
--Description: Check UNSUPPORTED_RESOURCE resultCode

	--Requirement id in JAMA: SDLAQ-CRS-1032

    --Verification criteria:  When the request is sent and UI isn't avaliable at the moment on current HMI, UNSUPPORTED_RESOURCE is returned as a result of request. Info parameter provides additional information about the case. General request result success=false.

		function Test:Slider_UNSUPPORTED_RESOURCE()

			--mobile side: request parameters
			local Request =
			{
				numTicks = 3,
				position = 2,
				sliderHeader ="sliderHeader",
				sliderFooter = {"1", "2", "3"},
				timeout = 5000
			}

		--request from mobile side
		local cid= self.mobileSession:SendRPC("Slider", Request)

		--response on mobile side
		EXPECT_RESPONSE(cid, { success = false, resultCode = "UNSUPPORTED_RESOURCE", info = "Destination controller not found!"})
		:Timeout(12000)
	end
--End Test suit ResultCodeChecks

return Test
