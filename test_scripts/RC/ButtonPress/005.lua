---------------------------------------------------------------------------------------------------
-- RPC: ButtonPress
-- Script: 005
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonRC = require('test_scripts/RC/commonRC')
local runner = require('user_modules/script_runner')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

--[[ Local variables for tests ]]
local climate_button_names = {
    "AC_MAX",
    "AC",
    "RECIRCULATE",
    "FAN_UP",
    "FAN_DOWN",
    "TEMP_UP",
    "TEMP_DOWN",
    "DEFROST_MAX",
    "DEFROST",
    "DEFROST_REAR",
    "UPPER_VENT",
    "LOWER_VENT"
}

local radio_button_names = {
    "VOLUME_UP",
    "VOLUME_DOWN",
    "EJECT",
    "SOURCE",
    "SHUFFLE",
    "REPEAT",
}

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
local function SendButtonPressPositive(button_press_params, self)
    local cid = self.mobileSession:SendRPC("ButtonPress", button_press_params)

    EXPECT_HMICALL("Buttons.ButtonPress", {
        appID = self.applications["Test Application"],
        moduleType = button_press_params.moduleType,
        buttonName = button_press_params.buttonName,
        buttonPressMode = button_press_params.buttonPressMode
    })
    :Times(1)
    :Do(function(_, data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)

    EXPECT_RESPONSE(cid, { success = false, resultCode = "SUCCESS" })

    commonTestCases:DelayedExp(commonRC.timeout)
end

local function SendButtonPressNegative(button_press_params, self)
    local cid = self.mobileSession:SendRPC("ButtonPress", button_press_params)

    EXPECT_HMICALL("Buttons.ButtonPress")
    :Times(0)

    EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

    commonTestCases:DelayedExp(commonRC.timeout)
end

--[[ Positive Scenario - check all positive climate names params]]
for _, button_name_value in pairs( climate_button_names ) do
    climate_params.buttonPressMode = "SHORT"
    runner.Title("Preconditions")
    runner.Step("Clean environment", commonRC.preconditions)
    runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
    runner.Step("RAI, PTU", commonRC.rai_ptu)
    runner.Title("Test - ButtonPress with buttonName " .. button_name_value)
    runner.Step("ButtonPress_CLIMATE", SendButtonPressPositive, {climate_params})
    runner.Step("ButtonPress_RADIO", SendButtonPressNegative, {radio_params})
    runner.Title("Postconditions")
    runner.Step("Stop SDL", commonRC.postconditions)
end

--[[ Negative Scenario - not matched params in mobile request]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Title("Test - negative, not matched params in mobile request")
runner.Step("ButtonPress_CLIMATE", SendButtonPressNegative, {climate_params})
runner.Step("ButtonPress_RADIO", SendButtonPressNegative, {radio_params})
runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
