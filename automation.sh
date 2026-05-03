#!/usr/bin/env bash

set -euo pipefail
#Валидация введенного IP адреса сервера
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

#Сбор данных для работы скрипта
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
        read -rp "Enter the username for server operations: " DEF_USERNAME
        if [ -z "$DEF_USERNAME" ]; then
            printf "Non-root username is invalid. Try again\n"
        else
            break
        fi
    done
    return 0
}
#Вывод введенных данных для проверки
connection_data() {
    printf "Your connection data:\n Server IP : $SERVER_IP \n Root username: \"$USERNAME_ROOT\"\n Target username: \"$DEF_USERNAME\"\n"
}

#Создание SSH-ключа для соединения с сервером без ввода пароля
ssh_key_creation_tool(){
    # if [[ -z "$DEF_USERNAME" ]]; then
    #     read -rp "Enter the new username: " DEF_USERNAME 
    # else
    #     while true; do
    #         if [[ -z "$DEF_USERNAME" ]]; then
    #             read -rp "Username cannot be empty. Try again.\n" DEF_USERNAME
    #         else
    #             break
    #         fi
    #     done
    # read -rp "Name your SSH-key: " SSH_KEY_NAME
    read -rp "Name your SSH-key: " SSH_KEY_NAME
    while true; do
        if [[ -z "$SSH_KEY_NAME" ]]; then
            read -rp "SSH-key name cannot be empty. Try again. \n" SSH_KEY_NAME
        else

            if ssh "$USERNAME_ROOT"@"$SERVER_IP" "id $DEF_USERNAME"; then
                ssh-keygen -t ed25519 -f "$HOME/.ssh/$SSH_KEY_NAME"
                cat "$HOME/.ssh/$SSH_KEY_NAME.pub" | ssh "$USERNAME_ROOT"@"$SERVER_IP" "
                mkdir -p \"/home/$DEF_USERNAME/.ssh/\" &&
                tee -a \"/home/$DEF_USERNAME/.ssh/authorized_keys\" &&
                chmod 700 \"/home/$DEF_USERNAME/.ssh\" &&
                chmod 600 \"/home/$DEF_USERNAME/.ssh/authorized_keys\" &&
                chown -R $DEF_USERNAME:$DEF_USERNAME \"/home/$DEF_USERNAME/.ssh\""
                printf "SSH-key for \"$DEF_USERNAME\" is available to use."
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
    adduser $DEF_USERNAME && 
    usermod -aG sudo $DEF_USERNAME &&
    echo '$DEF_USERNAME ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/$DEF_USERNAME &&
    chmod 440 /etc/sudoers.d/$DEF_USERNAME"
}

change_user(){
    read -rp "Print a new username: " DEF_USERNAME
    while true; do
        if [[ -z "$DEF_USERNAME" ]]; then
            read -rp "Username cannot be empty. Enter username: " DEF_USERNAME
        else   
            break
        fi
    done

}

install_docker(){
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
    ssh "$DEF_USERNAME"@"$SERVER_IP" '
    sudo apt update &&
    sudo apt install -y ca-certificates curl &&
    sudo install -m 0755 -d /etc/apt/keyrings &&
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc &&
    sudo chmod a+r /etc/apt/keyrings/docker.asc &&
    CODENAME=$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") &&
    ARCH=$(dpkg --print-architecture) &&
    echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${CODENAME} stable" |
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null &&
    sudo apt update &&
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin &&
    sudo systemctl enable --now --quiet docker
    '
}

install_docker_debian(){
    ssh "$DEF_USERNAME"@"$SERVER_IP" '
    sudo apt update &&
    sudo apt install -y ca-certificates curl &&
    sudo install -m 0755 -d /etc/apt/keyrings &&
    sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc &&
    sudo chmod a+r /etc/apt/keyrings/docker.asc &&
    CODENAME=$(. /etc/os-release && echo "$VERSION_CODENAME") &&
    ARCH=$(dpkg --print-architecture) &&
    echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian ${CODENAME} stable" |
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null &&
    sudo apt update &&
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin &&
    sudo systemctl enable --now --quiet docker
    '
}

menu(){
    local CHOICE
    while true; do
        clear
        printf "1. Install docker\n"
        printf "2. Install SSH-key\n"
        printf "3. Change connection data\n"
        printf "4. Print connection info\n"
        printf "5. Create new user\n"
        printf "6. Change target user\n"
        printf "0. Exit\n"
        read -rp "Choose an action(nums): " CHOICE
        case "$CHOICE" in
        #Install docker
        1) 
            install_docker
            ;;
        2)
            if ssh_key_creation_tool; then
                printf "SSH key installed succesffully\n"
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
                printf "New user '$DEF_USERNAME' created. "
                read -rp "Press Enter to continue"
            else
                printf "Creating new user failed, try again"
                read -rp "Press Enter to continue"
            fi
        ;;
        6)
            if change_user; then
                printf "Target user set to '$DEF_USERNAME'."
                read -rp "Press Enter to continue"
            else
                printf "The user change failed, try again."
                read -rp "Press Enter to continue"
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
