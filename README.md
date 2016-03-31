# Automated Test Framework (ATF) scripts
This repository contains ATF scripts and data to run it.

## How To:

* [Setup SDL](https://github.com/smartdevicelink/sdl_core/blob/master/README.md). 
 * Later the SDL sources destination directory is referenced as `<sdl_core>`  
* [Setup ATF](https://github.com/smartdevicelink/sdl_atf/blob/develop/README.md)
 * Later the ATF sources destination directory is referenced as `<sdl_atf>` 
* Clone [sdl_atf_test_scripts](https://github.com/smartdevicelink/sdl_atf_test_scripts)
 * Later the atf test scripts destination directory is referenced as `<sdl_atf_test_scripts>`

``` git clone https://github.com/smartdevicelink/sdl_atf_test_scripts <sdl_atf_test_scripts>```
* Copy all files from `<sdl_atf_test_scripts>` to `<sdl_atf>` : 

``` cp -r <sdl_atf_test_scripts>/* <sdl_atf>/ ```
* Place actual HMI_API.xml, MOBILE_API.xml from `<sdl_core>/src/components/interfaces/` to `<sdl_atf>/data/` : 

```
cp <sdl_core>/src/components/interfaces/HMI_API.xml <sdl_atf>/data/
cp <sdl_core>/src/components/interfaces/MOBILE_API.xml <sdl_atf>/data/
```  
* Run ATF. 
  * Pass path to sdl binary dir with --sdl_core command line parameter
  * Pass path to test script as first command line paramater
```
cd <sdl_atf>/
./start.sh --sdl_core=<sdl_core>/build/bin  ./tests/ATF_Speak.lua
```

__Note, that path to SDL binary dir may be different__


Some test cases are failed due to known SDL issues. List of failed test cases avaliable in [KnownIssues.md](https://github.com/LuxoftAKutsan/sdl_atf_test_scripts/blob/master/KnownIssues.md)
