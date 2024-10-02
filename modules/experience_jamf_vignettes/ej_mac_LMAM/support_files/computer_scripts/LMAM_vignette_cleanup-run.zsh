#!/bin/zsh
# Ward 2024

# Cleans up and removes all artifacts of the LMAN vignette, resetting things back to how they were before the vignette was run

############################
######## VARIABLES #########
############################


# Get the currently logged-in user
loggedInUser=$( scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }' )


# Get the TJE_USERNAME from the TryJamf configuration
TJE_USERNAME=$(/usr/libexec/PlistBuddy -c 'print "USERNAME"' "/Library/Managed Preferences/com.tryjamf.device.plist")
/usr/bin/logger "LMAM-CleanUp: TJE_USERNAME: ${TJE_USERNAME}"

# Extract the first six digits
TJE_USER_ID=${TJE_USERNAME%@*}
echo "TJE User ID: ${TJE_USER_ID}"
/usr/bin/logger "LMAM-CleanUp: TJE User ID: ${TJE_USER_ID}"

# LaunchDaemon Paths
FIRST_RUN_LD_PATH="/Library/LaunchDaemons/com.TJE.LMAM-FIRST-RUN.plist"
ADMIN_MONITOR_LD_PATH="/Library/LaunchDaemons/com.TJE.LMAM-ADMIN-MONITOR.plist"
FAILSAFE_CLEANUP_LD_PATH="/Library/LaunchDaemons/com.TJE.LMAM-FAILSAFE-CLEANUP.plist"

# LaunchAgent Paths
LOGIN_TRIGGER_LA_PATH="/Library/LaunchAgents/com.TJE.LMAM-LOGIN-TRIGGER.plist"

/usr/bin/logger 'LMAM-CleanUp: Variables Set'

######################
######## RUN #########
######################


########################################################
# Reset authchanger - restores default macOS loginwindow
########################################################


if [ -f "/usr/local/bin/authchanger" ]; then
    sudo /usr/local/bin/authchanger -reset
    /usr/bin/logger 'LMAM-CleanUp: authchanger reset, default macOS loginwindow restored'
else
    /usr/bin/logger 'LMAM-CleanUp: authchanger not installed'
fi


#######################################
# Uninstall all Jamf Connect Components
#######################################

/usr/bin/logger 'LMAM-CleanUp: Starting Jamf Connect removals.. '


# Set the path variable
JC_UNINSTALL_PKG="/Library/.tje/LMAM/JamfConnectAssets/JamfConnectUninstaller.pkg"


# Check if the package exists
if [[ -f "$JC_UNINSTALL_PKG" ]]; then
    /usr/bin/logger 'LMAM-CleanUp: JC uninstaller exists'
    echo "Installing package: $JC_UNINSTALL_PKG"
    sudo installer -pkg "$JC_UNINSTALL_PKG" -target /
    /usr/bin/logger 'LMAM-CleanUp: running JC uninstaller pkg'
    if [[ $? -eq 0 ]]; then
        /usr/bin/logger 'LMAM-CleanUp: JC Uninstaller ran successfully'
    else
        /usr/bin/logger 'LMAM-CleanUp: Failed to run the JC Uninstaller package'
    fi
else
    /usr/bin/logger 'LMAM-CleanUp: JC Uninstaller package not found'
fi



#####################################################
# Unload & remove the LaunchDaemons & LMAM dir
# (string matching method combined with conditionals)
#####################################################

/usr/bin/logger 'LMAM-CleanUp: Starting LaunchD removals.. '

# Check for each LaunchDaemon, unload it, and remove the plist file if it exists

launchctl_list=$(launchctl list)

if [[ "$launchctl_list" == *"com.TJE.LMAM-FIRST-RUN"* ]]; then
    sudo launchctl bootout system "$FIRST_RUN_LD_PATH"
    /usr/bin/logger 'LMAM-CleanUp: Unloaded FIRST-RUN LaunchDaemon'
fi
if [ -f "$FIRST_RUN_LD_PATH" ]; then
    sudo rm -f "$FIRST_RUN_LD_PATH"
    /usr/bin/logger 'LMAM-CleanUp: Removed FIRST-RUN LaunchDaemon plist file'
fi

if [[ "$launchctl_list" == *"com.TJE.LMAM-LOGIN-TRIGGER"* ]]; then
    sudo launchctl bootout system "$LOGIN_TRIGGER_LA_PATH"
    /usr/bin/logger 'LMAM-CleanUp: Unloaded LOGIN-TRIGGER LaunchAgent'
fi
if [ -f "$LOGIN_TRIGGER_LA_PATH" ]; then
    sudo rm -f "$LOGIN_TRIGGER_LA_PATH"
    /usr/bin/logger 'LMAM-CleanUp: Removed LOGIN-TRIGGER LaunchAgent plist file'
fi

if [[ "$launchctl_list" == *"com.TJE.LMAM-ADMIN-MONITOR"* ]]; then
    sudo launchctl bootout system "$ADMIN_MONITOR_LD_PATH"
    /usr/bin/logger 'LMAM-CleanUp: Unloaded ADMIN-MONITOR LaunchDaemon'
fi
if [ -f "$ADMIN_MONITOR_LD_PATH" ]; then
    sudo rm -f "$ADMIN_MONITOR_LD_PATH"
    /usr/bin/logger 'LMAM-CleanUp: Removed ADMIN-MONITOR LaunchDaemon plist file'
fi

if [[ "$launchctl_list" == *"com.TJE.LMAM-FAILSAFE-CLEANUP"* ]]; then
    sudo launchctl bootout system "$FAILSAFE_CLEANUP_LD_PATH"
    /usr/bin/logger 'LMAM-CleanUp: Unloaded FAILSAFE-CLEANUP LaunchDaemon'
fi
if [ -f "$FAILSAFE_CLEANUP_LD_PATH" ]; then
    sudo rm -f "$FAILSAFE_CLEANUP_LD_PATH"
    /usr/bin/logger 'LMAM-CleanUp: Removed FAILSAFE-CLEANUP LaunchDaemon plist file'
fi

#####

# Check if the LMAM directory exists and remove it
if [ -d /Library/.tje/LMAM ]; then
    rm -rf /Library/.tje/LMAM
    /usr/bin/logger 'LMAM-CleanUp: Removed LMAM directory'
fi

##########################
# Log Out the Console User
##########################

/usr/bin/logger "LMAM-CleanUp: Starting ${TJE_USER_ID} logout.."

if [ -n "${loggedInUser}" ]; then
    /usr/bin/logger "LMAM-CleanUp: Logging out console user: ${loggedInUser}"
    
    # Attempt to log out the user
    sudo pkill -KILL -u "${loggedInUser}"
    /usr/bin/logger "LMAM-CleanUp: Sent kill signal to log out user: ${loggedInUser}"
    
    # Loop until the user is no longer logged in
    while true; do
        consoleUserStatus=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')
        
        # Log the current console user status
        /usr/bin/logger "LMAM-CleanUp: Checking console user status: ${consoleUserStatus}"
        
        if [ -z "${consoleUserStatus}" ] || [ "${consoleUserStatus}" != "${loggedInUser}" ]; then
            /usr/bin/logger "LMAM-CleanUp: User ${loggedInUser} has been successfully logged out."
            break
        else
            /usr/bin/logger "LMAM-CleanUp: User ${consoleUserStatus} is still logged in, waiting for logout to complete..."
            sudo killall loginwindow
            sleep 3
        fi
    done
else
    /usr/bin/logger "LMAM-CleanUp: No console user to log out."
fi


sleep 2


################################
# Delete the TJE_USER_ID Account
################################

/usr/bin/logger "LMAM-CleanUp: Starting ${TJE_USER_ID} account deletion..."

# Loop to ensure the user account and home directory are deleted
while dscl . -list /Users | grep -q "${TJE_USER_ID}"; do
    /usr/bin/logger "LMAM-CleanUp: User ${TJE_USER_ID} exists. Proceeding with deletion."
    
    # Delete the user account
    sudo dscl . -delete /Users/${TJE_USER_ID}
    /usr/bin/logger "LMAM-CleanUp: Deleted user record for ${TJE_USER_ID}."
    
    # Delete the home directory
    if [ -d "/Users/${TJE_USER_ID}" ]; then
        sudo rm -rf "/Users/${TJE_USER_ID}"
        /usr/bin/logger "LMAM-CleanUp: Deleted home directory for ${TJE_USER_ID}."
    fi
    
    # Small delay to ensure changes are processed
    sleep 2
done

/usr/bin/logger "LMAM-CleanUp: Successfully deleted User ${TJE_USER_ID} and home directory, if they existed."


###########################
# Final Clean up and reboot
###########################

/usr/bin/logger 'LMAM-CleanUp: Starting final clean up.. '

# refresh the login window so the TJE user account doesn't show up. This makes it so the original macOS user account is selected and in the foreground

sudo killall loginwindow
/usr/bin/logger "LMAM-CleanUp: loginwindow reset"

sleep 2

# Update the Mac's inventory in Jamf Pro. Updates the Extension Attribute that's looking for the LMAM Marker file. With the Marker gone, Mac falls out of scope of Jamf Connect configs - resetting the vignette
  
sudo /usr/local/bin/jamf recon
/usr/bin/logger "LMAM-CleanUp: Jamf Pro Inventory updated"


sleep 2

# Reboot the Mac
/usr/bin/logger "LMAM-CleanUp: Starting Mac reboot"
sudo shutdown -r now
/usr/bin/logger "LMAM-CleanUp: Mac rebooting now"

exit 0s