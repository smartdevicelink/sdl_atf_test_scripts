
local CurrentAppType = config.application1.registerAppInterfaceParams.appHMIType
Test.appHMITypes = {DEFAULT = false, COMMUNICATION = false, MEDIA = false, MESSAGING = false, NAVIGATION = false, INFORMATION = false, SOCIAL = false, BACKGROUND_PROCESS = false, TESTING = false, SYSTEM = false}

for i=1,#CurrentAppType do
	Test.appHMITypes[CurrentAppType[i]] = true
end

Test.isMediaApplication = config.application1.registerAppInterfaceParams.isMediaApplication
NewTestSuiteNumber = 0 -- use as subfix of test case "NewTestSuite" to make different test case name.

-- Verify config.pathToSDL
findresultFirstCharacters = string.match (config.pathToSDL, '^%.%/')
if findresultFirstCharacters == "./" then
	local CurrentFolder = assert( io.popen( "pwd" , 'r'))
	local CurrentFolderPath = CurrentFolder:read( '*l' )

	PathUsingCurrentFolder = string.match (config.pathToSDL, '[^%.]+')

	config.pathToSDL = CurrentFolderPath .. PathUsingCurrentFolder

end

findresultLastCharacters = string.find (config.pathToSDL, '.$')
if string.sub(config.pathToSDL,findresultLastCharacters) ~= "/" then
	config.pathToSDL = config.pathToSDL..tostring("/")
end 



