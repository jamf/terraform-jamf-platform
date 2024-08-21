#!/bin/sh

if [ -e /Library/.tje/remove_cis ]; then
    echo "<result>remove_cis</result>"
else
    echo "<result></result>"
fi

exit 0