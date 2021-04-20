---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: Set Menu Layout
-- Item: Happy path
--
-- Requirement summary:
-- [ReadDID] SUCCESS: getting SUCCESS:VehicleInfo.GetSystemCapabilities()
--
-- Description:
-- HMI Has capability to support a TILES menuLayout

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level
-- d. HMI display capabilities member menuLayoutsAvailable contains TILES

-- Steps:
-- Mobile App calls SetGlobalProperties with menuLayout = TILES
-- Mobile App calls AddSubMenu with menuLayout = TILES

-- Expected:
-- SDL responds with (resultCode: SUCCESS, success:true) to mobile application for both requests
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local addSubMenuParams = {
  menuLayout = "TILES",
  menuID = 44991234,
  menuName = "sickMenu"
}

local setGlobalPropertiesParams = {
  menuLayout = "TILES"
}

local successResponse = {
  success = true,
  resultCode = "SUCCESS"
}

local onSystemCapabilityUpdatedParams = {
  systemCapability = {
    systemCapabilityType = "DISPLAYS",
    displayCapabilities = {
      {
        displayName = "displayName",
        windowTypeSupported = {
          {
            type = "MAIN",
            maximumNumberOfWindows = 1
          },
          {
            type = "WIDGET",
            maximumNumberOfWindows = 2
          }
        },
        windowCapabilities = {
          {
            menuLayoutsAvailable = { "LIST", "TILES" },
            textFields = {
              {
                name = "mainField1",
                characterSet = "UTF_8",
                width = 1,
                rows = 1
              }
            },
            imageFields = {
              {
                name = "choiceImage",
                imageTypeSupported = { "GRAPHIC_PNG"
                },
                imageResolution = {
                  resolutionWidth = 35,
                  resolutionHeight = 35
                }
              }
            },
            imageTypeSupported = {
              "STATIC"
            },
            templatesAvailable = {
              "Template1", "Template2", "Template3", "Template4", "Template5"
            },
            numCustomPresetsAvailable = 100,
            buttonCapabilities = {
              {
                longPressAvailable = true,
                name = "VOLUME_UP",
                shortPressAvailable = true,
                upDownAvailable = false
              }
            },
            softButtonCapabilities = {
              {
                shortPressAvailable = true,
                longPressAvailable = true,
                upDownAvailable = true,
                imageSupported = true,
                textSupported = true
              }
            }
          }
        }
      }
    }
  }
}

--[[ Local Functions ]]
local function setMenuLayoutTiles()
  local mobileSession = common.getMobileSession()
  local hmi = common.getHMIConnection()
  onSystemCapabilityUpdatedParams.appID = common.getHMIAppId()
  hmi:SendNotification("BasicCommunication.OnSystemCapabilityUpdated", onSystemCapabilityUpdatedParams)

  onSystemCapabilityUpdatedParams.appID = nil
  mobileSession:ExpectNotification("OnSystemCapabilityUpdated", onSystemCapabilityUpdatedParams)
  :Do(function()
    local cid = mobileSession:SendRPC("SetGlobalProperties", setGlobalPropertiesParams)

    hmi:ExpectRequest("UI.SetGlobalProperties", {})
    :Do(function(_, data)
      hmi:SendResponse(data.id, data.method, "SUCCESS", {})
      mobileSession:ExpectResponse(cid, successResponse)
    end)

    local cid2 = mobileSession:SendRPC("AddSubMenu", addSubMenuParams)

    hmi:ExpectRequest("UI.AddSubMenu", {})
    :Do(function(_, data)
      hmi:SendResponse(data.id, data.method, "SUCCESS", {})
      mobileSession:ExpectResponse(cid2, successResponse)
    end)
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Setting Menu Layout to supported TILES", setMenuLayoutTiles)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
