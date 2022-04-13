---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: SetDisplayLayout
-- Item: Happy path
--
-- Requirement summary:
-- [SetDisplayLayout] SUCCESS on UI.SetDisplayLayout
--
-- Description:
-- Mobile application sends SetDisplayLayout request with valid parameters to SDL
--
-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
--
-- Steps:
-- Application sends SetDisplayLayout request with valid parameters to SDL
--
-- Expected:
-- SDL validates parameters of the request
-- SDL checks if UI interface is available on HMI
-- SDL checks if SetDispLay is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL transfers the UI part of request with allowed parameters to HMI
-- SDL receives UI part of response from HMI with "SUCCESS" result code
-- SDL transfers response to mobile app
-- Note: since "SetDisplayLayout" is deprecated SDL has to respond with WARNINGS to mobile in success case
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')
local hmi_values = require('user_modules/hmi_values')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function getRequestParams()
  return { displayLayout = "TEMPLATE" }
end

local function getHMIRequestParams()
  return  { templateConfiguration = { template = "TEMPLATE" } }
end

local function getResponseParams()
  local hmiTable = hmi_values.getDefaultHMITable()
  local defaultDisplayCapabilities = hmiTable.UI.GetCapabilities.params.displayCapabilities
  defaultDisplayCapabilities.imageCapabilities = nil -- some capabilities are excluded due to SDL issue

  return {
    displayCapabilities = defaultDisplayCapabilities,
    buttonCapabilities = hmiTable.Buttons.GetCapabilities.params.capabilities,
    softButtonCapabilities = hmiTable.UI.GetCapabilities.params.softButtonCapabilities,
    presetBankCapabilities = hmiTable.Buttons.GetCapabilities.params.presetBankCapabilities
  }
end

local function setDisplaySuccess()
  local responseParams = getResponseParams()
  local cid = common.getMobileSession():SendRPC("SetDisplayLayout", getRequestParams())
  common.getHMIConnection():ExpectRequest("UI.Show", getHMIRequestParams())
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getMobileSession():ExpectResponse(cid, {
    success = true,
    resultCode = "WARNINGS",
    displayCapabilities = responseParams.displayCapabilities,
    buttonCapabilities = responseParams.buttonCapabilities,
    softButtonCapabilities = responseParams.softButtonCapabilities,
    presetBankCapabilities = responseParams.presetBankCapabilities
  })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("SetDisplay Positive Case", setDisplaySuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
