---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0256-Refactor-Fuel-Information-Related-Vehicle-Data.md
-- Description: The app is not able to receive the parameters from HMI in case app version is less than parameters version,
-- parameter is listed in DB and API
-- In case:
-- 1) App is registered with syncMsgVersion=5.0
-- 2) New params in `FuelRange` structure have since=6.2 in DB and API
-- 3) App is subscribed to `FuelRange` data
-- 4) App requests GetVehicleData(fuelRange)
-- 5) HMI responds to GetVehicleData with all parameters in `FuelRange` structure
-- SDL does:
--  a) cut off the params from HMI response that allowed for apps starting from 6.2 version
--  b) send GetVehicleData response to mobile app without not allowed params
-- 6) HMI sends valid OnVehicleData notification with all parameters of `FuelRange` structure
-- SDL does:
--  a) cut off new params of structure `FuelRange` from HMI notification that allowed for apps starting from 6.2 version
--  b) send OnVehicleData notification to app without new params of structure `FuelRange`
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/Refactor_Fuel_Information/common')

-- [[ Test Configuration ]]
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 5
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 0

local expectedVehicleData = {
  type = common.allVehicleData.type,
  range = common.allVehicleData.range
}

--[[ Local Functions ]]
local function getVehicleData()
  local cid = common.getMobileSession():SendRPC("GetVehicleData", { fuelRange = true })
  common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { fuelRange = true })
  :Do(function(_,data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { fuelRange = { common.allVehicleData } })
  end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS", fuelRange = { expectedVehicleData } } )
  :ValidIf(function(_,data)
    if data.payload.fuelRange[1].level or
      data.payload.fuelRange[1].levelState or
      data.payload.fuelRange[1].capacity or
      data.payload.fuelRange[1].capacityUnit then
        return false, "Unexpected params are received in GetVehicleData response"
    end
    return true
  end)
end

local function sendOnVehicleData()
  common.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { fuelRange = { common.allVehicleData } })
  common.getMobileSession():ExpectNotification("OnVehicleData", { fuelRange = { expectedVehicleData } })
  :ValidIf(function(_,data)
    if data.payload.fuelRange[1].level or
      data.payload.fuelRange[1].levelState or
      data.payload.fuelRange[1].capacity or
      data.payload.fuelRange[1].capacityUnit then
        return false, "Unexpected params are received in OnVehicleData notification"
    end
    return true
  end)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { common.pTUpdateFunc })
common.Step("Activate App", common.activateApp)
common.Step("App subscribes to fuelRange data", common.subUnScribeVD, { "SubscribeVehicleData", common.subUnsubParams })

common.Title("Test")
common.Step("App sends GetVehicleData for fuelRange", getVehicleData)
common.Step("OnVehicleData without new fuelRange parameters", sendOnVehicleData)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
