---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0207-rpc-message-protection.md

-- Description:
-- Verify the value for `requireEncryption` in OnPermissionsChange at top and functional group levels after
-- app registration

-- Precondition:
-- 1) PT contains data for encryption_required parameters for app and function_group (Base-4)
-- In case:
-- 1) App registered
-- SDL does:
-- 1) send BasicCommunication.OnAppRegistered to HMI
-- 2) send OnPermissionsChange to mobile app with appropriate values of encryption_required parameters
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Security/RPCMessageProtection/common')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local states = {
  [1] = { app = true,  fg = true  },
  [2] = { app = true,  fg = false },
  [3] = { app = true,  fg = nil   },
  [4] = { app = false, fg = true  },
  [5] = { app = false, fg = false },
  [6] = { app = false, fg = nil   },
  [7] = { app = nil,   fg = true  },
  [8] = { app = nil,   fg = false },
  [9] = { app = nil,   fg = nil   }
}

local rpcConfig = {
  FG1 = {
    isEncFlagDefined = false,
    rpcs = { "AddCommand" }
  },
  FG2 = {
    isEncFlagDefined = true,
    rpcs = { "OnPermissionsChange" }
  }
}

--[[ Local Functions ]]
local function registerApp(pAppNew, pFGNew, pTC)
  common.getMobileSession():StartService(7)
  :Do(function()
      local cid = common.getMobileSession():SendRPC("RegisterAppInterface", common.getConfigAppParams())
      common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered")
      common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          common.getMobileSession():ExpectNotification("OnPermissionsChange")
          :ValidIf(function(e, data)
              if e.occurences == 1 then
                local expApp, expFG = common.getExp(pAppNew, pFGNew)
                return common.checkOnPermissionsChange(rpcConfig, expApp, expFG, data.payload, pTC)
              end
              return true
            end)
        end)
    end)
end

--[[ Scenario ]]
for n, tc in common.spairs(states) do
  runner.Title("TC[" .. string.format("%03d", n) .. "/".. string.format("%03d", #states) .. "] set "
    .. "(App:" .. tostring(tc.app) .. ",FG0:" .. tostring(tc.fg) .. ")")
  runner.Title("Preconditions")
  runner.Step("Clean environment", common.preconditions)
  runner.Step("Preloaded update", common.updatePreloadedPTSpecific,
    { rpcConfig, tc.app, { FG2 = tc.fg } })
  runner.Step("Start SDL, init HMI", common.start)

  runner.Title("Test")
  runner.Step("Register App", registerApp, { tc.app, tc.fg, n })

  runner.Title("Postconditions")
  runner.Step("Clean sessions", common.cleanSessions)
  runner.Step("Stop SDL, restore SDL settings", common.postconditions)
end

runner.Step("Print failed TCs", common.printFailedTCs)
