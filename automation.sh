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
    return 0
}
#Вывод введенных данных для проверки
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
