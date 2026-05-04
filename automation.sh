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
    while true; do 
        read -rp "Enter target username" DEF_USERNAME
        if [ -z "$DEF_USERNAME" ]; then
            printf "Non-root username is invalid. Try again\n"
        else
            break
        fi
    done
    return 0
}

connection_data() {
    printf "Your connection data:\n Server IP : $SERVER_IP \n Root username: \"$USERNAME_ROOT\"\n Target username: \"$DEF_USERNAME\"\n"
}


ssh_key_creation_tool(){
    read -rp "Name your SSH key: " SSH_KEY_NAME
    while true; do
        if [[ -z "$SSH_KEY_NAME" ]]; then
            read -rp "SSH key name cannot be empty. Try again. \n" SSH_KEY_NAME
        else

            if ssh "$USERNAME_ROOT"@"$SERVER_IP" "id $DEF_USERNAME"; then
                ssh-keygen -t ed25519 -f "$HOME/.ssh/$SSH_KEY_NAME"
                cat "$HOME/.ssh/$SSH_KEY_NAME.pub" | ssh "$USERNAME_ROOT"@"$SERVER_IP" "
                mkdir -p \"/home/$DEF_USERNAME/.ssh/\" &&
                tee -a \"/home/$DEF_USERNAME/.ssh/authorized_keys\" &&
                chmod 700 \"/home/$DEF_USERNAME/.ssh\" &&
                chmod 600 \"/home/$DEF_USERNAME/.ssh/authorized_keys\" &&
                chown -R $DEF_USERNAME:$DEF_USERNAME \"/home/$DEF_USERNAME/.ssh\""
                printf "SSH key for \"$DEF_USERNAME\" is available to use."
                read -rp "Press any key to exit..."
                break
            else
                printf "Username '$DEF_USERNAME' does not exist. Creating new user.\n"
                create_user
            fi
            
        fi
    done

}

create_user(){
    ssh "$USERNAME_ROOT"@"$SERVER_IP" "
    apt update &&
    apt install -y sudo &&
    adduser \"$DEF_USERNAME\" && 
    usermod -aG sudo \"$DEF_USERNAME\""
}

change_user(){
    read -rp "Enter a new username: " DEF_USERNAME
    while true; do
        if [[ -z "$DEF_USERNAME" ]]; then
            read -rp "Username cannot be empty. Enter username: " DEF_USERNAME
        else   
            break
        fi
    done

}

# grant_temp_sudo(){
#     ssh "$USERNAME_ROOT"@"$SERVER_IP" "
#     printf '%s\n' '$DEF_USERNAME ALL=(ALL) NOPASSWD:ALL' > '/etc/sudoers.d/${DEF_USERNAME}-bootstrap' &&
#     chmod 440 '/etc/sudoers.d/${DEF_USERNAME}-bootstrap'
#     "
# }

# revoke_temp_sudo(){
#     ssh "$USERNAME_ROOT"@"$SERVER_IP" "
#     rm -f '/etc/sudoers.d/${DEF_USERNAME}-bootstrap'
#     "
# }

# run_with_temp_sudo() {
#     local install_func="$1"

#     grant_temp_sudo
#     trap revoke_temp_sudo RETURN

#     if "$install_func"; then
#         printf "Installation succeeded\n"
#     else
#         printf "Installation failed. Try again\n"
#     fi
#     read -rp "Press Enter to continue"
# }

install_docker() {
    local SYSTEM

    while true; do
        printf "1. Debian\n"
        printf "2. Ubuntu\n"
        read -rp "Choose a system: " SYSTEM

        case "$SYSTEM" in
        1)
            if install_docker_debian; then
                printf "Installation succeeded\n"
                read -rp "Press Enter to continue"
                break
                
            else
                printf "Installation failed. Try again\n"
                read -rp "Press Enter to continue"
            fi
            ;;
        2)
            if install_docker_ubuntu; then
                printf "Installation succeeded\n"
                read -rp "Press Enter to continue"
                break
            else
                printf "Installation failed. Try again\n"
                read -rp "Press Enter to continue"
                break
            fi
            ;;
        esac
    done
}


install_docker_ubuntu(){
    ssh "$USERNAME_ROOT"@"$SERVER_IP" '
    apt update &&
    apt install -y ca-certificates curl &&
    install -m 0755 -d /etc/apt/keyrings &&
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc &&
    chmod a+r /etc/apt/keyrings/docker.asc &&
    CODENAME=$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") &&
    ARCH=$(dpkg --print-architecture) &&
    echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${CODENAME} stable" |
    tee /etc/apt/sources.list.d/docker.list > /dev/null &&
    apt update &&
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin &&
    systemctl enable --now --quiet docker &&
    usermod -aG docker '"$DEF_USERNAME"'
    '
}

install_docker_debian(){
    ssh "$USERNAME_ROOT"@"$SERVER_IP" '
    apt update &&
    apt install -y ca-certificates curl &&
    install -m 0755 -d /etc/apt/keyrings &&
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc &&
    chmod a+r /etc/apt/keyrings/docker.asc &&
    CODENAME=$(. /etc/os-release && echo "$VERSION_CODENAME") &&
    ARCH=$(dpkg --print-architecture) &&
    echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian ${CODENAME} stable" |
    tee /etc/apt/sources.list.d/docker.list > /dev/null &&
    apt update &&
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin &&
    systemctl enable --now --quiet docker &&
    usermod -aG docker '"$DEF_USERNAME"'
    '
}

install_nginx(){
    ssh "$USERNAME_ROOT"@"$SERVER_IP" "
    apt update &&
    apt install -y nginx &&
    systemctl enable --now nginx
    "
}

menu(){
    local CHOICE
    while true; do
        clear
        printf "1. Install docker\n"
        printf "2. Install SSH key\n"
        printf "3. Change connection data\n"
        printf "4. Print connection info\n"
        printf "5. Create new user\n"
        printf "6. Change target user\n"
        printf "7. Install nginx\n"
        printf "0. Exit\n"
        read -rp "Choose an action(number): " CHOICE
        case "$CHOICE" in
        #Install docker
        1) 
            install_docker
            ;;
        2)
            if ssh_key_creation_tool; then
                printf "SSH key installed successfully\n"
                read -rp "Press Enter to continue"
            else
                printf "Installation failed. Try again\n"
                read -rp "Press Enter to continue"
            fi
            ;;
        3)
            if ask_connection_data; then
                printf "New connection data:\n"
                connection_data
            else
                printf "Something went wrong, check your data\n"
                read -rp "Press Enter to continue"
            fi
            ;;
        4)
            connection_data
            read -rp "Press Enter to continue"
            ;;
        5)
            if create_user; then
                printf "New user '$DEF_USERNAME' created. \n"
                read -rp "Press Enter to continue"
            else
                printf "Failed to create user. Try again."
                read -rp "Press Enter to continue"
            fi
        ;;
        6)
            if change_user; then
                printf "Target user set to '$DEF_USERNAME'.\n"
                read -rp "Press Enter to continue"
            else
                printf "Failed to change target user. Try again.\n"
                read -rp "Press Enter to continue"
            fi
        ;;
        7)  
            if install_nginx; then
                printf "Nginx installed successfully.\n"
                read -rp "Press any key to continue"
            else
                printf "Installation failed. Try again.\n"
                read -rp "Press any key to continue"
            fi
        ;;
        0)
            break
            ;;
        esac
        
    done
}

main() {
    ask_connection_data
    connection_data
    menu
    read -rsp "Press any key to close window..."
}

main
