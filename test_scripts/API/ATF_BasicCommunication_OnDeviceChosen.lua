Test = require('connecttest')
require('cardinalities')
local events = require('events')	
local mobile_session = require('mobile_session')

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
require('user_modules/AppTypes')

local DEVICE_ID = config.deviceMAC
local DEVICE_NAME = "127.0.0.1"

---------------------------------------------------------------------------------------------
-------------------------------------------Common function-----------------------------------
---------------------------------------------------------------------------------------------
function BC_OnDeviceChosen_Notification(self, Description, Method, DeviceInfo)
	
	self.hmiConnection:SendNotification("BasicCommunication.OnStartDeviceDiscovery")

	EXPECT_HMICALL("BasicCommunication.UpdateDeviceList")
	:Do(function(exp,data)
		
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

		if (Description == "Invalid Json") then		
			self.hmiConnection:Send('{"method";"BasicCommunication.OnDeviceChosen","params":{"deviceInfo":{"name":"127.0.0.1","id":"12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"}},"jsonrpc":"2.0"}')
		else
			self.hmiConnection:SendNotification( Method, { deviceInfo = DeviceInfo })
		end

	end)
	
	commonTestCases:DelayedExp(5000)
	
end


---------------------------------------------------------------------------------------------
-----------------------------------------I TEST BLOCK----------------------------------------
---------------Check notification BasicCommunication.OnDeviceChosen from HMI-----------------
---------------------------------------------------------------------------------------------	

	--Description: TC's checks processing 
		--HMI sends BasicCommunication.OnDeviceChosen notification with positive case and (full deviceInfo)
		--HMI sends BasicCommunication.OnDeviceChosen notification with Missing deviceInfo
		--HMI sends BasicCommunication.OnDeviceChosen notification with Missing deviceID
		--HMI sends BasicCommunication.OnDeviceChosen notification with Missing DeviceName
		--HMI sends BasicCommunication.OnDeviceChosen notification with Missing ID and Name
		--HMI sends BasicCommunication.OnDeviceChosen notification with Missing All Parameters
		--HMI sends BasicCommunication.OnDeviceChosen notification with Missing Method
		--HMI sends BasicCommunication.OnDeviceChosen notification with Empty deviceInfo
		--HMI sends BasicCommunication.OnDeviceChosen notification with Empty deviceID
		--HMI sends BasicCommunication.OnDeviceChosen notification with WrongType deviceInfo
		--HMI sends BasicCommunication.OnDeviceChosen notification with WrongType deviceID
		--HMI sends BasicCommunication.OnDeviceChosen notification with WrongType deviceName
		--HMI sends BasicCommunication.OnDeviceChosen notification with WrongType ID and Name
		--HMI sends BasicCommunication.OnDeviceChosen notification with Invalid Json

		--Requirement id in JAMA: 
				--APPLINK-24441: https://adc.luxoft.com/svn/APPLINK/doc/technical/HOW-TOs_and_Guidelines/FORD.SmartDeviceLink.SDL_Integration_Guidelines.docx (6.10)
				
		----------------------------------------------------------------------------------------------		

		local TestData = {
			{description = "Positive Case",				method = "BasicCommunication.OnDeviceChosen", deviceInfo = {id = DEVICE_ID, name = DEVICE_NAME}	},
			{description = "Missing deviceInfo",		method = "BasicCommunication.OnDeviceChosen", deviceInfo = nil 									},
			{description = "Missing deviceID", 			method = "BasicCommunication.OnDeviceChosen", deviceInfo = {id = nil, name = DEVICE_NAME}		},
			{description = "Missing DeviceName", 		method = "BasicCommunication.OnDeviceChosen", deviceInfo = {id = DEVICE_ID, name = nil}			},
			{description = "Missing ID and Name", 		method = "BasicCommunication.OnDeviceChosen", deviceInfo = {id = nil, name = nil}				},
			{description = "Missing All Parameters", 	method = nil, 								  deviceInfo = nil									},
			{description = "Missing Method", 			method = nil,								  deviceInfo = {id = DEVICE_ID, name = DEVICE_NAME}	},
			{description = "Empty deviceInfo", 			method = "BasicCommunication.OnDeviceChosen", deviceInfo = {}									},
			{description = "Empty deviceID", 			method = "BasicCommunication.OnDeviceChosen", deviceInfo = {name = DEVICE_NAME}					},
			{description = "Empty deviceName", 			method = "BasicCommunication.OnDeviceChosen", deviceInfo = {id = DEVICE_ID}						},
			{description = "WrongType deviceInfo", 		method = "BasicCommunication.OnDeviceChosen", deviceInfo = 1234									},
			{description = "WrongType deviceID", 		method = "BasicCommunication.OnDeviceChosen", deviceInfo = {id = true, name = DEVICE_NAME}		},
			{description = "WrongType deviceName", 		method = "BasicCommunication.OnDeviceChosen", deviceInfo = {id = DEVICE_ID, name = {1234}}		},
			{description = "WrongType ID and Name", 	method = "BasicCommunication.OnDeviceChosen", deviceInfo = {id = 1234, name = true}				},
			{description = "Invalid Json", 				_, 											   _,												}
		}		

		----------------------------------------------------------------------------------------------				

		-- commonSteps:ActivationApp()
		
		--Main executing
		for i=1, #TestData do
			
			--Print new line to separate new test cases group
			commonFunctions:newTestCasesGroup("-----------------------I." ..tostring(i).." [" ..TestData[i].description .. "]------------------------------")
			
			Test["BC_" .. TestData[i].description] = function(self)
				BC_OnDeviceChosen_Notification(self, TestData[i].description, TestData[i].method, TestData[i].deviceInfo)
			end
			
		end