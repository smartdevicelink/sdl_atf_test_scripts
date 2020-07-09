---------------------------------------------------------------------------------------------------
-- Description:
-- Mobile sends multiple unknown enum included in an array of structs. The structs containing the
-- enums will be filtered out because the invalid enum was mandatory. An empty softbuttons array
-- will still be transfered to the HMI because the minsize of the softbutton array is 0.

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL

-- Steps:
-- appID requests Show with two softbuttons that use an unknown softbutton type/

-- Expected:
-- SDL Core attempts to filter out the unknown enum and removes all invalid softbutton objects.
-- HMI receives the show request with an empty softbutton array.
-- Mobile receives a WARNINGS result code.
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local putFileParams = {
  requestParams = {
    syncFileName = 'icon.png',
    fileType = "GRAPHIC_PNG",
    persistentFile = false,
    systemFile = false
  },
  filePath = "files/icon.png"
}

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
  graphic = {
    imageType = "DYNAMIC",
    value = "icon.png"
  },
  secondaryGraphic = {
    imageType = "DYNAMIC",
    value = "icon.png"
  },
  metadataTags = {
    mainField1 = { "mediaTitle" },
    mainField2 = { "mediaArtist" },
    mainField3 = { "mediaAlbum" },
    mainField4 = { "mediaYear" },
  },
  softButtons = {
    {
    softButtonID = 1,
    type = "UNKNOWN_1"
    },
    {
    softButtonID = 2,
    type = "UNKNOWN_2",
    text = "Hello"
    },
  }
}

local responseUiParams = {
  showStrings = {
    {
      fieldName = "mainField1",
      fieldText = requestParams.mainField1,
      fieldTypes = requestParams.metadataTags.mainField1
    },
    {
      fieldName = "mainField2",
      fieldText = requestParams.mainField2,
      fieldTypes = requestParams.metadataTags.mainField2
    },
    {
      fieldName = "mainField3",
      fieldText = requestParams.mainField3,
      fieldTypes = requestParams.metadataTags.mainField3
    },
    {
      fieldName = "mainField4",
      fieldText = requestParams.mainField4,
      fieldTypes = requestParams.metadataTags.mainField4
    },
    {
      fieldName = "templateTitle",
      fieldText = requestParams.templateTitle
    },
    {
      fieldName = "mediaClock",
      fieldText = requestParams.mediaClock
    },
    {
      fieldName = "mediaTrack",
      fieldText = requestParams.mediaTrack
    },
    {
      fieldName = "statusBar",
      fieldText = requestParams.statusBar
    }
  },
  alignment = requestParams.alignment,
  graphic = {
    imageType = requestParams.graphic.imageType,
    value = common.getPathToFileInAppStorage(requestParams.graphic.value)
  },
  secondaryGraphic = {
    imageType = requestParams.secondaryGraphic.imageType,
    value = common.getPathToFileInAppStorage(requestParams.secondaryGraphic.value)
  }
}

local allParams = {
  requestParams = requestParams,
  responseUiParams = responseUiParams,
}

--[[ Local Functions ]]
local function show(pParams)
  local cid = common.getMobileSession():SendRPC("Show", pParams.requestParams)
  pParams.responseUiParams.appID = common.getHMIAppId()
  common.getHMIConnection():ExpectRequest("UI.Show", pParams.responseUiParams)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  :ValidIf(function(_, data)
      return #data.params["softButtons"] == 0
    end)
  common.getMobileSession():ExpectResponse(cid, {
    success = true,
    resultCode = "WARNINGS"
  }):ValidIf(function(_, data)
    local res1 = string.match(data.payload.info, "softButtons.0")
    local res2 = string.match(data.payload.info, "softButtons.1")
    return res1 and res2
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("Upload icon file", common.putFile, { putFileParams })

runner.Title("Test")
runner.Step("Show Positive Case", show, { allParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
