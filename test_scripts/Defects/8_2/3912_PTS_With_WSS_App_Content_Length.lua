---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3912
---------------------------------------------------------------------------------------------------
-- Description: Validates the content length of a PT snapshot which contains a cloud app entry
-- (including a certificate with newline strings)
--
-- Preconditions:
-- 1) WSS cloud app entry (with certificate) is added to the preloaded policy table
-- 2) SDL, HMI, Mobile session are started
-- 3) Mobile app is registered
--
-- Steps:
-- 1) HMI sends a PROPRIETARY OnSystemRequest
-- SDL does:
--  - Forward the OnSystemRequest to the mobile app with HTTP Headers
-- 2) Validate the Content-Length sent in the HTTP Headers using the HTTP request body
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")
local utils = require('user_modules/utils')
local json = require("modules/json")
local color = require("user_modules/consts").color

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "PROPRIETARY", "EXTERNAL_PROPRIETARY" } } }

--[[ Local Functions ]]
local function calculateContentLength(content)
  local contentLength = #content
  local backslash = string.byte("\\")
  local newline = string.byte("\n")
  for idx = 1, #content do
    if (content:byte(idx) == backslash) or (content:byte(idx) == newline)  then
      -- Adjust content length for content requiring escape characters
        contentLength = contentLength - 1
    end
  end
  return contentLength
end

local function updatePreloadedPT()
  local pt = common.sdl.getPreloadedPT()
  local appId = "cloudApp1"
  pt.policy_table.app_policies[appId] = utils.cloneTable(pt.policy_table.app_policies.default)
  pt.policy_table.app_policies[appId].groups = { "Base-4", "CloudAppStore" }
  pt.policy_table.app_policies[appId].nicknames = { "Cloud App 1" }
  pt.policy_table.app_policies[appId].hybrid_app_preference = "CLOUD"
  pt.policy_table.app_policies[appId].endpoint = "wss://127.0.0.1:4355"
  pt.policy_table.app_policies[appId].cloud_transport_type = "WSS"
  pt.policy_table.app_policies[appId].auth_token = "default auth token"
  pt.policy_table.app_policies[appId].enabled = true
  pt.policy_table.app_policies[appId].certificate = "-----BEGIN CERTIFICATE-----\nMIIDDzCCAfegAwIBAgIUeLhIGUGdeU4KxJ0UCZ3h5pPtat8wDQYJKoZIhvcNAQEL\nBQAwFzEVMBMGA1UEAwwMMTkyLjE2OC4xLjM0MB4XDTIyMDMxNjE4NTcxOFoXDTIz\nMDMxNjE4NTcxOFowFzEVMBMGA1UEAwwMMTkyLjE2OC4xLjM0MIIBIjANBgkqhkiG\n9w0BAQEFAAOCAQ8AMIIBCgKCAQEAntr/sMoG/BlrdzzhzVw/Pq528HWLRmguNYQe\nfPCqYsL00Uo0faNKsKEiOfbQHKkJGkPteFK+xgNCJA+w3sePgTkMwsyhKNgk2x+R\nI+Aua4hrcq5jaUR+EZ1wZlIS7UIz/y4VVDpiJWq+PfsofAYUvkS3xwOmJIYqnYT2\nTR5NbYW5FugcbH96RymRQ0iI97muijAYEbeQ2VW3f3p8s13Z/onByzcfY3/2LTeo\nZYGNfyLJVunWqzMraw4EwhzoodAjddGngZUwGx/QTAMkL87DGZySCgjvS1CXCpGD\nihzKWVy8L3vCYKA2V+Hjoocm2SiyZp1PQwjNobuErC68B68srQIDAQABo1MwUTAd\nBgNVHQ4EFgQUk5pq1IFzrDGaWhnffA1XOXIDtDQwHwYDVR0jBBgwFoAUk5pq1IFz\nrDGaWhnffA1XOXIDtDQwDwYDVR0TAQH/BAUwAwEB/zANBgkqhkiG9w0BAQsFAAOC\nAQEAWNqn/RVZ28kFRCcxQns+stzx6tJiOZs+ILDieXHp1j9xRLJcWNkoOOjeE1eW\nNWTopUzlN7JqRQbvBADM3girQqT3ed8L79C5U02OKeav7Jf7bxV0D/RMVk8pv5rC\nTPnRKdjsJW23P+bSxXPmRkHMIHgwfDxhPQjoCX0PWWjpuf49AXxLJ1U7hE16sQ/1\n03C+tN1hg5dbILinRRyjQ/p8O53/8m62NeFhoT7HomQ7iGPYPERSTcZi9wMkcMjk\n9JYZDyYGkfeIo809Llf94bMLZcTLQ3kGDahNdNwZMY0Zj80c2jV3F0mXXVVdoVBk\nENaXPUOx1QscBAWW1MlOqBz8Yg==\n-----END CERTIFICATE-----\n"  

  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = common.json.null
  common.sdl.setPreloadedPT(pt)
end


local function validPTSContentLength()
    local ptuFileName = os.tmpname()
    local requestId = common.getHMIConnection():SendRequest("SDL.GetPolicyConfigurationData",
        { policyType = "module_config", property = "endpoints" })
    common.getHMIConnection():ExpectResponse(requestId)    
    common.getHMIConnection():SendNotification("BasicCommunication.OnSystemRequest",
        { requestType = "PROPRIETARY", fileName = common.sdl.getPTSFilePath() })
    common.getMobileSession():ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
        :ValidIf(function(_, d)
            local httpRequest = json.decode(d.binaryData).HTTPRequest
            local expectedContentLength = calculateContentLength(httpRequest.body)
            local actualContentLength = httpRequest.headers["Content-Length"]
            if expectedContentLength ~= actualContentLength then
                utils.cprint(color.red, "Content length validation failed. Expected: "..expectedContentLength..", actual: "..actualContentLength)
                return false
            end
            return true
        end)    
end

--[[ Test ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)

runner.Title("Test")
runner.Step("Validate PTS Content-Length", validPTSContentLength)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
