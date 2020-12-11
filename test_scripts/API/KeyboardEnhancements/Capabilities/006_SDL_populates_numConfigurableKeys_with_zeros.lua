----------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0238-Keyboard-Enhancements.md
----------------------------------------------------------------------------------------------------
-- Description: Check SDL populates with zeroes 'numConfigurableKeys' parameter of 'KeyboardCapabilities'
-- for 'supportedKeyboardLayouts' in case if HMI has not provided this information
--
-- Steps:
-- 1. App is registered
-- 2. HMI provides 'KeyboardCapabilities' with 'supportedKeyboardLayouts', but without information about
-- 'numConfigurableKeys' within 'OnSystemCapabilityUpdated' notification
-- 3. App requests 'DISPLAYS' system capabilities through 'GetSystemCapability'
-- SDL does:
--  - Provide 'KeyboardCapabilities' to App with 'numConfigurableKeys' set to zero
----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/KeyboardEnhancements/common')

--[[ Local Variables ]]
local tcs = {
  [01] = {
    src = {
      supportedKeyboardLayouts = { "QWERTY" },
      configurableKeys = nil
    },
    trg = {
      supportedKeyboardLayouts = { "QWERTY" },
      configurableKeys = {
        { keyboardLayout = "QWERTY", numConfigurableKeys = 0 }
      }
    }
  },
  [02] = {
    src = {
      supportedKeyboardLayouts = { "QWERTY", "NUMERIC" },
      configurableKeys = {
        { keyboardLayout = "QWERTY", numConfigurableKeys = 1 }
      }
    },
    trg = {
      supportedKeyboardLayouts = { "QWERTY", "NUMERIC" },
      configurableKeys = {
        { keyboardLayout = "QWERTY", numConfigurableKeys = 1 },
        { keyboardLayout = "NUMERIC", numConfigurableKeys = 0 }
      }
    }
  },
  [03] = {
    src = {
      supportedKeyboardLayouts = nil,
      configurableKeys = {
        { keyboardLayout = "QWERTY", numConfigurableKeys = 2 }
      }
    },
    trg = {
      supportedKeyboardLayouts = nil,
      configurableKeys = {
        { keyboardLayout = "QWERTY", numConfigurableKeys = 2 }
      }
    }
  },
  [04] = {
    src = {
      supportedKeyboardLayouts = { "QWERTY" },
      configurableKeys = {
        { keyboardLayout = "NUMERIC", numConfigurableKeys = 2 }
      }
    },
    trg = {
      supportedKeyboardLayouts = { "QWERTY" },
      configurableKeys = {
        { keyboardLayout = "QWERTY", numConfigurableKeys = 0 }
      }
    }
  },
}

--[[ Local Functions ]]
local function getDispCaps(pData)
  local dispCaps = common.getDispCaps()
  dispCaps.systemCapability.displayCapabilities[1].windowCapabilities[1].keyboardCapabilities = pData
  return dispCaps
end

local function sendOnSCU(pSrc, pExp)
  local dataFromHMI = common.cloneTable(pSrc)
  dataFromHMI.appID = common.getHMIAppId()
  common.getHMIConnection():SendNotification("BasicCommunication.OnSystemCapabilityUpdated", dataFromHMI)
  common.getMobileSession():ExpectNotification("OnSystemCapabilityUpdated", pExp)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)

common.Title("Test")
for n, tc in common.spairs(tcs) do
  common.Title("TC[" .. string.format("%03d", n) .. "]")
  local srcData = getDispCaps(tc.src)
  local expData = getDispCaps(tc.trg)
  common.Step("HMI sends OnSCU", sendOnSCU, { srcData, expData })
  common.Step("App sends GetSC", common.sendGetSC, { expData, common.success })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
