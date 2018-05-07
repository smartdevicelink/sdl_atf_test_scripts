---------------------------------------------------------------------------------------------------
-- VehicleData common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")

--[[ Local Variables ]]
local commonVehicleData = actions

commonVehicleData.timeout = 2000
commonVehicleData.minTimeout = 500

return commonVehicleData

