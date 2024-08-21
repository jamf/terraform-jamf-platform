#!/bin/bash

#This script writes a file that will trigger an EA in Jamf Pro to join a Smart Group

#Writing the file that is watched by the EA

mkdir /Library/.tje
rm /Library/.tje/remove_cis
touch /Library/.tje/apply_cis

jamf recon

sleep 4

#Quitting Self Service to refresh

osascript -e 'quit application "Self Service"'

dialog -p -o -b -t "Apply CIS Level 1" -m "[Jamf Compliance Editor](https://trusted.jamf.com/docs/establishing-compliance-baselines#jamf-compliance-editor) and Jamf Pro can be used to effeciently establish and enforce compliance baselines across Apple device fleets.\n\n #### What will happen?\n\n - Once completed portions of CIS Level 1 will be enforced on this Mac.\n\n   - __In this simulation, the entirety if CIS Level 1 is not being enforced as it would interfere with some macOS functionality.__\n\n #### Why is this important?\n\n - Regulated industries, government agencies and contractors may be required to meet specific standards such as __NIST-800, DISA STIG, CMMC__ and more.\n\n - In production, once deployed, baselines will be enforced, audited and remediated. " --icon 'SF=checkmark.shield' infobuttontext "Close" --quitoninfo

sleep 15

open -g -a Self\ Service.app

exit 0