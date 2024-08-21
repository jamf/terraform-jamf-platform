#!/bin/sh

if [ -e /Library/.tje/apply_cis ]; then
    echo "<result>apply_cis</result>"
else
    echo "<result></result>"
fi

exit 0