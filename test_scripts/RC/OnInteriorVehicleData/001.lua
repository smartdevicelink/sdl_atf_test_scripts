---------------------------------------------------------------------------------------------------
-- RPC: OnInteriorVehicleData
-- Script: 001
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonRC = require('test_scripts/RC/commonRC')
local runner = require('user_modules/script_runner')

--[[ Local Functions ]]
local function step1_1(self)
	local cid = self.mobileSession:SendRPC("GetInteriorVehicleData", {
			moduleDescription =	{
				moduleType = "CLIMATE",
				moduleZone = commonRC.getInteriorZone()
			},
			subscribe = true
		})

	EXPECT_HMICALL("RC.GetInteriorVehicleData", {
			appID = self.applications["Test Application"],
			moduleDescription =	{
				moduleType = "CLIMATE",
				moduleZone = commonRC.getInteriorZone()
			},
			subscribe = true
		})
  :Do(function(_, data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
					isSubscribed = true,
					moduleData = {
						moduleType = "CLIMATE",
						moduleZone = commonRC.getInteriorZone(),
						climateControlData = commonRC.getClimateControlData()
					}
				})
	end)

	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", isSubscribed = true })
end

local function step1_2(self)
	local climateControlData = {
    fanSpeed = 50,
    currentTemp = 86,
    desiredTemp = 75,
    temperatureUnit = "FAHRENHEIT",
    acEnable = true,
    circulateAirEnable = true,
    autoModeEnable = true,
    defrostZone = "FRONT",
    dualModeEnable = true
  }

 	self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
			moduleData = {
	      moduleType = "CLIMATE",
	      moduleZone = commonRC.getInteriorZone(),
	      climateControlData = climateControlData
	    }
	  })

  EXPECT_NOTIFICATION("OnInteriorVehicleData", {
  		moduleData = {
	  		moduleType = "CLIMATE",
	  		moduleZone = commonRC.getInteriorZone(),
	  		climateControlData = climateControlData
  		}
  	})
end

local function step2_1(self)
	local cid = self.mobileSession:SendRPC("GetInteriorVehicleData", {
			moduleDescription =	{
				moduleType = "RADIO",
				moduleZone = commonRC.getInteriorZone()
			},
			subscribe = true
		})

	EXPECT_HMICALL("RC.GetInteriorVehicleData", {
			appID = self.applications["Test Application"],
			moduleDescription =	{
				moduleType = "RADIO",
				moduleZone = commonRC.getInteriorZone()
			},
			subscribe = true
		})
  :Do(function(_, data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
					isSubscribed = true,
					moduleData = {
						moduleType = "RADIO",
						moduleZone = commonRC.getInteriorZone(),
						radioControlData = commonRC.getRadioControlData()
					}
				})
	end)

	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", isSubscribed = true })
end

local function step2_2(self)
	local radioControlData = {
    frequencyInteger = 1,
    frequencyFraction = 2,
    band = "AM",
    rdsData = {
        PS = "ps",
        RT = "rt",
        CT = "123456789012345678901234",
        PI = "pi",
        PTY = 2,
        TP = false,
        TA = true,
        REG = "US"
      },
    availableHDs = 1,
    hdChannel = 1,
    signalStrength = 5,
    signalChangeThreshold = 20,
    radioEnable = true,
    state = "ACQUIRING"
  }

 	self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
			moduleData = {
	      moduleType = "RADIO",
	      moduleZone = commonRC.getInteriorZone(),
	      radioControlData = radioControlData
	    }
	  })

  EXPECT_NOTIFICATION("OnInteriorVehicleData", {
  		moduleData = {
	  		moduleType = "RADIO",
	  		moduleZone = commonRC.getInteriorZone(),
	  		radioControlData = radioControlData
  		}
  	})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Title("Test")
runner.Step("GetInteriorVehicleData_CLIMATE", step1_1)
runner.Step("OnInteriorVehicleData_CLIMATE", step1_2)
runner.Step("GetInteriorVehicleData_RADIO", step2_1)
runner.Step("OnInteriorVehicleData_RADIO", step2_2)
runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
