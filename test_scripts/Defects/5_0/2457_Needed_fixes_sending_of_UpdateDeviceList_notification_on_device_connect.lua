---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2457
--
-- Description:
-- Steps to reproduce:
-- 1) HMI and SDL started, connect device.
-- Expected:
-- 1) SDL has to notify system with BC.UpdateDeviceList on device connect even if device does not have any SDL-enabled applications running.
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local utils = require ('user_modules/utils')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local function ]]
local function start ()
    common.start()
    common.getHMIConnection():ExpectRequest("BasicCommunication.UpdateDeviceList",
        { deviceList = { { id = utils.getDeviceMAC(), name = utils.getDeviceName()} } })
    common.getHMIConnection():ExpectRequest("BasicCommunication.OnDeviceAdded")
    :Times(0)
  end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)

-- [[ Test ]]
runner.Title("Test")
runner.Step("Start SDL, HMI, connect Mobile", start)

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
