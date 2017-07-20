---------------------------------------------------------------------------------------------------
-- RPC: ButtonPress
-- Script: 005
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonRC = require('test_scripts/RC/commonRC')
local runner = require('user_modules/script_runner')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

-- Climate Buttons
-- "AC_MAX"
-- "AC"
-- "RECIRCULATE"
-- "FAN_UP"
-- "FAN_DOWN"
-- "TEMP_UP"
-- "TEMP_DOWN"
-- "DEFROST_MAX"
-- "DEFROST"
-- "DEFROST_REAR"
-- "UPPER_VENT"
-- "LOWER_VENT"

local climate_params = {
    moduleType = "CLIMATE",
    buttonName = "VOLUME_UP",
    buttonPressMode = "SHORT" -- LONG, SHORT
}

local radio_params = {
    moduleType = "RADIO",
    buttonName = "AC",
    buttonPressMode = "LONG"
}


--[[ Local Functions ]]
local function SendButtonPress(button_press_params, self)
    local cid = self.mobileSession:SendRPC("ButtonPress", button_press_params)

    EXPECT_HMICALL("Buttons.ButtonPress")
    :Times(0)

    EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

    commonTestCases:DelayedExp(commonRC.timeout)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Title("Test")
runner.Step("ButtonPress_CLIMATE", SendButtonPress, {climate_params})
runner.Step("ButtonPress_RADIO", SendButtonPress, {radio_params})
runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
