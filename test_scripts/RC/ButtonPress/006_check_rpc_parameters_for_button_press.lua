---------------------------------------------------------------------------------------------------
-- Requirement summary:
-- [SDL_RC] Button press event emulation
--
-- Description:
-- In case:
-- 1) RC app sends ButtonPress request with invalid parameters
-- SDL must:
-- 1) Do not transfer request to HMI
-- 2) Respond with success:false, "INVALID_DATA"
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

--[[ Local Functions ]]
local function reset_climate_params()
    return {moduleType = "CLIMATE", buttonName = "AC", buttonPressMode = "SHORT"}
end

local function reset_radio_params()
    return {moduleType = "RADIO", buttonName = "VOLUME_UP", buttonPressMode = "SHORT"}
end

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

    EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
end

local function SendButtonPressNegative(button_press_params, self)
    local cid = self.mobileSession:SendRPC("ButtonPress", button_press_params)

    EXPECT_HMICALL("Buttons.ButtonPress")
    :Times(0)

    EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

    commonTestCases:DelayedExp(commonRC.timeout)
end

--[[ Positive Scenario - check all positive climate names params]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Step("Activate App", commonRC.activate_app)

for _, button_name_value in pairs( climate_button_names ) do
    local climate_params = reset_climate_params()
    climate_params.buttonPressMode = "SHORT"
    climate_params.buttonName = button_name_value
    runner.Title("Test - ButtonPress with buttonName " .. button_name_value)
    runner.Step("ButtonPress_CLIMATE_" .. button_name_value .. "_SHORT", SendButtonPressPositive, {climate_params})
    climate_params.buttonPressMode = "LONG"
    runner.Step("ButtonPress_CLIMATE_" .. button_name_value .. "_LONG", SendButtonPressPositive, {climate_params})
end

--[[ Positive Scenario - check all positive radio names params]]
for _, button_name_value in pairs( radio_button_names ) do
    local radio_params = reset_radio_params()
    radio_params.buttonPressMode = "SHORT"
    radio_params.buttonName = button_name_value
    runner.Title("Test - ButtonPress with buttonName " .. button_name_value)
    runner.Step("ButtonPress_RADIO_" .. button_name_value .. "_SHORT", SendButtonPressPositive, {radio_params})
    radio_params.buttonPressMode = "LONG"
    runner.Step("ButtonPress_RADIO_" .. button_name_value .. "_LONG", SendButtonPressPositive, {radio_params})
end

--[[ Negative Scenario - invalid value of buttonName in mobile request]]
local climate_params = reset_climate_params()
local radio_params = reset_radio_params()
climate_params.buttonName = "invalid_name"
radio_params.buttonName = "invalid_name"
runner.Title("Test - negative, invalid value of buttonName in mobile request")
runner.Step("ButtonPress_CLIMATE", SendButtonPressNegative, {climate_params})
runner.Step("ButtonPress_RADIO", SendButtonPressNegative, {radio_params})
climate_params = reset_climate_params()
radio_params = reset_radio_params()

--[[ Negative Scenario - invalid value of buttonPressMode in mobile request]]
climate_params.buttonPressMode = "invalid_name"
radio_params.buttonPressMode = "invalid_name"
runner.Title("Test - negative, invalid value of buttonPressMode in mobile request")
runner.Step("ButtonPress_CLIMATE", SendButtonPressNegative, {climate_params})
runner.Step("ButtonPress_RADIO", SendButtonPressNegative, {radio_params})
runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
