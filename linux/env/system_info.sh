#! /bin/env bash

# Welcome
welcome=$(uname -r)

# Memory
memory_total=$(free -m | awk '/Mem:/ { printf($2)}')
if [ "$memory_total" -gt 0 ]
then
    memory_usage=$(free -m | awk '/Mem:/ { printf("%3.1f%%", $3/$2*100)}')
else
    memory_usage=0.0%
fi

# Swap memory
swap_total=$(free -m | awk '/Swap:/ { printf($2)}')
if [ "$swap_total" -gt 0 ]
then
    swap_mem=$(free -m | awk '/Swap:/ { printf("%3.1f%%", $3/$2*100)}')
else
    swap_mem=0.0%
fi

# Usage
usageof=$(df -h / | awk '/\// {print $(NF-1)}')

# System load
load_average=$(awk '{print $1}' /proc/loadavg)

# WHO I AM
#whoiam=$(whoami)

# Time
time_cur=$(date)

# Processes
processes=$(ps aux | wc -l)

# Users
user_num=$(users | wc -w)

# Ip address
ip_pre=""
if [ -x "/sbin/ip" ]
then
    ip_pre=$(/sbin/ip a | grep inet | grep -v "127.0.0.1" | grep -v inet6 | awk '{print $2}')
fi

echo -e "\n"
echo -e "Welcome to $welcome\n"
echo -e "System information as of time: \t$time_cur\n"
echo -e "System load: \t\033[0;33;40m$load_average\033[0m"
echo -e "Processes: \t$processes"
echo -e "Memory used: \t$memory_usage"
echo -e "Swap used: \t$swap_mem"
echo -e "Usage On: \t$usageof"
for line in $ip_pre
do
    ip_address=${line%/*}
    echo -e "IP address: \t$ip_address"
done
echo -e "Users online: \t$user_num"
#if [ "$whoiam" == "root" ]
#then
#    echo -e "\n"
#else
#    echo -e "To run a command as administrator(user \"root\"),use \"sudo <command>\"."
#fi

echo -e "\n"
