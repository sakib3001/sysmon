#!/bin/bash
ram_usage_limit=$1
cpu_usage_limit=$1

check_cpu_usages() {
    echo -e "==> Checking the CPU usages"
    used_cpu=$(mpstat 1 2 | awk '/^Average/ {
        # Process the average CPU usage line
        total_cpu_usages = $3 + $4 + $5 + $6 + $7 + $8 + $9 + $10
        total_cpu_usages_value = substr(total_cpu_usages,1,length(total_cpu_usages)-1)
        printf "%.2f\n", total_cpu_usages_value
    }')

    # Floating point comparison; bc returns 1 or 0    
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

# check_network_connections() {
#     echo "Checking Network connections..."
#     netstat -tuln
# }

# check_disk_usage() {
#     echo "==> Checking Disk usage..."
#     df -h | awk '$5 > 60 {print NR, $0}'
# }


# Call the functions
check_ram_usages
check_cpu_usages


