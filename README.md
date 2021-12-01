# termux_apk_maker
A simple bash script intented for termux to build very basic apk files for small projects
This expects a basic Android project directory structure to exist:
- ./assets is for app assets
- ./bin/apk is where temporary & final APK & signing files are put
- ./bin/classes is where compiled java class files are put
- ./res is where all resources are expected to be
- ./src is where java source files expected to be
- ./AndroiManifest.xml , as in in root directly, is where the manifest file should be, along with this script.

The paths need to be changed for each use-case, package name need to be as well, and apk name and project name as well.
The following build tools are expected to be installed:
- aapt
- ecj
- dx
- jdk-11 for signing
Currently tools like lint or zipalign aren't used as this is intended at small example / practice projects.
