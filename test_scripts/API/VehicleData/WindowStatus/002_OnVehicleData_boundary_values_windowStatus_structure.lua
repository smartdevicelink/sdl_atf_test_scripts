---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0261-New-vehicle-data-WindowStatus.md
--
-- Description: SDL transfers OnVehicleData notification to subscribed app if HMI sends this notification
-- with valid values of 'windowStatus' structure sub-parameters:
--    location: { col, row, level, colspan, rowspan, levelspan }
--    state: { approximatePosition, deviation }
--
-- In case:
-- 1) App is subscribed to 'windowStatus' data.
-- 2) HMI sends the 'windowStatus' structure with valid values for sub-parameters.
-- SDL does:
--  a) process this notification and transfer it to mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/common')

--[[ Local Variables ]]
local param = "windowStatus"
local windowStatusData = {
  {
    location = { col = 0, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1 },
    state = {
      approximatePosition = 50,
      deviation = 50
    }
  }
}

local windowStatusDataMinValues = {
  location = { col = -1, row = -1, level = -1, colspan = 1, rowspan = 1, levelspan = 1 },
  state = { approximatePosition = 0, deviation = 0 }
}

local windowStatusDataMaxValues = {
  location = { col = 100, row = 100, level = 100, colspan = 100, rowspan = 100, levelspan = 100 },
  state = { approximatePosition = 100, deviation = 100 }
}

local maxArraySize = {}
for i = 1, 100 do
  maxArraySize[i] = windowStatusData[1]
end

--[[ Local Functions ]]
local function getCustomData(pSubParam, pParam, pValue)
  local params = common.cloneTable(windowStatusData)
  params[1][pParam][pSubParam] = pValue
  return params
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)
common.Step("RPC " .. common.rpc.sub, common.processSubscriptionRPC, { common.rpc.sub, param })

common.Title("Test")
common.Title("VD parameter: " .. param)
for k in common.spairs(windowStatusData[1].state) do
  common.Step("RPC " .. common.rpc.on .. " minValue " .. k .. "=" .. windowStatusDataMinValues.state[k],
    common.sendOnVehicleData, { param, common.isExpected, getCustomData(k, "state", windowStatusDataMinValues.state[k]) })
  common.Step("RPC " .. common.rpc.on .. " maxValue " .. k .. "=" .. windowStatusDataMaxValues.state[k],
    common.sendOnVehicleData, { param, common.isExpected, getCustomData(k, "state", windowStatusDataMaxValues.state[k]) })
end
for k in common.spairs(windowStatusData[1].location) do
  common.Step("RPC " .. common.rpc.on .. " minValue " .. k .. "=" .. windowStatusDataMinValues.location[k],
    common.sendOnVehicleData, { param, common.isExpected, getCustomData(k, "location", windowStatusDataMinValues.location[k]) })
  common.Step("RPC " .. common.rpc.on .. " maxValue " .. k .. "=" .. windowStatusDataMaxValues.location[k],
    common.sendOnVehicleData, { param, common.isExpected, getCustomData(k, "location", windowStatusDataMaxValues.location[k]) })
end
common.Step("RPC " .. common.rpc.on .. " max windowStatus array size",
  common.sendOnVehicleData, { param, common.isExpected, maxArraySize })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
