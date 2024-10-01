#!/bin/bash

# Set variables

# Get the last logged in user
lastLoggedInUser=`defaults read /Library/Preferences/com.apple.loginwindow lastUserName`

# Get Model Name of computer
modelName=`system_profiler SPHardwareDataType | grep "Model Identifier" | awk '{print $3}' | sed 's/[0-9]*//g' | tr -d ','`

# Get original name of computer
oldComputerName=`scutil --get ComputerName`

# Generate new computer name
computerName=$lastLoggedInUser-$modelName

# Set new computer name locally
scutil --set ComputerName $computerName

scutil --set HostName $computerName

scutil --set LocalHostName $computerName

# Set the computer name in Jamf to reflect what is set locally on the computer
/usr/local/bin/jamf setComputerName -name $computerName
/usr/local/bin/jamf recon

echo "Computer name has been changed from $oldcomputername to $computerName"

exit 0