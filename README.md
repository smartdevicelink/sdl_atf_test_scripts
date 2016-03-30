# Automated Test Framework (ATF) scripts
This repository contains ATF scripts and data to run it.

## How To:

1. Setup SDL : https://github.com/smartdevicelink/sdl_atf/blob/develop/README.md
2. Setup ATF: https://github.com/smartdevicelink/sdl_core/blob/master/README.md
3. Clone  this repository :
```
git clone https://github.com/smartdevicelink/sdl_atf_test_scripts
```
4. Go to ATF repository and copy all files from sdl_atf_test_scripts to sdl_atf
```
cp -r ../sdl_atf_test_scripts/* ./ 
```
5.  Place actual HMI_API.xml, MOBILE_API.xml for SDL to 'ATF_build/data/' 
```
cp ../sdl_core/src/components/interfaces/HMI_API.xml ./data/
cp ../sdl_core/src/components/interfaces/MOBILE_API.xml ./data/
```
6. Run ATF with path to sdl binary dir and test script name as parameters
```
./start.sh --sdl_core=../sdl_core/build/bin  ./test_scripts/ATF_Speak.lua
```
