#!/bin/zsh

:<<ABOUT_THIS_SCRIPT
-------------------------------------------------------------------------------

	Written by:William Smith
	Partner Program Manager
	Jamf
	bill@talkingmoose.net
	https://gist.github.com/talkingmoose/94882adb69403a24794f6b84d4ae9de5
	
	Originally posted: June 1, 2023

	Purpose: Downloads and installs the latest available Jamf Connect software
	for Mac directly on the client. This avoids having to manually download
	and store an up-to-date installer on a distribution server every month.
	
	Instructions: Optionally update the sha256Checksum value with a
	known SHA 256 string. Run the script with elevated privileges.
	If using Jamf Pro, consider replacing the sha256Checksum value
	with "$4", entering the checksum as script parameter in a policy.

	Except where otherwise noted, this work is licensed under
	http://creativecommons.org/licenses/by/4.0/

	"If you are going to fail, then fail gloriously."
	
-------------------------------------------------------------------------------
ABOUT_THIS_SCRIPT


# enter the SHA 256 checksum for the download file
# download the package and run '/usr/bin/shasum -a 256 /path/to/file.pkg'
# this will change with each version
# leave blank to to skip the checksum verification (less secure) or if using a $4 script parameter with Jamf Pro

sha256Checksum="" # e.g. "67b1e8e036c575782b1c9188dd48fa94d9eabcb81947c8632fd4acac7b01644b"

if [ "$4" != "" ] && [ "$sha256Checksum" = "" ]
then
	sha256Checksum=$4
fi

# functions
function logcomment()	{
	if [ $? = 0 ] ; then
		/bin/date "+%Y-%m-%d %H:%M:%S	$1" >> "$logFile"
	else
		/bin/date "+%Y-%m-%d %H:%M:%S	$2" >> "$logFile"
	fi
}

# path to this script
currentDirectory=$( /usr/bin/dirname "$0" )

# name of this script
currentScript=$( /usr/bin/basename -s .sh "$0" )

# create log file in same directory as script
logFile="/Library/Logs/$currentScript - $( /bin/date '+%y-%m-%d' ).log"

echo "Log file: $logFile"

# temporary file name for downloaded package
dmgFile="JamfConnect.dmg"
pkgFile="JamfConnect.pkg"

# this is the full download URL to the latest version of the product
downloadURL="https://files.jamfconnect.com/JamfConnect.dmg"

# create temporary working directory
echo "Creating working directory '$tempDirectory'"
workDirectory=$( /usr/bin/basename $0 )
tempDirectory=$( /usr/bin/mktemp -d "/private/tmp/$workDirectory.XXXXXX" )

# change directory to temporary working directory
echo "Changing directory to working directory '$tempDirectory'"
cd "$tempDirectory"

# download the installer package
echo "Downloading disk image $dmgFile"
/usr/bin/curl "$downloadURL" \
--location \
--silent \
--output "$dmgFile"

# checksum the download
downloadChecksum=$( /usr/bin/shasum -a 256 "$tempDirectory/$dmgFile" | /usr/bin/awk '{ print $1 }' )
echo "Checksum for downloaded disk image: $downloadChecksum"

# install the download if checksum validates
if [ "$sha256Checksum" = "$downloadChecksum" ] || [ "$sha256Checksum" = "" ]; then
	echo "Checksum verified. Installing software..."
	
	# mounting DMG
	logcomment "Mounting $dmgFile..."
	appVolume=$( yes | /usr/bin/hdiutil attach -nobrowse "$tempDirectory/$dmgFile" | /usr/bin/grep /Volumes | /usr/bin/sed -e 's/^.*\/Volumes\///g' )
	logcomment "Mounted $dmgFile." "Failed to mount $dmgFile."
	echo "$appVolume"
	
	# install software
	logcomment "Installing software..."
	/usr/sbin/installer -pkg "/Volumes/$appVolume/$pkgFile" -target /
	logcomment "Installed software." "Failed to install software."
	
	# unmount DMG
	logcomment "Unmounting $dmgFile..."
	/sbin/umount -f "/Volumes/$appVolume" # forcibly unmount
	logcomment "Unmounting $dmgFile." "Failed to unmount $dmgFile."
	
else
	echo "Checksum failed. Recalculate the SHA 256 checksum and try again. Or download may not be valid."
	exit 1
fi

# delete DMG
logcomment "Deleting DMG..."
/bin/rm -R "$tempDirectory"
logcomment "Deleted DMG." "Failed to delete DMG."

exit $exitCode