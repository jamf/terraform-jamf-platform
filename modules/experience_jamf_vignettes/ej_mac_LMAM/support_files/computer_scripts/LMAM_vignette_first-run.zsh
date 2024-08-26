#!/bin/zsh
# Ward
# 2024

##########################################################################################
##########################################################################################
##########################################################################################

# Local macOS Account Management (LMAM)
#
# This script is designed to be executed as a Jamf Pro Policy, serving as the initial step
# in the Local macOS Account Management (LMAM) Vignette workflow. The script performs the following tasks:
#
# 1. Creates working directories and marker files to signify the start of the LMAM Vignette.
# 2. Places and configures 4 local run scripts for subsequent steps in the LMAM vignette workflow.
# 3. Sets up and loads multiple LaunchDaemons to monitor for the presence of Jamf Connect configuration profiles, admin elevation, and control the timing and steps of the vignette.



############################
######## VARIABLES #########
############################

# Vignette Directory
LMAM_DIR="/Library/.tje/LMAM"

# LMAM Marker
LMAM_MARKER="/Library/.tje/LMAM/lmamRUN"

# Paths to local run scripts
STEP1_SCRIPT_PATH="/Library/.tje/LMAM/LMAM_vignette-local-step1-run.zsh"
STEP2_SCRIPT_PATH="/Library/.tje/LMAM/LMAM_vignette-local-step2-run.sh"
STEP3_SCRIPT_PATH="/Library/.tje/LMAM/LMAM_vignette-local-step3-run.zsh"
CLEANUP_SCRIPT_PATH="/Library/.tje/LMAM/LMAM_vignette-cleanup-run.zsh"
# LOAD_LAUNCH_AGENT_SCRIPT_PATH="/Library/.tje/LMAM/LMAM_vignette-LOAD_LAUNCH_AGENT_SCRIPT.zsh"

# LaunchDaemon Paths
FIRST_RUN_LD_PATH="/Library/LaunchDaemons/com.TJE.LMAM-FIRST-RUN.plist"
ADMIN_MONITOR_LD_PATH="/Library/LaunchDaemons/com.TJE.LMAM-ADMIN-MONITOR.plist"
FAILSAFE_CLEANUP_LD_PATH="/Library/LaunchDaemons/com.TJE.LMAM-FAILSAFE-CLEANUP.plist"

# LaunchAgent Paths
# LOGIN_TRIGGER_LA_PATH="/Library/LaunchAgents/com.TJE.LMAM-LOGIN-TRIGGER.plist"

# Get the TJE_USERNAME from the experience.jamfcloud custom TryJamf configuration. should result in the username for device record to leverage in vignettes. ie, ######@tryjamf.com was set as the User during enrollment, so we always know which account username to workwith throughout the vignettes
TJE_USERNAME=$(/usr/libexec/PlistBuddy -c 'print "USERNAME"' "/Library/Managed Preferences/com.tryjamf.device.plist")
echo "TJE_USERNAME: ${TJE_USERNAME}"

# Extract the first six digits so we have a value that is only the numbers portion of the tryjamf.com TJE_USERNAME
TJE_USER_ID=${TJE_USERNAME%@*}
echo "TJE User ID: ${TJE_USER_ID}"

# Define the path to Jamf Connect Menu Bar
JCMB="/Applications/Jamf Connect.app/Contents/MacOS/Jamf Connect"


######################
######## PER-RUN #########
######################


# Define the path to SwiftDialog
dialog="/usr/local/bin/dialog"

# Define the message and other parameters for the dialog


message="## What's about to happen?\n\n - Clicking ***Continue*** or ***Cancel*** on this notification will proceed accordingly\n\n 	- If continuing, 20 seconds of background configuration will occur. Nothing will appear on screen during this time\n\n 	- A **fullscreen** notification will appear with further details\n\n \n\n #### Please have your Experience Jamf credentials ready for next steps\n\n  	 ${TJE_USERNAME} & password displayed in Jamf Account"
button="Continue"


# Function to run the dialog
runDialog () {
    ${dialog} \
    --title "Local macOS Account Management" \
    --big \
    --ontop \
    --moveable \
    --position center \
    --icon 'SF=person.crop.circle.badge.clock.fill,colour=red' --iconsize 210 \
    --message "${message}" \
    --messagefont "size=18" \
    --button1text ${button} \
    --button2 \
    --hidedefaultkeyboardaction
}


runDialog
dialogExitCode=$?

# Check the exit code and act accordingly
if [ $dialogExitCode -eq 2 ]; then
    echo "User chose to exit the process. Exiting Vignette"
    exit 0
elif [ $dialogExitCode -eq 0 ]; then
    echo "User chose to continue. Proceeding with the Vignette"
    # Continue with the rest of the script...

fi


######################
######## RUN #########
######################

# Create the script directory if it does not exist
mkdir -p "$LMAM_DIR"

# Create LMAM marker file. Once recon occurs, Mac will fall into scope of LMAM Jamf Connect Configs. 
touch "$LMAM_MARKER"

touch "/Library/LaunchAgents/com.jamf.connect.plist"



# # Install Jamf Connect pkgs if not already installed
#     if [[ ! -f ${JCMB} ]]; then
#         /usr/local/bin/jamf policy -event @installJC
#     fi
#     
#     # Wait for Jamf Connect Menu Bar App to be installed
#     while [[ ! -f ${JCMB} ]]; do
#         sleep 2
#     done


####################################
# Create local run scripts (5 total)
####################################

####################
# Place STEP1_SCRIPT
####################

cat << EOF > "$STEP1_SCRIPT_PATH"
#!/bin/zsh

# Get the TJE_USERNAME from the plist
TJE_USERNAME=$(/usr/libexec/PlistBuddy -c 'print "USERNAME"' "/Library/Managed Preferences/com.tryjamf.device.plist")

# Get the currently logged-in user
loggedInUser=$( scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }' )

# Define the path to SwiftDialog
dialog="/usr/local/bin/dialog"

# Define the path to Jamf Connect Menu Bar
JCMB="/Applications/Jamf Connect.app/Contents/MacOS/Jamf Connect"

# Define the message and other parameters for the dialog
message="### What's Happening?\n\n - Custom login window and menu bar configurations are loaded\n\n - Demo Account creation and Privilege Elevation with Jamf Connect \n\n ### What's Next?\n\n - Use **\${TJE_USERNAME}** & password to authenticate next steps\n\n   -  Once finished, log back in to your current macOS account\n\n - Current macOS account:\n\n 		\${loggedInUser} | No changes will be made to this account\n\n - Click ***Log Out*** to continue"
button="Log Out"

# Ensure SwiftDialog is installed
if [[ ! -f \${dialog} ]]; then
    /usr/local/bin/jamf policy -event @dialog
fi


# Function to run the dialog
runDialog () {
    \${dialog} \\
    --title "Local macOS Account Management" \\
    --big \\
    --ontop \\
    --blurscreen \\
    --moveable \\
    --position center \\
    --icon 'SF=person.crop.circle.fill.badge.plus,colour=blue' --iconsize 210 \\
    --message \${message} \\
    --messagefont "size=18" \\
    --button1text \${button} \\
    --hidedefaultkeyboardaction \\
}


# Install Jamf Connect pkgs if not already installed
    if [[ ! -f \${JCMB} ]]; then
        /usr/local/bin/jamf policy -event @installJC
    fi
    
    # Wait for Jamf Connect Menu Bar App to be installed
    while [[ ! -f \${JCMB} ]]; do
        sleep 2
    done

# Run the dialog
runDialog
    
      # Force log out the user
    sudo pkill -KILL -u \${loggedInUser}
    sudo authchanger -reset -JamfConnect
    echo "User has been logged out."
    
    # Unload and remove the LaunchDaemon to prevent looping
    sudo launchctl bootout system "/Library/LaunchDaemons/com.TJE.LMAM-FIRST-RUN.plist"
	# sudo rm -f "/Library/LaunchDaemons/com.TJE.LMAM-FIRST-RUN.plist"
      

exit 0
EOF

####################
# Place STEP2_SCRIPT
####################

cat << EOF > "$STEP2_SCRIPT_PATH"
#!/bin/sh

# Get the TJE_USERNAME from the plist
TJE_USERNAME=$(/usr/libexec/PlistBuddy -c 'print "USERNAME"' "/Library/Managed Preferences/com.tryjamf.device.plist")


TJE_USER_ID=${TJE_USERNAME%@*}


# Define the path to SwiftDialog
dialog="/usr/local/bin/dialog"

# Define the message and other parameters for the dialog
info_link="https://www.jamf.com/products/jamf-connect/"
message="### What Happened?\n\n - Jamf Connect created a new macOS local account with standard privileges assoociated with your cloud directory user ☁️\n\n		Strong IdP MFA configurations more typical, removed for this demo\n\n  ### What's Next?\n\n - Need to do something that requires Admin rights? ‼️\n\n - Click the Jamf Connect Menu Bar App & Request temporary admin privileges\n\n - The ***${TJE_USER_ID}*** Mac account will automatically be deleted after a period of inactivity"
button="Explore Jamf Connect"


# Function to run the dialog
runDialog () {
    \${dialog} \\
    --title "Local macOS Account Management" \\
    --big \\
    --ontop \\
    --moveable \\
    --position bottom \\
    --icon 'SF=person.crop.circle.fill.badge.checkmark,colour=blue' --iconsize 210 \\
    --message "\${message}" \\
    --messagefont "size=18" \\
    --infobuttontext "More Info" \\
    --infobuttonaction \${info_link} \\
    --quitoninfo \\
    --button1text "\${button}" \\
    --hidedefaultkeyboardaction
}

# Open System Settings.app to the Users & Groups pane

open -b com.apple.systempreferences /System/Library/PreferencePanes/Accounts.prefPane

# Run the dialog
runDialog

sleep 2

# Quit System Settings so it's refreshed/correct when It re-opens again in the priv elevation step
osascript -e 'tell application "System Settings" to quit'

exit 0
EOF

####################
# Place STEP3_SCRIPT
####################

cat << EOF > "$STEP3_SCRIPT_PATH"
#!/bin/zsh


# Get the TJE_USERNAME from the plist
TJE_USERNAME=$(/usr/libexec/PlistBuddy -c 'print "USERNAME"' "/Library/Managed Preferences/com.tryjamf.device.plist")



# Define the cleanup script path
CLEANUP_SCRIPT_PATH="/Library/.tje/LMAM/LMAM_vignette-cleanup-run.zsh"

# Define the path to SwiftDialog
dialog="/usr/local/bin/dialog"

# Define the message and other parameters for the dialog
info_link="https://www.jamf.com/products/jamf-connect/"
message="### What Happened?\n\n - ***\${TJE_USERNAME}'s*** account privileges were temporarily elevated to Admin\n\n- 	**System Settings.app** shows user is elevated\n\n - For visibility to events while elevated, [Jamf Protect Telemetry](https://learn.jamf.com/en-US/bundle/jamf-protect-documentation/page/Telemetry.html) provides rich macOS auditing capabilities\n\n ### What's Next?\n\n - When ready, click ***Exit & Clean Up***\n\n - macOS account ***${TJE_USER_ID}*** will log off, be deleted & the Mac will ***reboot***\n\n - Log back in to your original account\n\n - If no selection is made ***Exit & Clean Up*** will proceed automatically"
button="Exit & Clean Up"


# Open System Settings.app to the Users & Groups pane

open -b com.apple.systempreferences /System/Library/PreferencePanes/Accounts.prefPane


# Ensure SwiftDialog is installed
if [[ ! -f \${dialog} ]]; then
    /usr/local/bin/jamf policy -event @dialog
fi

# Open System Settings.app to the Users & Groups pane

open -b com.apple.systempreferences /System/Library/PreferencePanes/Accounts.prefPane

# Function to run the dialog
runDialog () {
    \${dialog} \\
    --title "Local macOS Account Management" \\
    --big \\
    --ontop \\
    --moveable \\
    --position bottom \\
    --icon 'SF=person.crop.circle.badge.clock.fill,colour=green' --iconsize 210 \\
    --message \${message} \\
    --messagefont "size=18" \\
    --button1text \${button} \\
    --button1action \${button1_link} \\
    --hidedefaultkeyboardaction \\
}


runDialog

# Run cleanup
sudo /bin/zsh ${CLEANUP_SCRIPT_PATH} &


exit 0
EOF


######################
# Place CLEANUP_SCRIPT
######################


cat << EOF > "$CLEANUP_SCRIPT_PATH"
#!/bin/zsh

sudo /usr/local/bin/jamf policy -event @LMAM-CLEANUP &

exit 0
EOF

# ######################
# # Place LOAD_LAUNCH_AGENT_SCRIPT
# ######################
# 
# cat << EOF > "$LOAD_LAUNCH_AGENT_SCRIPT_PATH"
# #!/bin/zsh
# # LMAM_vignette-local-step2-run.zsh
# # loads the com.TJE.LMAM-LOGIN-TRIGGER LaunchAgent as the TJE user. JCL's ScriptPath runs this script after successful auth with JCL.
# 
# touch /tmp/Start_loggin-trigger
# 
# # Get the currently logged-in user
# loggedInUser=\$( scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print \$3 }' )
# 
# # Get the TJE_USERNAME from the TryJamf configuration
# TJE_USERNAME=\$(/usr/libexec/PlistBuddy -c 'print "USERNAME"' "/Library/Managed Preferences/com.tryjamf.device.plist")
# echo "TJE_USERNAME: \${TJE_USERNAME}"
# 
# # Extract the first six digits
# TJE_USER_ID=\${TJE_USERNAME%@*}
# echo "TJE User ID: \${TJE_USER_ID}"
# 
# touch /tmp/loggedInUser-\${loggedInUser}
# 
# # Get the UID of the TJE_USER_ID account
# TJE_USER_UID=\$(id -u "\${TJE_USER_ID}")
# 
# touch /tmp/UID-\${TJE_USER_UID}
# 
# # Load the LaunchAgent for TJE_USER_ID
# if [ -n "\${TJE_USER_UID}" ]; then
#     sudo -u "\${TJE_USER_ID}" "launchctl bootstrap gui/\${TJE_USER_UID} /Library/LaunchAgents/com.TJE.LMAM-LOGIN-TRIGGER.plist"
# fi
# 
# # Check if the LaunchAgent is loaded
# if launchctl list | grep -q "com.TJE.LMAM-LOGIN-TRIGGER"; then
#     touch /tmp/loaded
# fi
# 
# touch /tmp/End-loggin-trigger
# 
# exit 0
# EOF

########################################################################
# Set ownership and permissions for the scripts and make them executable
########################################################################

chmod 644 "$STEP1_SCRIPT_PATH"
chmod 755 "$STEP2_SCRIPT_PATH"
chmod 644 "$STEP3_SCRIPT_PATH"
chmod 644 "$CLEANUP_SCRIPT_PATH"
# chmod 644 "$LOAD_LAUNCH_AGENT_SCRIPT_PATH"

chmod +x "$STEP1_SCRIPT_PATH"
chmod +x "$STEP2_SCRIPT_PATH"
chmod +x "$STEP3_SCRIPT_PATH"
chmod +x "$CLEANUP_SCRIPT_PATH"
# chmod +x "$LOAD_LAUNCH_AGENT_SCRIPT_PATH"

# change ownership on the scripts
chown root:wheel "$STEP1_SCRIPT_PATH"
chown root:wheel "$STEP2_SCRIPT_PATH"
chown root:wheel "$STEP3_SCRIPT_PATH"
chown root:wheel "$CLEANUP_SCRIPT_PATH"
# chown root:wheel "$LOAD_LAUNCH_AGENT_SCRIPT_PATH"

######################
# Create LaunchDaemons
######################

# Create the First Run LaunchDaemon plist
# Runs STEP1_SCRIPT_PATH once the Jamf Connect Login configs are installed

cat << EOF > "$FIRST_RUN_LD_PATH"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.TJE.LMAM-FIRST-RUN</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/zsh</string>
        <string>/Library/.tje/LMAM/LMAM_vignette-local-step1-run.zsh</string>
    </array>
    <key>WatchPaths</key>
    <array>
        <string>/Library/Managed Preferences/com.jamf.connect.login.plist</string>
    </array>
</dict>
</plist>
EOF


# Create the Admin Monitor LaunchDaemon plist
cat << EOF > "$ADMIN_MONITOR_LD_PATH"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.TJE.LMAM-ADMIN-MONITOR</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/zsh</string>
        <string>Library/.tje/LMAM/LMAM_vignette-local-step3-run.zsh</string>
    </array>
    <key>WatchPaths</key>
    <array>
        <string>/private/var/db/dslocal/nodes/Default/groups/admin.plist</string>
    </array>
    <key>KeepAlive</key>
    <false/>
    <key>AbandonProcessGroup</key>
    <true/>
</dict>
</plist>
EOF


# Create the Failsafe Cleanup LaunchDaemon plist
cat << EOF > "$FAILSAFE_CLEANUP_LD_PATH"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.TJE.LMAM-FAILSAFE-CLEANUP</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/zsh</string>
        <string>/Library/.tje/LMAM/LMAM_vignette-cleanup-run.zsh</string>
    </array>
    <key>StartInterval</key>
    <integer>600</integer>
    <key>KeepAlive</key>
    <false/>
    <key>AbandonProcessGroup</key>
    <true/>
</dict>
</plist>
EOF

######################
# Create LaunchAgents
######################

# # Create the Login Trigger LaunchAgent plist
# cat << EOF > "$LOGIN_TRIGGER_LA_PATH"
# <?xml version="1.0" encoding="UTF-8"?>
# <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
# <plist version="1.0">
# <dict>
#     <key>Label</key>
#     <string>com.TJE.LMAM-LOGIN-TRIGGER</string>
#     <key>ProgramArguments</key>
#     <array>
#         <string>/bin/zsh</string>
#         <string>/Library/.tje/LMAM/LMAM_vignette-local-step2-run.zsh</string>
#     </array>
# 	<key>RunAtLoad</key>
#     <true/>
#     <key>LimitLoadToSessionType</key>
#     <array>
#         <string>Aqua</string>
#     </array>
# </dict>
# </plist>
# EOF

# Set the permissions for the First Run LaunchDaemon
sudo chmod 644 "$FIRST_RUN_LD_PATH"
sudo chown root:wheel "$FIRST_RUN_LD_PATH"

# # Set the permissions for the Login Trigger LaunchAgent
# sudo chmod 644 "$LOGIN_TRIGGER_LA_PATH"
# sudo chown root:wheel "$LOGIN_TRIGGER_LA_PATH"

# Set the permissions for the Admin Monitor LaunchDaemon
sudo chmod 644 "$ADMIN_MONITOR_LD_PATH"
sudo chown root:wheel "$ADMIN_MONITOR_LD_PATH"

# Set the permissions for the Failsafe Cleanup LaunchDaemon
sudo chmod 644 "$FAILSAFE_CLEANUP_LD_PATH"
sudo chown root:wheel "$FAILSAFE_CLEANUP_LD_PATH"

# Load the LaunchDaemons
sudo launchctl bootstrap system "$FIRST_RUN_LD_PATH"
sudo launchctl bootstrap system "$ADMIN_MONITOR_LD_PATH"
sudo launchctl bootstrap system "$FAILSAFE_CLEANUP_LD_PATH"

# Load the LaunchAgents
# sudo launchctl bootstrap system "$LOGIN_TRIGGER_LA_PATH"

sudo /usr/local/bin/jamf recon

exit 0