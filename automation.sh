#!/usr/bin/env bash

set -euo pipefail

is_valid_ip() {
    local ip="$1"
    local IFS="."
    local -a octets

    [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1

    read -r -a octets <<< "$ip"
    
    for octet in "${octets[@]}"; do
        ((octet >= 0 && octet <= 255)) || return 1
    done

    return 0
}

while true; do
    read -rp "Enter server IP: " SERVER_IP

    if is_valid_ip "$SERVER_IP"; then
        break
    fi

    printf "Invalid IP, try again. \n"

done

read -rp "Enter username: " USERNAME

read -rsp "Enter user password: " PASSWD

printf "\n "
printf "Connection parameters:\n"
printf "Server IP: %s\n" "$SERVER_IP"
printf "Username: %s\n" "$USERNAME"

read -rsp "Press any key to close window..."