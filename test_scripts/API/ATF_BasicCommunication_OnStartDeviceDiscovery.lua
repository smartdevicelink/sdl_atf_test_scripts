Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
require('user_modules/AppTypes')

---------------------------------------------------------------------------------------------
------------------------------------------Common functions-----------------------------------
---------------------------------------------------------------------------------------------
function DelayedExp(time)
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  :Timeout(time+1000)
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, time)
end

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK I----------------------------------------
--------------------------------Check normal cases of Mobile request---------------------------
-----------------------------------------------------------------------------------------------

--Not Applicable

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK II----------------------------------------
-----------------------------Check special cases of Mobile request----------------------------
----------------------------------------------------------------------------------------------

--Not Applicable

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK III--------------------------------------
---------------------------------Check normal cases of HMI response----------------------------
-----------------------------------------------------------------------------------------------
	commonFunctions:newTestCasesGroup("Normal cases of HMI response")
	--Description: Check the processing in case
		--1. HMI sends valid BasicCommunication.OnStartDeviceDiscovery
	--Requirement: 
		--https://adc.luxoft.com/svn/APPLINK/doc/technical/HOW-TOs_and_Guidelines/FORD.SmartDeviceLink.SDL_Integration_Guidelines.docx
	-------------------------------------------------------------------------------------------

	function Test:OnStartDeviceDiscovery_Valid()
		self.hmiConnection:Send('{"jsonrpc":"2.0","method":"BasicCommunication.OnStartDeviceDiscovery"}')
		EXPECT_HMICALL("BasicCommunication.UpdateDeviceList")
			:Do(function(_,data)
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
		:Times(1)
		
		DelayedExp(10000)
	end

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK IV----------------------------------------
----------------------------Check special cases of HMI response---------------------------
----------------------------------------------------------------------------------------------
	commonFunctions:newTestCasesGroup("Special cases of HMI response")
	--Description: Check the processing in case
		--1. Invalid Json BasicCommunication.OnStartDeviceDiscovery
		--2. Invalid Structure BasicCommunication.OnStartDeviceDiscovery
		--3. Wrong Type BasicCommunication.OnStartDeviceDiscovery
		--4. Missing parameter in BasicCommunication.OnStartDeviceDiscovery
		--5. Missing all parameters in BasicCommunication.OnStartDeviceDiscovery
		
	--Requirement: 
		--https://adc.luxoft.com/svn/APPLINK/doc/technical/HOW-TOs_and_Guidelines/FORD.SmartDeviceLink.SDL_Integration_Guidelines.docx

	-------------------------------------------------------------------------------------------

	-- InvalidJsonSyntax
	function Test:OnStartDeviceDiscovery_InvalidJsonSyntax()
		self.hmiConnection:Send('{"jsonrpc";"2.0","method":"BasicCommunication.OnStartDeviceDiscovery"}')

		EXPECT_HMICALL("BasicCommunication.UpdateDeviceList")
			:Do(function(_,data)
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
		:Times(0)
		
		DelayedExp(1000)
	end

	------------------------------------------------------------------------------------------

	-- InvalidStructure
	function Test:OnStartDeviceDiscovery_InvalidStructure()
		self.hmiConnection:Send('{"jsonrpc":"2.0"{"method":"BasicCommunication.OnStartDeviceDiscovery"}}')
		
		EXPECT_HMICALL("BasicCommunication.UpdateDeviceList")
			:Do(function(_,data)
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
		:Times(0)
		
		DelayedExp(1000)
	end

	------------------------------------------------------------------------------------------

	-- WrongType
	function Test:OnStartDeviceDiscovery_WrongType()
		self.hmiConnection:Send('{"jsonrpc":"abc","method":"BasicCommunication.OnStartDeviceDiscovery"}}')
		
		EXPECT_HMICALL("BasicCommunication.UpdateDeviceList")
			:Do(function(_,data)
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
		:Times(0)
		
		DelayedExp(1000)
	end

	--------------------------------------------------------------------------------------

	-- Missing parameter
	function Test:OnStartDeviceDiscovery_MissingParam()
		self.hmiConnection:Send('{"method":"BasicCommunication.OnStartDeviceDiscovery"}')
		
		EXPECT_HMICALL("BasicCommunication.UpdateDeviceList")
			:Do(function(_,data)
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
		:Times(0)
		
		DelayedExp(1000)
	end
	
	--------------------------------------------------------------------------------------

	-- Missing all parameters
	function Test:OnStartDeviceDiscovery_MissingAllParams()
		self.hmiConnection:Send('{}')
		
		EXPECT_HMICALL("BasicCommunication.UpdateDeviceList")
			:Do(function(_,data)
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
		:Times(0)
		
		DelayedExp(1000)
	end

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK V----------------------------------------
-------------------------------------Checks All Result Codes-----------------------------------
-----------------------------------------------------------------------------------------------

--Not applicable

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VI----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------

--Not applicable