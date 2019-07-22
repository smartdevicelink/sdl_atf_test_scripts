---------------------------------------------------------------------------------------------------
-- User story: TO ADD !!!
-- Use case: TO ADD !!!
-- Item: Use Case 1: TO ADD!!!
--
-- Requirement summary:
-- [OnVehicleData] As a mobile app is subscribed for VI parameter
-- and received notification about this parameter change from hmi
--
-- Description:
-- In case:
-- 1) If application is subscribed to get vehicle data with 'engineOilLife' parameter
-- 2) Notification about changes in subscribed parameter is received from hmi
-- SDL must:
-- Forward this notification to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/commonVehicleData')

--[[ Local Variables ]]
local rpc1 = {
  name = "SubscribeVehicleData",
  params = {
    engineOilLife = true,
    fuelRange = true,
    tirePressure = true,
    electronicParkBrakeStatus = true,
    turnSignal = true
  }
}

local rpc2 = {
  name = "OnVehicleData",
  params = {
    engineOilLife = 50.3,
    fuelRange = {
      {
        type = "GASOLINE",
        range = 400.00
      }
    },
    tirePressure = {
      leftFront = {
        status = "NORMAL",
        tpms = "SYSTEM_ACTIVE",
        pressure = 35.00
      },
      rightFront = {
        status = "NORMAL",
        tpms = "SYSTEM_ACTIVE",
        pressure = 35.00
      }
    },
    electronicParkBrakeStatus = "CLOSED",
    turnSignal = "OFF"
  }
}

local vehicleDataResults = {
  engineOilLife = {
    dataType = "VEHICLEDATA_ENGINEOILLIFE",
    resultCode = "SUCCESS"
  },
  fuelRange = {
    dataType = "VEHICLEDATA_FUELRANGE",
    resultCode = "SUCCESS"
  },
  tirePressure = {
    dataType = "VEHICLEDATA_TIREPRESSURE",
    resultCode = "SUCCESS"
  },
  electronicParkBrakeStatus = {
    dataType = "VEHICLEDATA_ELECTRONICPARKBRAKESTATUS",
    resultCode = "SUCCESS"
  },
  turnSignal = {
    dataType = "VEHICLEDATA_TURNSIGNAL",
    resultCode = "SUCCESS"
  }
}

--[[ Local Functions ]]
local function processRPCSubscribeSuccess(self)
  local mobileSession = common.getMobileSession(self, 1)
  local cid = mobileSession:SendRPC(rpc1.name, rpc1.params)
  EXPECT_HMICALL("VehicleInfo." .. rpc1.name, rpc1.params)
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", vehicleDataResults)
    end)

  local responseParams = common.cloneTable(vehicleDataResults)
  responseParams.success = true
  responseParams.resultCode = "SUCCESS"
  mobileSession:ExpectResponse(cid, responseParams)
end

local function checkNotificationSuccess(self)
  local mobileSession = common.getMobileSession(self, 1)
  self.hmiConnection:SendNotification("VehicleInfo." .. rpc2.name, rpc2.params)
  mobileSession:ExpectNotification("OnVehicleData", rpc2.params)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI with PTU", common.registerAppWithPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("RPC " .. rpc1.name, processRPCSubscribeSuccess)
runner.Step("RPC " .. rpc2.name, checkNotificationSuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
