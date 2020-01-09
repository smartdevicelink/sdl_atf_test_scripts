---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/1006
-- Description: SDL responses with GENERIC_ERROR instead of UNSUPPORTED_RESOURCE
-- Precondition:
-- 1) SDL and HMI are started.
-- In case:
-- 1) Any single UI-related RPC is requested , UI interface is not supported by the system
-- 2) SDL receives UI.IsReady (available=false) from HMI
-- Expected result:
-- 1) SDL must respond "UNSUPPORTED_RESOURCE, success=false, info: UI is not supported by system" to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")
local hmi_values = require("user_modules/hmi_values")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParams = {
  mainField1 = "mainField1_text",
  mainField2 = "mainField2_text",
  mainField3 = "mainField3_text",
  mainField4 = "mainField4_text",
  templateTitle = "templateTitle_text",
  statusBar = "statusBar_text",
  mediaClock = "mediaClock_text",
  mediaTrack = "mediaTrack_text",
  alignment = "CENTERED",
  metadataTags = {
    mainField1 = { "mediaTitle" },
    mainField2 = { "mediaArtist" },
    mainField3 = { "mediaAlbum" },
    mainField4 = { "mediaYear" },
  }
}

--[[ Local Functions ]]
local function getHMIValues()
  local params = hmi_values.getDefaultHMITable()
  params.UI.IsReady.params.available = false
  params.UI.GetCapabilities = nil
  params.UI.GetLanguage = nil
  params.UI.GetSupportedLanguages = nil
  return params
end

local function sendShow()
  local cid = common.getMobileSession():SendRPC("Show", requestParams)
  common.getHMIConnection():ExpectRequest("UI.Show")
  :Times(0)
  common.getMobileSession():ExpectResponse(cid, {success = false, resultCode = "UNSUPPORTED_RESOURCE"})
end

--[[ Test ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, {getHMIValues()})
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Sends Show", sendShow)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
