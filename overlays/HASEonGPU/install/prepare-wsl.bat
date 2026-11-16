@echo off
setlocal
if not defined OPT_PACKAGE_WSL_DISTRO set "OPT_PACKAGE_WSL_DISTRO=Ubuntu-24.04"
echo Run as Administrator on a new Windows PC. Reboot if requested, then open the distro and create a user.
wsl --install -d "%OPT_PACKAGE_WSL_DISTRO%"
exit /b %errorlevel%
