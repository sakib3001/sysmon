#!/bin/bash
cpu_usage_limit=$1
ram_usage_limit=$2
disk_usage_limit=$3

if [[ -z $cpu_usage_limit || -z $ram_usage_limit || -z $disk_usage_limit   ]]; then 
echo "Enter all arguments: <cpu_usage_limit> <ram_usage_limit> <disk_usage_limit>"
exit 1
fi

check_cpu_usages() {
    echo -e "==> Checking the CPU usages"
    
    # 100 - idle_cpu = used_cpu
    used_cpu=$(mpstat 1 2 | awk '/^Average/ { printf "%.2f", 100 - $12 }')

    if [ $(echo "${used_cpu} >= ${cpu_usage_limit}" | bc) -eq 1 ]; then
        echo -e "Sending Mail: CPU Used is High: ${used_cpu}%"
    else
        echo -e "CPU Usage: ${used_cpu}% (normal)"
    fi
}

check_ram_usages() {
    echo -e "==> Checking the RAM usages"
    used_memory=$(free -h | awk 'NR > 1 {
        used = $3
        if (used ~ /Mi/) {
            # Converted to GB
            used_value = substr(used, 1, length(used) - 2) / 1024
            printf "%.2f\n", used_value # Print with two decimal values
        } else if (used ~ /Gi/) {
            used_value = substr(used, 1, length(used) - 2)
            printf "%.2f\n", used_value
        }
    }')

    # Floating point comparison; bc returns 1 or 0
    if [ $(echo "${used_memory} >= ${ram_usage_limit}" | bc) -eq 1 ]; then
        echo "Sending Mail: RAM Used is High"
    else
        echo -e "RAM Usage: ${used_memory} GiB (normal)"
    fi
}

check_network_connections() {
    echo "Checking Network connections..."
    ss -tuln
    echo "==================================================>"
    echo "Active connections:"
    ss -anp | grep ESTABLISHED
}

check_disk_usage() {
    echo "==> Checking Disk usage..."
    disk_usages=($(df -h | awk -v limit="$disk_usage_limit" 'NR>2 {
    disk_used_value = substr($5, 1, length($5)-1)
    if (disk_used_value >= limit) {
        print $1 " is using " disk_used_value "%"
    }
}' | tr '\n' ';'))

IFS=';' read -r -a disk_usages_array <<< "${disk_usages[@]}"

# Print the full lines from the array disk_usages_array
for i in "${disk_usages_array[@]}"; do
    disk_usages=$(echo "$i" | awk '{
    used_value = substr($4,1,length($4)-1)
    print used_value
    }')
    disk_name=$(echo "$i" | awk '{
    print $1
    }')
    if [[ $disk_usages -gt $disk_usage_limit ]]; then
    echo -e "Sending Mail: High Disk Used: ${disk_usages}% on disk: ${disk_name}"
    else 
    echo "Normal Disk Used: ${disk_usages}% on disk: ${disk_name}"
    fi
done
}

# Call the functions
check_ram_usages
check_cpu_usages
check_disk_usage
check_network_connections


