---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0266-New-vehicle-data-GearStatus.md
--
-- Description: SDL successfully processes GetVehicleData response if 'gearStatus' structure contains one parameter.
--
-- In case:
-- 1) App sends GetVehicleData(gearStatus=true) request.
-- SDL does:
--  a) transfer this request to HMI.
-- 2) HMI sends the 'gearStatus' structure with only one parameter in GetVehicleData response.
-- SDL does:
--  a) respond with resultCode:'SUCCESS' to app with only one parameter.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/common')

-- [[ Local Variables ]]
local param = "gearStatus"

local transmissionTypeEnumValues = {
  "MANUAL",
  "AUTOMATIC",
  "SEMI_AUTOMATIC",
  "DUAL_CLUTCH",
  "CONTINUOUSLY_VARIABLE",
  "INFINITELY_VARIABLE",
  "ELECTRIC_VARIABLE",
  "DIRECT_DRIVE"
}

local prndlEnumValues = {
  "PARK",
  "REVERSE",
  "NEUTRAL",
  "DRIVE",
  "SPORT",
  "LOWGEAR",
  "FIRST",
  "SECOND",
  "THIRD",
  "FOURTH",
  "FIFTH",
  "SIXTH",
  "SEVENTH",
  "EIGHTH",
  "NINTH",
  "TENTH",
  "UNKNOWN",
  "FAULT"
}

local gearStatusData = {
  userSelectedGear = prndlEnumValues,
  actualGear = prndlEnumValues,
  transmissionType = transmissionTypeEnumValues
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Title("VD parameter: " .. param)
for sub_param, data in common.spairs(gearStatusData) do
  for _, value in common.spairs(data) do
    common.Step("RPC " .. common.rpc.get .. " param " .. sub_param .. "=" .. value,
      common.getVehicleData, { param, { [sub_param] = value } })
  end
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
