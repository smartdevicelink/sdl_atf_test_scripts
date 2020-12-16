---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0261-New-vehicle-data-WindowStatus.md
--
-- Description: SDL processes GetVehicleData if HMI responds with valid values
-- for 'windowStatus' structure sub-parameters:
--    location: { col, row, level, colspan, rowspan, levelspan }
--    state: { approximatePosition, deviation }
--
-- In case:
-- 1) App sends GetVehicleData request with windowStatus=true to the SDL and this request is allowed by Policies.
-- 2) SDL transfers this request to HMI.
-- 3) HMI sends GetVehicleData response with 'windowStatus' structure with valid values sub-parameters
-- SDL does:
--  a) process this response and transfer it to mobile app.
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

common.Title("Test")
common.Title("VD parameter: " .. param)
for k in common.spairs(windowStatusData[1].state) do
  common.Step("RPC " .. common.rpc.get .. " minValue " .. k .. "=" .. windowStatusDataMinValues.state[k],
    common.getVehicleData, { param, getCustomData(k, "state", windowStatusDataMinValues.state[k]) })
  common.Step("RPC " .. common.rpc.get .. " maxValue " .. k .. "=" .. windowStatusDataMaxValues.state[k],
    common.getVehicleData, { param, getCustomData(k, "state", windowStatusDataMaxValues.state[k]) })
end
for k in common.spairs(windowStatusData[1].location) do
  common.Step("RPC " .. common.rpc.get .. " minValue " .. k .. "=" .. windowStatusDataMinValues.location[k],
    common.getVehicleData, { param, getCustomData(k, "location", windowStatusDataMinValues.location[k]) })
  common.Step("RPC " .. common.rpc.get .. " maxValue " .. k .. "=" .. windowStatusDataMaxValues.location[k],
    common.getVehicleData, { param, getCustomData(k, "location", windowStatusDataMaxValues.location[k]) })
end
common.Step("RPC " .. common.rpc.get .. " max windowStatus array size",
  common.getVehicleData, { param, maxArraySize })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
