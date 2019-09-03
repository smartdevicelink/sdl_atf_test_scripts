---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0207-rpc-message-protection.md

-- Description:
-- Verify check on protection has higher priority than check on func. group consent
-- Note: Script is applicable for EXTERNAL_PROPRIETARY SDL policy mode

-- Preconditions:
-- 1) PT contains functional group (FG2) with
--   - some RPC
--   - 'encryption_required' = true
--   - 'user_consent_prompt' defined
-- 2) App has this functional group assigned
-- 3) App registered
--
-- Steps:
-- 1) App registered
-- 2) App try to send Unprotected RPC
-- SDL does respond to App with 'ENCRYPTION_NEEDED' result code
-- 3) App opens secure connection
-- 4) App tries to send Protected RPC
-- SDL does respond to App with 'DISALLOWED' result code
-- 5) User disallow functional group from HMI
-- 6) App tries to send Protected RPC
-- SDL does respond to App with 'USER_DISALLOWED' result code
-- 7) User allow functional group from HMI
-- 8) App tries to send Protected RPC
-- SDL does proceed with request successfully
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Security/RPCMessageProtection/common')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } }

--[[ Local Variables ]]
local fgId

--[[ Local Functions ]]
local function ptUpdate(pTbl)
  local pt = pTbl.policy_table
  pt.app_policies["default"].encryption_required = nil
  pt.functional_groupings["Base-4"].encryption_required = nil
  local hmiLevels = { "NONE", "BACKGROUND", "FULL", "LIMITED" }
  pt.functional_groupings["FG1"] = {
    encryption_required = nil,
    user_consent_prompt = nil,
    rpcs = {
      ["OnPermissionsChange"] = {
        hmi_levels = hmiLevels
      },
      ["OnHashChange"] = {
        hmi_levels = hmiLevels
      }
    }
  }
  pt.functional_groupings["FG2"] = {
    encryption_required = true,
    user_consent_prompt = "FG2Prompt",
    rpcs = {
      ["AddCommand"] = {
        hmi_levels = hmiLevels
      }
    }
  }
  pt.app_policies["spt"] = common.cloneTable(pt.app_policies["default"])
  pt.app_policies["spt"].encryption_required = true
  pt.app_policies["spt"].groups = { "FG1", "FG2" }
end

local function registerApp()
  common.getMobileSession():StartService(7)
  :Do(function()
      local cid = common.getMobileSession():SendRPC("RegisterAppInterface", common.getConfigAppParams())
      common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered")
      :Do(function(_, data)
          common.setHMIAppId(data.params.application.appID)
        end)
      common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          common.getMobileSession():ExpectNotification("OnPermissionsChange")
          :Do(function()
              local cid2 = common.getHMIConnection():SendRequest("SDL.GetListOfPermissions")
              common.getHMIConnection():ExpectResponse(cid2)
              :Do(function(_, data)
                for _, item in pairs(data.result.allowedFunctions) do
                  if item.name == 'FG2Prompt' then
                    fgId = item.id
                    common.cprint(35, "Id of func group:", tostring(fgId))
                  else
                    common.cprint(35, "Id was not found")
                  end
                end
              end)
            end)
        end)
    end)
end

local function unprotectedRpcInProtectedMode_ENCRYPTION_NEEDED()
  local cid = common.getMobileSession():SendRPC("AddCommand", common.getAddCommandParams(1))
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "ENCRYPTION_NEEDED" })
end

local function protectedRpcInProtectedMode_DISALLOWED()
  local cid = common.getMobileSession():SendEncryptedRPC("AddCommand", common.getAddCommandParams(1))
  common.getMobileSession():ExpectEncryptedResponse(cid, { success = false, resultCode = "DISALLOWED" })
end

local function consentFG(pIsAllowed)
   common.getHMIConnection():SendNotification("SDL.OnAppPermissionConsent", {
    appID = common.getHMIAppId(), source = "GUI",
    consentedFunctions = {{ name = "FG2Prompt", id = fgId, allowed = pIsAllowed }}
  })
  common.getMobileSession():ExpectNotification("OnPermissionsChange")
end

local function protectedRpcInProtectedMode_USER_DISALLOWED()
  local cid = common.getMobileSession():SendEncryptedRPC("AddCommand", common.getAddCommandParams(1))
  common.getMobileSession():ExpectEncryptedResponse(cid, { success = false, resultCode = "USER_DISALLOWED" })
end

local function protectedRpcInProtectedMode_SUCCESS()
  local cid = common.getMobileSession():SendEncryptedRPC("AddCommand", common.getAddCommandParams(1))
  common.getHMIConnection():ExpectRequest("UI.AddCommand")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  common.getMobileSession():ExpectEncryptedResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getMobileSession():ExpectNotification("OnHashChange")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Preloaded update", common.preloadedPTUpdate, { ptUpdate })
runner.Step("Start SDL, init HMI", common.start)

runner.Title("Test")
runner.Step("Register App", registerApp)
runner.Step("Unprotected RPC in protected mode ENCRYPTION_NEEDED", unprotectedRpcInProtectedMode_ENCRYPTION_NEEDED)
runner.Step("Start RPC Service protected", common.switchRPCServiceToProtected)
runner.Step("Protected RPC in protected mode DISALLOWED", protectedRpcInProtectedMode_DISALLOWED)
runner.Step("Remove consent for FG", consentFG, { false })
runner.Step("Protected RPC in protected mode USER_DISALLOWED", protectedRpcInProtectedMode_USER_DISALLOWED)
runner.Step("Add consent for FG", consentFG, { true })
runner.Step("Protected RPC in protected mode SUCCESS", protectedRpcInProtectedMode_SUCCESS)

runner.Title("Postconditions")
runner.Step("Clean sessions", common.cleanSessions)
runner.Step("Stop SDL, restore SDL settings", common.postconditions)
