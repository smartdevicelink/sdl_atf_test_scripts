---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] <device identifier>. User clears all these applications
--
-- Description:
-- All applications from new device are successfully registered AND the User clears all these applications from the list of registered applications
-- 1. Used preconditions:
-- Delete files and policy table from previous ignition cycle if any
-- Connect new device
-- Register App1
-- Register App2
-- Unregister App1
-- Unregister App2
--
-- 2. Performed steps:
-- Connect second device
--
-- Expected result:
-- Device must be still visible by SDL and must NOT be removed from HMI`s list of connected devices:
-- SDL->HMI: BC.UpdateDeviceList(device1, device2)
-- HMI->SDL: BC.UpdateDeviceList(SUCCESS)
--------------------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Local Variables ]]
local anotherDeviceParams = { host = "1.0.0.1", port = config.mobilePort }
local anotherDeviceName = anotherDeviceParams.host .. ":" .. anotherDeviceParams.port

--[[ Local Functions ]]
local function connectDeviceTwo()
    EXPECT_HMICALL("BasicCommunication.UpdateDeviceList",
    {
      deviceList = {
        {
          transportType = "WEBENGINE_WEBSOCKET",
        },
        {
          name = anotherDeviceName,
          isSDLAllowed = false,
          transportType = "WIFI"
        },
        {
          name = utils.getDeviceName(),
          transportType = utils.getDeviceTransportType()
        }
    }})
    :Do(function(_,data)
      actions.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)

    utils.addNetworkInterface(2, anotherDeviceParams.host)
    actions.mobile.createConnection(2, anotherDeviceParams.host, anotherDeviceParams.port)
    actions.mobile.connect(2)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI", actions.start)
common.Step("Register App1", actions.registerAppWOPTU, { 1 })
common.Step("Register App2", actions.registerAppWOPTU, { 2 })
common.Step("Unregister App1", actions.app.unRegister, { 1 })
common.Step("Unregister App2", actions.app.unRegister, { 2 })

common.Title("Test")
common.Step("Connect another mobile device, verify device list", connectDeviceTwo)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
