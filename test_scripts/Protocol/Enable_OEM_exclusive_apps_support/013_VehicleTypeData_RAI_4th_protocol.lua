---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL is able to provide all vehicle type data in RAI response in case the app is registered
--  via 4th protocol
--
-- Steps:
-- 1. HMI provides all vehicle type data in BC.GetSystemInfo(ccpu_version, systemHardwareVersion)
--  and VI.GetVehicleType(make, model, modelYear, trim) responses
-- 2. App requests RAI via 4th protocol
-- SDL does:
--  - Provide the vehicle type info with all parameter values received from HMI in RAI response to the app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Test Configuration ]]
config.defaultProtocolVersion = 4 -- Set 4 protocol as default for script

--[[ Local Variables ]]
local hmiCap = common.setHMIcap(common.vehicleTypeInfoParams.default)

--[[ Local Functions ]]
local function registerApp(responseExpectedData)
  local session = common.createSession()
  session:StartService(7)
  :Do(function()
     common.registerAppEx(responseExpectedData)
  end)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { hmiCap })

common.Title("Test")
common.Step("Vehicle type data in RAI", registerApp, { common.vehicleTypeInfoParams.default })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
