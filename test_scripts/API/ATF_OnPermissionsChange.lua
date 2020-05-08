--Note: For now please use ATF version "atf-2.1.3-r1" for running this script because ATF2.2 cannot compare 2 array data table (OnPermissionsChange data on mobile app)
--------------------------------------------------------------
Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')

local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
require('user_modules/AppTypes')

--List all application's permissions for checking on mobile app
local arrayRegisterNewApp = {
							permissionItem =
							{
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									  },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "ChangeRegistration"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "DeleteFile"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "EncodedSyncPData"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "ListFiles"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnAppInterfaceUnregistered"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnEncodedSyncPData"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnHMIStatus"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnHashChange"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnLanguageChange"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnPermissionsChange"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnSystemRequest"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "PutFile"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "RegisterAppInterface"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "ResetGlobalProperties"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "SetAppIcon"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "SetDisplayLayout"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "SetGlobalProperties"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "SystemRequest"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "UnregisterAppInterface"
								  }
							}
			}
local arrayUpdatePolicyAddGroup = {
							permissionItem =
							{
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									  },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "AddCommand"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "AddSubMenu"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "FULL", "LIMITED" }
									 },
									 rpcName = "Alert"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "AlertManeuver"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "ChangeRegistration"
								  },
								  {
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "CreateInteractionChoiceSet"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "DeleteCommand"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "DeleteFile"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "DeleteInteractionChoiceSet"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "DeleteSubMenu"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "DiagnosticMessage"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "EncodedSyncPData"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "EndAudioPassThru"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "GenericResponse"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "GetDTCs"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "ListFiles"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnAppInterfaceUnregistered"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnAudioPassThru"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnButtonEvent"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									  },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnButtonPress"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnCommand"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnDriverDistraction"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnEncodedSyncPData"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnHMIStatus"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnHashChange"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnLanguageChange"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnPermissionsChange"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnSystemRequest"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "PerformAudioPassThru"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "PerformInteraction"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "PutFile"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "ReadDID"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "RegisterAppInterface"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "ResetGlobalProperties"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "FULL" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "ScrollableMessage"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "SetAppIcon"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "SetDisplayLayout"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "SetGlobalProperties"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "SetMediaClockTimer"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "Show"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "ShowConstantTBT"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "FULL" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "Slider"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "Speak"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "SubscribeButton"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "SystemRequest"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "UnregisterAppInterface"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "UnsubscribeButton"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "UpdateTurnList"
								  }
							}
			}
local arrayUpdatePolicyRemoveGroup = {
							permissionItem =
							{
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									  },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "AddCommand"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "AddSubMenu"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "FULL", "LIMITED" }
									 },
									 rpcName = "Alert"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "ChangeRegistration"
								  },
								  {
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "CreateInteractionChoiceSet"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "DeleteCommand"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "DeleteFile"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "DeleteInteractionChoiceSet"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "DeleteSubMenu"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = { "BACKGROUND", "FULL", "LIMITED" },
										allowed = {}
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "DiagnosticMessage"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "EncodedSyncPData"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "EndAudioPassThru"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "GenericResponse"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = { "BACKGROUND", "FULL", "LIMITED" },
										allowed = {}
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "GetDTCs"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "ListFiles"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnAppInterfaceUnregistered"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnAudioPassThru"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnButtonEvent"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									  },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnButtonPress"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnCommand"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnDriverDistraction"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnEncodedSyncPData"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnHMIStatus"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnHashChange"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnLanguageChange"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnPermissionsChange"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnSystemRequest"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "PerformAudioPassThru"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "PerformInteraction"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "PutFile"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = { "BACKGROUND", "FULL", "LIMITED" },
										allowed = {}
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "ReadDID"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "RegisterAppInterface"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "ResetGlobalProperties"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "FULL" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "ScrollableMessage"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "SetAppIcon"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "SetDisplayLayout"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "SetGlobalProperties"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "SetMediaClockTimer"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "Show"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "FULL" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "Slider"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "Speak"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "SubscribeButton"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "SystemRequest"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "UnregisterAppInterface"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "UnsubscribeButton"
								  }
							}
			}
local arrayUserConsentChange = {
							permissionItem =
							{
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									  },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "AddCommand"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "AddSubMenu"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "FULL", "LIMITED" }
									 },
									 rpcName = "Alert"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "ChangeRegistration"
								  },
								  {
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "CreateInteractionChoiceSet"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "DeleteCommand"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "DeleteFile"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "DeleteInteractionChoiceSet"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "DeleteSubMenu"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "EncodedSyncPData"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "EndAudioPassThru"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "GenericResponse"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = { "BACKGROUND", "FULL", "LIMITED" },
										allowed = {}
									 },
									 parameterPermissions = {
										userDisallowed = { "accPedalPosition", "beltStatus", "driverBraking", "myKey", "prndl", "rpm", "steeringWheelAngle"},
										allowed = {}
									 },
									 rpcName = "GetVehicleData"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "ListFiles"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnAppInterfaceUnregistered"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnAudioPassThru"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnButtonEvent"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									  },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnButtonPress"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnCommand"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnDriverDistraction"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnEncodedSyncPData"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnHMIStatus"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnHashChange"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnLanguageChange"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnPermissionsChange"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "OnSystemRequest"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = { "BACKGROUND", "FULL", "LIMITED" },
										allowed = {}
									 },
									 parameterPermissions = {
										userDisallowed = { "accPedalPosition", "beltStatus", "driverBraking", "myKey", "prndl", "rpm", "steeringWheelAngle"},
										allowed = {}
									 },
									 rpcName = "OnVehicleData"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "PerformAudioPassThru"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "PerformInteraction"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "PutFile"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "RegisterAppInterface"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "ResetGlobalProperties"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "FULL" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "ScrollableMessage"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "SetAppIcon"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "SetDisplayLayout"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "SetGlobalProperties"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "SetMediaClockTimer"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "Show"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "FULL" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "Slider"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "Speak"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "SubscribeButton"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = { "BACKGROUND", "FULL", "LIMITED" },
										allowed = {}
									 },
									 parameterPermissions = {
										userDisallowed = { "accPedalPosition", "beltStatus", "driverBraking", "myKey", "prndl", "rpm", "steeringWheelAngle"},
										allowed = {}
									 },
									 rpcName = "SubscribeVehicleData"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "SystemRequest"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "UnregisterAppInterface"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = {},
										allowed = { "BACKGROUND", "FULL", "LIMITED" }
									 },
									 parameterPermissions = {
										userDisallowed = {},
										allowed = {}
									 },
									 rpcName = "UnsubscribeButton"
								  },
								  {
									 hmiPermissions = {
										userDisallowed = { "BACKGROUND", "FULL", "LIMITED" },
										allowed = {}
									 },
									 parameterPermissions = {
										userDisallowed = { "accPedalPosition", "beltStatus", "driverBraking", "myKey", "prndl", "rpm", "steeringWheelAngle"},
										allowed = {}
									 },
									 rpcName = "UnsubscribeVehicleData"
								  }
							}
			}

--Use "atf-2.1.3-r1" for running this script because ATF2.2 cannot compare 2 array data tables (OnPermissionsChange data on mobile app)
---------------------------------------------------------------------------------------------------------------------
-----------------------I - SCRIPT TO COVERAGE onPermissionsChange NOTIFICATION---------------------------------------
-------SDL sends onPermissionsChange notification to mobile app when  application's permissions are changed----------
---------------------------------------------------------------------------------------------------------------------
--Requirement id in JAMA or JIRA:
	--APPLINK-19918: [OnPermissionsChange] send after successful registration
	--APPLINK-19922: [OnPermissionsChange] send after app's permissions change by Policy Table Update
	--APPLINK-19930: [OnPermissionsChange] send after user's consent change for app's permissions
---------------------------------------------------------------------------------------------------------------------

local function SequenceOnPemissionsChange()

----------------------------------------------------------------------------------------------------------------------
---------------------------------------------------Common function----------------------------------------------------
----------------------------------------------------------------------------------------------------------------------

	--Description: Using to activate app with specified session
	function Test:activateApp(applicationID, session)

		--hmi side: sending SDL.ActivateApp request
		local RequestId=self.hmiConnection:SendRequest("SDL.ActivateApp", { appID=applicationID})

		--hmi side: expect SDL.ActivateApp response
		EXPECT_HMIRESPONSE(RequestId)
			:Do(function(_,data)
				--In case when app is not allowed, it is needed to allow app
				if
					data.result.isSDLAllowed ~= true then

						--hmi side: sending SDL.GetUserFriendlyMessage request
						local RequestId=self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
											{language="EN-US", messageCodes={"DataConsent"}})

						--hmi side: expect SDL.GetUserFriendlyMessage response
						--TODO: Update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId,{result={code=0, method="SDL.GetUserFriendlyMessage"}})
						EXPECT_HMIRESPONSE(RequestId)
						:Do(function(_,data)

							--hmi side: send request SDL.OnAllowSDLFunctionality
							self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
								{allowed=true, source="GUI", device={id=config.deviceMAC, name="127.0.0.1"}})

							--hmi side: expect BasicCommunication.ActivateApp request
							EXPECT_HMICALL("BasicCommunication.ActivateApp")
							:Do(function(_,data)
								--hmi side: sending BasicCommunication.ActivateApp response
								self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
							end)
							:Times(AnyNumber())
						end)
				end
		 end)

		if (session == 1) then
			--mobile side: expect OnHMIStatus notification
			self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel="FULL", systemContext="MAIN"})
		else
			self.mobileSession1:ExpectNotification("OnHMIStatus", {hmiLevel="FULL", systemContext="MAIN"})
		end
	end

	-----------------------------------------------------------------------------------------------------------------

	--Description: Using to update policy and check OnPermissionChange with specified App
	function Test:updatePolicy_CheckOnPermissionChange_SpecifiedApp(policyFile, arrayOnPermissionsChange)

		--hmi side: sending SDL.GetURLS request
		local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })

		--hmi side: expect SDL.GetURLS response from HMI
		EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetURLS", urls = {{url = "http://policies.telematics.ford.com/api/policies"}}}})
		:Do(function(_,data)
			--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
			self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
				{
					appID = appId,
					fileName = "/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json",
					fileType="JSON",
					length=10000,
					offset=1000,
					policyAppID="default",
					requestType = "HTTP",
					timeout=500,
					url="http://policies.telematics.ford.com/api/policies"
				}
			)
			--mobile side: expect OnSystemRequest notification
			self.mobileSession1:ExpectNotification("OnSystemRequest", { requestType = "HTTP" })
			:Do(function(_,data)
				--mobile side: sending SystemRequest request
				local CorIdSystemRequest = self.mobileSession1:SendRPC("SystemRequest",
					{
						fileName = "PolicyTableUpdate",
						requestType = "HTTP"
					},
					"files/" .. policyFile)

				local systemRequestId
				--hmi side: expect SystemRequest request
				EXPECT_HMICALL("BasicCommunication.SystemRequest")
				:Do(function(_,data)
					systemRequestId = data.id
					--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
					self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
						{
							policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
						}
					)
					function to_run()
						--hmi side: sending SystemRequest response
						self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
					end

					RUN_AFTER(to_run, 500)
				end)

				--hmi side: expect SDL.OnStatusUpdate
				EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
				:ValidIf(function(exp,data)
					if
						exp.occurences == 1 and
						data.params.status == "UP_TO_DATE" then
							return true
					elseif
						exp.occurences == 1 and
						data.params.status == "UPDATING" then
							return true
					elseif
						exp.occurences == 2 and
						data.params.status == "UP_TO_DATE" then
							return true
					else
						if
							exp.occurences == 1 then
								print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in first occurrences status 'UP_TO_DATE' or 'UPDATING', got '" .. tostring(data.params.status) .. "' \27[0m")
						elseif exp.occurences == 2 then
								print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in second occurrences status 'UP_TO_DATE', got '" .. tostring(data.params.status) .. "' \27[0m")
						end
						return false
					end
				end)
				:Times(Between(1,2))

				--mobile side: expect SystemRequest response
				self.mobileSession1:ExpectResponse(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
				:Do(function(_,data)
					--hmi side: sending SDL.GetUserFriendlyMessage request to SDL
					local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"StatusUpToDate"}})

					--hmi side: expect SDL.GetUserFriendlyMessage response
					EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage", messages = {{line1 = "Up-To-Date", messageCode = "StatusUpToDate", textBody = "Up-To-Date"}}}})
					:Do(function(_,data)
					end)
				end)

			end)

			--mobile side: Expect OnPermissionsChange notification (specific policy)
			self.mobileSession1:ExpectNotification("OnPermissionsChange", arrayOnPermissionsChange )
			-- :Do(function(_,data) --TODO: USING FOR UPDATING SCRIPT AFTER FIXING APPLINK-20213 DEFECT
					-- commonFunctions:printTable(data.payload)
			-- end)

			--mobile side: Expect doesn't receive OnPermissionsChange notification (default policy)
			self.mobileSession:ExpectNotification("OnPermissionsChange", arrayOnPermissionsChange )
			:Times(0)

			commonTestCases:DelayedExp(5000)

		end)

	end

	-----------------------------------------------------------------------------------------------------------------

	--Description: Using to update policy and check OnPermissionChange with default App
	function Test:updatePolicy_CheckOnPermissionChange_DefaultApp(policyFile, arrayOnPermissionsChange)

		--hmi side: sending SDL.GetURLS request
		local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })

		--hmi side: expect SDL.GetURLS response from HMI
		EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetURLS", urls = {{url = "http://policies.telematics.ford.com/api/policies"}}}})
		:Do(function(_,data)
			--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
			self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
				{
					requestType = "PROPRIETARY",
					fileName = "filename"
				}
			)
			--mobile side: expect OnSystemRequest notification
			EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
			:Do(function(_,data)
				--mobile side: sending SystemRequest request
				local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
					{
						fileName = "PolicyTableUpdate",
						requestType = "PROPRIETARY"
					},
				"files/" .. policyFile)

				local systemRequestId
				--hmi side: expect SystemRequest request
				EXPECT_HMICALL("BasicCommunication.SystemRequest")
				:Do(function(_,data)
					systemRequestId = data.id
					--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
					self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
						{
							policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
						}
					)
					function to_run()
						--hmi side: sending SystemRequest response
						self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
					end

					RUN_AFTER(to_run, 500)
				end)

				--hmi side: expect SDL.OnStatusUpdate
				EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
				:ValidIf(function(exp,data)
					if
						exp.occurences == 1 and
						data.params.status == "UP_TO_DATE" then
							return true
					elseif
						exp.occurences == 1 and
						data.params.status == "UPDATING" then
							return true
					elseif
						exp.occurences == 2 and
						data.params.status == "UP_TO_DATE" then
							return true
					else
						if
							exp.occurences == 1 then
								print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in first occurrences status 'UP_TO_DATE' or 'UPDATING', got '" .. tostring(data.params.status) .. "' \27[0m")
						elseif exp.occurences == 2 then
								print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in second occurrences status 'UP_TO_DATE', got '" .. tostring(data.params.status) .. "' \27[0m")
						end
						return false
					end
				end)
				:Times(Between(1,2))

				--mobile side: expect SystemRequest response
				EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
				:Do(function(_,data)
					--hmi side: sending SDL.GetUserFriendlyMessage request to SDL
					local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"StatusUpToDate"}})

					--hmi side: expect SDL.GetUserFriendlyMessage response
					EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage", messages = {{line1 = "Up-To-Date", messageCode = "StatusUpToDate", textBody = "Up-To-Date"}}}})
					:Do(function(_,data)
					end)
				end)

			end)
			--mobile side: Expect OnPermissionsChange notification (specific policy)
			self.mobileSession1:ExpectNotification("OnPermissionsChange", arrayOnPermissionsChange )
			:Times(0)

			--mobile side: Expect OnPermissionsChange notification (default policy)
			self.mobileSession:ExpectNotification("OnPermissionsChange", arrayOnPermissionsChange )
			-- :Do(function(_,data) --TODO: USING FOR UPDATING SCRIPT AFTER FIXING APPLINK-20213 DEFECT
					-- commonFunctions:printTable(data.payload)
			-- end)


			commonTestCases:DelayedExp(5000)

		end)

	end

	-----------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------------
------------------------------------------------End Common function--------------------------------------------------
---------------------------------------------------------------------------------------------------------------------

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("-----------------------I - SCRIPT TO COVERAGE onPermissionsChange NOTIFICATION------------------------------")

	local function APPLINK_19918()

		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test cases APPLINK_19918: [OnPermissionsChange] send after successful registration")

		--Description: Create new session to register new application
		function Test:APPLINK_19918_Pre_CreationNewSession()
			-- Connected expectation
			self.mobileSession1 = mobile_session.MobileSession(
				self,
				self.mobileConnection)
			self.mobileSession1:StartService(7)
		end

		-------------------------------------------------------------------------------------------------------------

		-- Description: RegisterAppInterface and checking the OnPemissionChange notification
		function Test:APPLINK_19918_RegisterApp_CheckOnPermissionChange()

			config.application2.registerAppInterfaceParams.fullAppID = "0000002"
			--mobile side: sending request
			local CorIdRegister = self.mobileSession1:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)

			--hmi side: expect BasicCommunication.OnAppRegistered request
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
			{
				application =
				{
					appName = config.application2.registerAppInterfaceParams.appName
				}
			})
			:Do(function(_,data)
				appId = data.params.application.appID
				self.appId = appId
			end)

			--mobile side: expect notification
			self.mobileSession1:ExpectNotification("OnHMIStatus",
			{
				systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"
			})
			:Timeout(2000)

			--mobile side: Expect OnPermissionsChange notification
			self.mobileSession1:ExpectNotification("OnPermissionsChange", arrayRegisterNewApp )

		end

	end

	local function APPLINK_19922()

		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test cases APPLINK_19922: [OnPermissionsChange] send after app's permissions change by Policy Table Update")

		-------------------------------------------------------------------------------------------------------------

		-- Description: Activation specified app
		function Test:APPLINK_19922_ActivationSpecifiedApp()
			self:activateApp(appId, 2)
		end

		-------------------------------------------------------------------------------------------------------------

		--TODO debbug after resolving APPLINK-13101
		-- Description: UpdatePolicy and checking the OnPemissionChange notification
		function Test:APPLINK_19922_UPT_AddedGroup_CheckOnPermissionChange()

			self:updatePolicy_CheckOnPermissionChange_SpecifiedApp("PTU_OnPermissionChange_AddedGroup.json", arrayUpdatePolicyAddGroup)

		end

		-------------------------------------------------------------------------------------------------------------

		--TODO debbug after resolving APPLINK-13101
		-- Description: UpdatePolicy and checking the OnPemissionChange notification on specific policy
		function Test:APPLINK_19922_UPT_RemovedGroup_CheckOnPermissionChange()

			self:updatePolicy_CheckOnPermissionChange_SpecifiedApp("PTU_OnPermissionChange_RemovedGroup.json", arrayUpdatePolicyRemoveGroup)

		end

		-------------------------------------------------------------------------------------------------------------

		-- Description: Activation app
		function Test:APPLINK_19922_ActivationDefaultApp()

			local HMIappID=self.applications[config.application1.registerAppInterfaceParams.appName]
			self:activateApp(HMIappID, 1)

		end

		-------------------------------------------------------------------------------------------------------------

		--TODO debbug after resolving APPLINK-13101
		-- Description: UpdatePolicy and checking the OnPemissionChange notification on default policy option 1 (Register app with appId is not exist in PT)
		function Test:APPLINK_19922_UPT_AddedGroup_Default_CheckOnPermissionChange_Option1()

			self:updatePolicy_CheckOnPermissionChange_DefaultApp("PTU_OnPermissionChange_Default_AddedGroup.json", arrayUpdatePolicyAddGroup)

		end

		-------------------------------------------------------------------------------------------------------------

		--TODO debbug after resolving APPLINK-13101
		-- Description: UpdatePolicy and checking the OnPemissionChange notification on default policy option 1 (Register app with appId is not exist in PT)
		function Test:APPLINK_19922_UPT_RemovedGroup_Default_CheckOnPermissionChange_Option1()

			self:updatePolicy_CheckOnPermissionChange_DefaultApp("PTU_OnPermissionChange_Default_RemovedGroup.json", arrayUpdatePolicyRemoveGroup)

		end

		-------------------------------------------------------------------------------------------------------------

		--TODO debbug after resolving APPLINK-13101
		-- Description: UpdatePolicy and checking the OnPemissionChange notification on default policy option 2 (Register app with appId is exist in PT and assigned to default permission (example "0000002": "default",))
		function Test:APPLINK_19922_UPT_AddedGroup_Default_CheckOnPermissionChange_Option2()

			self:updatePolicy_CheckOnPermissionChange_DefaultApp("PTU_OnPermissionChange_Default_AddedGroup_1.json", arrayUpdatePolicyAddGroup)

		end

		-------------------------------------------------------------------------------------------------------------

		--TODO debbug after resolving APPLINK-13101
		-- Description: UpdatePolicy and checking the OnPemissionChange notification on default policy option 2 (Register app with appId is exist in PT and assigned to default permission (example "0000002": "default",))
		function Test:APPLINK_19922_UPT_RemovedGroup_Default_CheckOnPermissionChange_Option2()

			self:updatePolicy_CheckOnPermissionChange_DefaultApp("PTU_OnPermissionChange_Default_RemovedGroup_1.json", arrayUpdatePolicyRemoveGroup)

		end

		-------------------------------------------------------------------------------------------------------------

	end

	local function APPLINK_19930()

		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test cases APPLINK_19930: [OnPermissionsChange] send after user's consent change for app's permissions")

		-------------------------------------------------------------------------------------------------------------

		-- Description: Activation app
		function Test:APPLINK_19930_ActivationSpecifiedApp()
			self:activateApp(appId, 2)
		end

		-------------------------------------------------------------------------------------------------------------

		-- Description: UpdatePolicy and checking the OnPemissionChange notification on specific policy
		function Test:APPLINK_19930_UserConsentChange_CheckOnPermissionChange()

			self:updatePolicy_CheckOnPermissionChange_SpecifiedApp("PTU_OnPermissionChange_UserConsentGroup.json", arrayUserConsentChange)

		end

		-------------------------------------------------------------------------------------------------------------

		-- Description: Activation app
		function Test:APPLINK_19930_ActivationDefaultApp()
			local HMIappID=self.applications[config.application1.registerAppInterfaceParams.appName]
			self:activateApp(HMIappID, 1)
		end

		-------------------------------------------------------------------------------------------------------------

		-- Description: UpdatePolicy and checking the OnPemissionChange notification on default policy option 1 (Register app with appId is not exist in PT)
		function Test:APPLINK_19930_UserConsentChange_Default_CheckOnPermissionChange_Option1()

			self:updatePolicy_CheckOnPermissionChange_DefaultApp("PTU_OnPermissionChange_Default_UserConsentGroup.json", arrayUserConsentChange)

		end

		-------------------------------------------------------------------------------------------------------------

		--Description: Update Policy for precondition
		testCasesForPolicyTable:updatePolicy("files/ptu_general.json")

		-------------------------------------------------------------------------------------------------------------

		-- Description: UpdatePolicy and checking the OnPemissionChange notification on specific policy option 2 (Register app with appId is exist in PT and assigned to default permission (example "0000002": "default",))
		function Test:APPLINK_19930_UserConsentChange_Default_CheckOnPermissionChange_Option2()

			self:updatePolicy_CheckOnPermissionChange_DefaultApp("PTU_OnPermissionChange_Default_UserConsentGroup_1.json", arrayUserConsentChange)

		end

		-------------------------------------------------------------------------------------------------------------

	end

	--Main to execute test cases
	APPLINK_19918()
	APPLINK_19922()
	APPLINK_19930()

end

SequenceOnPemissionsChange()
