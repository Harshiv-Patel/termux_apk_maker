#!/data/data/com.termux/files/usr/bin/bash
#Apk Build script version v1.11+ beta in dev 
#===  primary directories & files ===
myDir="projects"
workspace="/sdcard/$myDir/term/"
bDir="bin/"
classesDir=$bDir"classes/"
apkDir=$bDir"apk/"
sourceDir="src/"
assetsDir="assets/"
resDir="res/"

#pkgDir 			#example "com/myapp/mypackage"
pkgDir="br/liveo/navigationliveo"
#application name	#example "myapp"
apname="NavigationLiveo"

#Project Home Dir	#example "myprojectname/"
#homeDir="/mnt/sdcard/$myDir/term/projects/android"
homeDir="/mnt/sdcard/$myDir/term/projects/android/OpenGLES/Navigation-Drawer-ActionBarCompat-master/Navigation-Drawer-ActionBarCompat-master/NavigationLiveo/"

logfile=$homeDir$bDir"log.txt"
mk_dirs ( ) {
	mkdir -p "$homeDir$classesDir"
	mkdir -p "$homeDir$apkDir"
	mkdir -p "$homeDir$assetsDir"
}

# apk signing Variables
keyfile=$homeDir$apkDir"debug.keystore"
psswd="sillylittlepasswd989889"
alias_name="alias"

#===  build files  ===
manifest="AndroidManifest.xml"
compiledRes="temp.apk"
apkName=
#======	other Variables =======
compiler="ecj"
#compiler="javac2"

dexflag=
dx_nostrict=0
installflag=0
jarlibs=$homeDir"libs/android-support-v4.jar:"$homeDir"libs/android-support-v7-appcompat.jar"
#arrays for program arguments and input files
aapt_args=( )
dxargs=( )
compilerargs=( )
sourcefiles=( )
classfiles=( )

#this forces the output to be suppressed
#do SILENT=[non-zero value] to disable redirection
redirect_cmd( ) {
     if [ -n "$SILENT" ]; then
        "$@" > /dev/null
    else
        "$@"
    fi
}
# make sure directories for generated binaries exist before building
mk_dirs ( ) {
	cd "$homeDir"
	mkdir -p "$classesDir"
	mkdir -p "$apkDir"
	mkdir -p "$assetsDir"
}

# generate a keystore
generate_keystore ( ) {
	if [[ -f "$keyfile" ]]; then
		echo "keystore file $keyfile already exists!"
	else
		keytool \
		-genkey \
		-v \
		-keystore "$keyfile" \
		-alias "$alias_name" \
		-storepass "$psswd" \
		-keypass "$psswd" \
		-keyalg RSA \
		-keysize 2048 \
		-validity 10000 \
		-dname "CN=Android Debug,O=Android,C=US"
	fi
}

sign_apk ( ) {
generate_keystore

echo "$psswd" | apksigner \
	sign \
	--ks "$keyfile" \
	"$compiledRes" 
}

# WARNING : do not change line numbers of above files, they're hard coded
# TODO : in v1.12 onwards, homeDir includes absolute path,
# so do not include $workspace Variable when referring to $homeDir
#function to Install the apk
install_apk ( ) {
#Only works if APK is on the sdcard
#	make sure that argument of '-d' option points to 
#	correct abstract path of apk, otherwise packageInstaller 
#	will give parsing errors
am start \
  --user 0 \
  -a android.intent.action.VIEW \
  -t application/vnd.android.package-archive \
  -d content://$homeDir$apkDir$apname"-signed.apk"
}

show_help ( ) {
yb="\033[37;44m" #colored title
nc="\033[0m"
echo -e "${yb} android application package builder                        ${nc}"
echo "Usage: maker_android.sh [Options]"
echo "Options:"
echo -e "\t -a \t enable Verbose output in aapt"
echo -e "\t -d \t enable Verbose output in dx"
echo -e "\t -j \t enable Verbose output in $compiler"
echo -e "\t -v \t enable Verbose output in all of above"
echo -e "\t -n \t enable '--no-strict' option in dx"
echo
echo -e "\t -i \t Install apk upon successfull build (via am)"
echo -e "\t -I \t install exiting apk from 'bin/apk' dir"
}

#process command line args if number of args is nonzero
if [ $# -ne 0 ]
then
	while getopts "adhiIjnrv" option
	do
		case $option in
			a) aapt_args+=( -v ) ;;
			d) dxargs+=( --verbose ) ;;
			i) installflag=1 ;;
			I) installflag=2 ;;
			j) compilerargs+=( -verbose ) ;;
			n) dx_nostrict=1 ;;
			v) 	aapt_args+=( -v )
				compilerargs+=( -verbose )
				dxargs+=( --verbose ) ;;
			*) show_help && exit ;;
		esac
	done
fi
#if Only Installation is required, install_apk and exit
(( $installflag == 2 )) && install_apk && exit 0
mk_dirs
#build process starts here : get the R.java file path
Rfile=$sourceDir$pkgDir"R.java"
#cd into the home dir - this way it works when run from inside vim or any other folder
cd $homeDir
#	===== Clean up older build files=====
rm -rf $classesDir $apkDir/*.apk $apkDir/*.dex
#Rmove the R.java file as will be created by aapt
[[ -f $Rfile ]] && rm $Rfile
# Remove previous compiler log file
[[ -f $logfile ]] && rm $logfile

#create the needed directories
mkdir -p $classesDir
#setup aapt arguments
aapt_args+=( -f )
aapt_args+=( -u )
aapt_args+=( -A $assetsDir )
aapt_args+=( -M $manifest )
aapt_args+=( -F $apkDir$compiledRes )
aapt_args+=( -S $resDir )
aapt_args+=( -J $sourceDir$pkgDir )
#unused#-I $coreAndroidjar \
#Now use aapt p[ackage] command
aapt p "${aapt_args[@]}"
#go to src dir for compilation
cd $sourceDir
#setup compiler arguments
compilerargs+=( -d ../bin/classes/ )
#ecj will require location of android.jar per API lavel
#compilerargs+=( -bootclasspath /data/data/com.termux/files/usr/bin/android.jar )
compilerargs+=( -bootclasspath ~/storage/external-1/android_v2.3.3.jar )
#compilerargs+=( -warn:none )
#add any jarlib if exists
[[ ! -z $jarlibs ]] && \
compilerargs+=( -classpath "$jarlibs" )

sourcefiles+=( `find . -name '[A-Za-z0-9]*.java' -type f` )
#errstr=""
#a pattern to detect compiler errors
pattern='.java\:[0-9]*\: '
#call compiler compiler and redirect its output to a log file.
#display error info on screen
$compiler "${compilerargs[@]}" "${sourcefiles[@]}" \
	2>&1 | tee ../logs.txt | \
	grep -e 'error' -e 'ERROR ' -e $pattern
#check for any compilation errors written in log file
errstr=$( cat ../logs.txt | grep -e 'error' -e 'ERROR' -e $pattern )
#echo -e "erratr: "$errstr
#if there are any errors, stop building and exit
[[ ! -z "${errstr// }" ]] && exit

#on successfull compilation, go to compiled java classes
cd ../$classesDir
#setup dx arguments
#find any classfiles and dirs(expected to be java package stucture)
num_dirs=0
num_dirs=`ls -l|grep ^d|wc -l`	#matches number of dirs

(( $num_dirs > 0 )) && \
	classfiles+=( 
	`find . -maxdepth 1 -type d|cut -d$'\n' -f 2-` ) ||
	classfiles+=( `find . -type f -name '*.class'` )
#set up dx arguments
	dxargs+=( --dex )
	dxargs+=( --output=../apk/"classes.dex" )
	(( dx_nostrict == 0 )) && dxargs+=( --no-strict )
#in case of any external jar libs:
#dx requires space as delimeter, so replace ':' with ' '
	[[ ! -z $jarlibs ]] && classfiles+=( ${jarlibs//:/ } )
#call it with redirect_cmd to suppress usual 
# "processing xyz class" output
redirect_cmd dx "${dxargs[@]}" "${classfiles[@]}"
#Back out
cd $homeDir$apkDir
#we use aapt add option
aapt add \
		-f $compiledRes classes.dex
#And now sign it
apkName="$apname-signed.apk"
#for Android-5 this works, but not on Android-11
#apksigner \
#		-p "bw3aw3abw3aw3a3829rsa" \
#		customAlias \
#		$compiledRes \
#		$apkName

#call signing function
sign_apk && cp "$compiledRes" "$apkName" || echo "signing failed, darn you signer!"
#Install app if asked or exit
(( $installflag == 1 )) && install_apk || exit 0
