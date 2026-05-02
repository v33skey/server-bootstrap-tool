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

#COMMENT THIS FOR TESTS
ask_connection_data() {
    while true; do
        read -rp "Enter server IP: " SERVER_IP

        if is_valid_ip "$SERVER_IP"; then
            break
        fi

        printf "Invalid IP, try again. \n"

    done
    while true; do
        read -rp "Enter root username: " USERNAME_ROOT
        if [ -z "$USERNAME_ROOT" ]; then
            printf "Username invalid. Try again\n"
        else
            break
        fi
    done
    return 0
}
connection_data() {
    printf "Your connection data:\n Server IP : $SERVER_IP \n Root username: \"$USERNAME_ROOT\"\n"
}
#Создание SSH-ключа для соединения с сервером без ввода пароля
ssh_key_creation_tool(){
    printf "For better security, a non-root user should be created.\n" 
    read -rp "Enter the new username: " DEF_USERNAME 
    while true; do
        if [[ -z "$DEF_USERNAME" ]]; then
            read -rp "Username cannot be empty. Try again.\n" DEF_USERNAME
        else
            break
        fi
    done
    read -rp "Name your SSH-key: " SSH_KEY_NAME
    while true; do
        if [[ -z "$SSH_KEY_NAME" ]]; then
            read -rp "SSH-key name cannot be empty. Try again. \n" SSH_KEY_NAME
        else
            ssh-keygen -t ed25519 -f "$HOME/.ssh/$SSH_KEY_NAME"
            ssh "$USERNAME_ROOT"@"$SERVER_IP" "adduser $DEF_USERNAME && usermod -aG sudo $DEF_USERNAME"
            cat "$HOME/.ssh/$SSH_KEY_NAME.pub" | ssh "$USERNAME_ROOT"@"$SERVER_IP" "
            mkdir -p \"/home/$DEF_USERNAME/.ssh/\" &&
            tee -a \"/home/$DEF_USERNAME/.ssh/authorized_keys\" &&
            chmod 700 \"/home/$DEF_USERNAME/.ssh\" &&
            chmod 600 \"/home/$DEF_USERNAME/.ssh/authorized_keys\" &&
            chown -R $DEF_USERNAME:$DEF_USERNAME \"/home/$DEF_USERNAME/.ssh\""
            break
        fi
    done

}

main() {
    ask_connection_data
    connection_data
    ssh_key_creation_tool
    read -rsp "Press any key to close window..."
}

main
#FOR TESTS
# SERVER_IP="192.168.0.1"
# USERNAME="USER"
# PASSWD="123123"

# printf "\n"
# printf "Connection parameters:\n"
# printf "Server IP: %s\n" "$SERVER_IP"
# printf "Username: %s\n" "$USERNAME"

# #Asks user need SSH-key
# printf "Do you need to create SSH-key? (Print 1 or 2)\n"
# printf "1. Yes\n"
# printf "2. No\n"


# while true; do
#     read -rp "Choose an option (Default Yes): " SSH_OPTION

#     if [ "$SSH_OPTION" = "1" ] || [ -z "$SSH_OPTION" ]; then
#         ssh-keygen -t ed25519 -f ~/.ssh/keykey
#         break
#     elif [ "$SSH_OPTION" = "2" ]; then
#         printf "Now you need to login by your password every time\n"
#         break
#     else
#         printf "Invalid option. Try again.\n"
#     fi
# done
# #script exiting
# read -rsp "Press any key to close window..."    