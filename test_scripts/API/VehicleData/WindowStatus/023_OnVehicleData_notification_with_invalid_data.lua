---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0261-New-vehicle-data-WindowStatus.md
--
-- Description: Check that SDL does not transfer OnVehicleData notification to subscribed app if HMI sends notification
-- with invalid values of `windowStatus` structure params:
--    location: { col, row, level, colspan, rowspan, levelspan }
--    state: { approximatePosition, deviation }
--
-- In case:
-- 1) App is subscribed to `windowStatus` data.
-- 2) HMI sends the invalid `windowStatus` structure in OnVehicleData notification:
--    - invalid parameter name
--    - invalid parameter type
--    - missing mandatory parameter
--    - value out of bounds
--    - empty structures
-- SDL does:
--  a) ignore this notification.
--  b) not send OnVehicleData notification to mobile.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/WindowStatus/common')

-- [[ Test Configuration ]]
config.zeroOccurrenceTimeout = 500

--[[ Local Variables ]]
local invalidValue = {
  invalidType = true,
  greaterMax = 101,
  lessThanMin = -2
}

local maxArraySize = {}
for i = 1, invalidValue.greaterMax do
  maxArraySize[i] = common.getWindowStatusParams()[1]
end

local invalidParam = {
  ["empty_location"] = {
    { location = {}, -- empty location parameter
      state = common.getWindowStatusParams()[1].state
    }
  },
  ["invalidType_location"] = {
    { location = "string", -- invalid type for location parameter
      state = common.getWindowStatusParams()[1].state
    }
  },
  ["missing_location"] = { -- without location parameter
    { state = common.getWindowStatusParams()[1].state }
  },
  ["invalidName_location"] ={ -- invalid name for location parameter
    { loCaTion = { col = 49, row = 49 },
      state = common.getWindowStatusParams()[1].state
    }
  },
  ["invalidName_col"] = { -- invalid name for col parameter from Grid structure
    { location = { CoL = 49, row = 49 },
      state = common.getWindowStatusParams()[1].state
    }
  },
  ["invalidName_row"] = { -- invalid name for row parameter from Grid structure
    { location = { col = 49, RoW = 49 },
      state = common.getWindowStatusParams()[1].state
    }
  },
  ["empty_state"] = { -- empty state parameter
    { location = common.getWindowStatusParams()[1].location,
      state = {}
    }
  },
  ["invalidType_state"] = { -- invalid type for state parameter
    { location = common.getWindowStatusParams()[1].location,
      state = "string"
    }
  },
  ["missing_state"] = { -- without state parameter
    { location = common.getWindowStatusParams()[1].location }
  },
  ["invalidName_state"] = { -- invalid name for state parameter
    { location = common.getWindowStatusParams()[1].location,
      StaTe = { approximatePosition = 50, deviation = 50 }
    }
  },
  ["invalidName_approximatePosition"] = { -- invalid name for approximatePosition parameter from WindowState structure
    { location = common.getWindowStatusParams()[1].location,
      state = { ApproximatePositioN = 50, deviation = 50 }
    }
  },
  ["invalidName_deviation"] = { -- invalid name for deviation parameter from WindowState structure
    { location = common.getWindowStatusParams()[1].location,
      state = { approximatePosition = 50, DeviatioN = 50 }
    }
  },
  ["missing_col"] = { -- without col parameter from Grid structure
    { location = { row = 49, level = 49, colspan = 49, rowspan = 49, levelspan = 49 },
      state = { approximatePosition = 50, deviation = 50 }
    }
  },
  ["missing_row"] = { -- without row parameter from Grid structure
    { location = { col = 49, level = 49, colspan = 49, rowspan = 49, levelspan = 49 },
      state = { approximatePosition = 50, deviation = 50 }
    }
  },
  ["array_greater_max_size"] = maxArraySize,
  ["empty_array"] = {}
}

local notExpected = 0

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)
common.Step("App subscribes to windowStatus data", common.subUnScribeVD, { "SubscribeVehicleData" })

common.Title("Test")
for param in common.spairs(common.getWindowStatusParams()[1].location) do
  common.Title("HMI sends OnVehicleData with invalid `windowStatus` structure for " .. param)
  for k, v in common.spairs(invalidValue) do
    common.Step("OnVehicleData with invalid value for " .. param .. "=" .. tostring(k),
      common.sendOnVehicleData, { common.getCustomData(param, "location", v), notExpected })
  end
end

for param in common.spairs(common.getWindowStatusParams()[1].state) do
  common.Title("HMI sends OnVehicleData with invalid `windowStatus` structure for " .. param)
  for k, v in common.spairs(invalidValue) do
    common.Step("OnVehicleData with invalid value for " .. param .. "=" .. tostring(k),
    common.sendOnVehicleData, { common.getCustomData(param, "state", v), notExpected })
  end
end

common.Title("Check for other parameters")
for k, v in common.spairs(invalidParam) do
  common.Step("OnVehicleData with " .. k, common.sendOnVehicleData, { v, notExpected })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
