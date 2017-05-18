# Git pre-commit hook for ATF scripts
This instruction contains the information on how to install pre-commit git hook

## Luacheck installation
* Clone Luacheck git repository 
```
git clone https://github.com/mpeterv/luacheck.git
```
* Go to root directory of luacheck repository
* Install luacheck to <path>
```
./install.lua <path>" 
```
 * _For example for install luacheck to **/opt/luacheck**, run_ 
```
./install.lua /opt/luacheck
```
* Luacheck git repository can be removed.
* Add path to <path>/bin to your PATH variable
```
gedit ~/.profile"
```
 * Add line below to the end of file 
```
PATH="$PATH:<path>\bin" 
```
 * _For example, if luacheck was installed to **/opt/luacheck**, add line:_ 
```
PATH="$PATH:/opt/luacheck/bin"
```
* Log out and log in back for apply changes

## Pre-commit git hook installation
* Go to tools directory of "sdl_atf_test_scripts" repository
* Insatall git hooks
```
python install_hooks.py 
```
##Done!
