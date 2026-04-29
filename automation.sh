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

#UNCOMMENT THIS
# while true; do
#     read -rp "Enter server IP: " SERVER_IP

#     if is_valid_ip "$SERVER_IP"; then
#         break
#     fi

#     printf "Invalid IP, try again. \n"

# done

# read -rp "Enter username: " USERNAME

# read -rsp "Enter user password: " PASSWD

#DELETE THIS
SERVER_IP="192.168.0.1"
USERNAME="USER"
PASSWD="123123"

printf "\n"
printf "Connection parameters:\n"
printf "Server IP: %s\n" "$SERVER_IP"
printf "Username: %s\n" "$USERNAME"

#Asks user need SSH-key
printf "Do you need to create SSH-key? (Print 1 or 2)\n"
printf "1. Yes\n"
printf "2. No\n"


while true; do
    read -rp "Choose an option (Default Yes): " SSH_OPTION

    if [ "$SSH_OPTION" = "1" ] || [ -z "$SSH_OPTION" ]; then
        ssh-keygen -t ed25519 -f ~/.ssh/keykey
        break
    elif [ "$SSH_OPTION" = "2" ]; then
        printf "Now you need to login by your password every time\n"
        break
    else
        printf "Invalid option. Try again.\n"s
    fi
done
#script exiting
read -rsp "Press any key to close window..."