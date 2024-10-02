#!/bin/sh

if [ -e /Library/.tje/LMAM/lmamRUN ]; then
	echo "<result>lmamRUN</result>"
else
	echo "<result>No_LMAM</result>"
fi

exit 0