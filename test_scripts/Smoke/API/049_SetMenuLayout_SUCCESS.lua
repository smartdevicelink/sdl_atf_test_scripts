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
local commonSmoke = require('test_scripts/Smoke/commonSmoke')

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
                characterSet = "TYPE2SET",
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
local function setMenuLayoutTiles(self)
  onSystemCapabilityUpdatedParams.appID = commonSmoke.getHMIAppId()
  self.hmiConnection:SendNotification("BasicCommunication.OnSystemCapabilityUpdated", onSystemCapabilityUpdatedParams)
  
  onSystemCapabilityUpdatedParams.appID = nil
  self.mobileSession1:ExpectNotification("OnSystemCapabilityUpdated", onSystemCapabilityUpdatedParams)

  local cid = self.mobileSession1:SendRPC("SetGlobalProperties", setGlobalPropertiesParams)
  
  EXPECT_HMICALL("UI.SetGlobalProperties", {})
  :Do(function(_, data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    self.mobileSession1:ExpectResponse(cid, successResponse)
  end)

  local cid2 = self.mobileSession1:SendRPC("AddSubMenu", addSubMenuParams)
  
  EXPECT_HMICALL("UI.AddSubMenu", {})
  :Do(function(_, data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    self.mobileSession1:ExpectResponse(cid2, successResponse)
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSmoke.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSmoke.start)
runner.Step("RAI", commonSmoke.registerApp)
runner.Step("Activate App", commonSmoke.activateApp)

runner.Title("Test")
runner.Step("Setting Menu Layout to supported TILES", setMenuLayoutTiles)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
