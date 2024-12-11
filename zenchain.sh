#!/bin/bash

curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

# Variabel warna untuk output
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m'

# Meminta nama validator dari pengguna
read -p "Masukkan nama validator: " VALIDATOR_NAME

# Memastikan sistem memiliki dependensi yang dibutuhkan
install_dependencies() {
    echo -e "${YELLOW}Memeriksa dan menginstal dependensi yang diperlukan...${NC}"
    sudo apt-get update
    sudo apt-get install -y jq curl git build-essential
}

# Memastikan Docker dan Docker Compose terinstal
check_docker_installation() {
    if ! command -v docker &>/dev/null; then
        echo -e "${YELLOW}Docker tidak ditemukan. Menginstal Docker...${NC}"
        sudo apt-get install -y docker.io
        sudo systemctl start docker
        sudo systemctl enable docker
    else
        echo -e "${GREEN}Docker sudah terinstal.${NC}"
    fi

    if ! command -v docker-compose &>/dev/null; then
        echo -e "${YELLOW}Docker Compose tidak ditemukan. Menginstal Docker Compose...${NC}"
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.17.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    else
        echo -e "${GREEN}Docker Compose sudah terinstal.${NC}"
    fi
}

# Memastikan direktori chain-data ada dan memiliki izin yang benar
ensure_chain_data_directory() {
    echo -e "${YELLOW}Memastikan direktori ./chain-data dan izin yang benar...${NC}"

    # Direktori yang diperlukan
    mkdir -p ./chain-data

    # Memperbaiki izin direktori
    sudo chown -R $USER:$USER ./chain-data
    sudo chmod -R 755 ./chain-data

    echo -e "${GREEN}Direktori ./chain-data dan izin telah disiapkan.${NC}"
}

# Membuat file docker-compose.yml di direktori saat ini
create_docker_compose_file() {
    echo -e "${YELLOW}Membuat file docker-compose.yml...${NC}"
    cat <<EOF >./docker-compose.yml
version: '3.8'
services:
  zenchain:
    image: ghcr.io/zenchain-protocol/zenchain-testnet:latest
    container_name: zenchain
    ports:
      - "30333:30333"
    volumes:
      - ./chain-data:/chain-data
      - ./zenchain-config:/config
    user: "${UID}:${GID}"  # Menambahkan user dan group ID sesuai dengan yang digunakan di host
    command: >
      ./usr/bin/zenchain-node
      --base-path=/chain-data
      --rpc-cors=all
      --rpc-methods=unsafe
      --unsafe-rpc-external
      --validator
      --name=${VALIDATOR_NAME}
      --bootnodes=/dns4/node-7242611732906999808-0.p2p.onfinality.io/tcp/26266/p2p/12D3KooWLAH3GejHmmchsvJpwDYkvacrBeAQbJrip5oZSymx5yrE
      --chain=zenchain_testnet
EOF
    echo -e "${GREEN}File docker-compose.yml berhasil dibuat di direktori saat ini.${NC}\n"
}

# Memastikan berada di direktori yang benar sebelum menjalankan docker-compose
run_docker_compose() {
    echo -e "${YELLOW}Menjalankan Docker Compose untuk ZenChain Node...${NC}"

    # Menyimpan direktori saat ini
    CURRENT_DIR=$(pwd)

    # Memastikan kita berada di direktori yang sama dengan docker-compose.yml
    if [[ ! -f ./docker-compose.yml ]]; then
        echo -e "${RED}File docker-compose.yml tidak ditemukan di direktori ini!${NC}"
        exit 1
    fi

    # Menjalankan docker-compose dari direktori tempat file berada
    docker-compose down
    docker-compose up -d
    echo -e "${GREEN}ZenChain Node berhasil dijalankan.${NC}"
}

# Menunggu 60 detik untuk memastikan RPC aktif
wait_for_rpc() {
    echo -e "${YELLOW}Menunggu 60 detik untuk memastikan RPC aktif...${NC}"
    sleep 60
}

# Mendapatkan session keys
get_session_keys() {
    echo -e "${YELLOW}Mendapatkan Session Keys...${NC}"
    SESSION_KEYS=$(curl --max-time 10 --silent --retry 5 --retry-delay 5 --url http://localhost:9944 -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"author_rotateKeys","params":[],"id":1}' | jq -r .result)
    if [[ -z "$SESSION_KEYS" ]]; then
        echo -e "${YELLOW}Gagal mendapatkan Session Keys. Pastikan port 9944 terbuka.${NC}"
    else
        echo -e "${GREEN}Session Keys berhasil didapatkan: ${SESSION_KEYS}${NC}"
        echo "$SESSION_KEYS" > session_keys.txt
        echo -e "${GREEN}Session Keys disimpan di file session_keys.txt.${NC}"
    fi
}

# Melihat logs dari kontainer Docker Zenchain
view_logs() {
    echo -e "${YELLOW}Melihat logs dari Docker container Zenchain...${NC}"
    docker logs -f zenchain
}

# Menanyakan apakah ingin melihat logs setelah setup selesai
view_logs_option() {
    echo -e "${YELLOW}Apakah Anda ingin melihat logs dari ZenChain Node? (y/n)${NC}"
    read -p "Pilih opsi: " VIEW_LOGS
    if [[ "$VIEW_LOGS" == "y" || "$VIEW_LOGS" == "Y" ]]; then
        view_logs
    else
        echo -e "${GREEN}Proses selesai. Session Keys telah disimpan di session_keys.txt.${NC}"
    fi
}

# Menampilkan ajakan bergabung dengan Channel Telegram
join_telegram_channel() {
    echo -e "${GREEN}Terima kasih telah mengikuti proses ini. Jangan lupa untuk bergabung dengan Channel Telegram AirdropNode untuk update lebih lanjut: ${NC}"
    echo -e "${GREEN}👉 ${YELLOW}https://t.me/airdrop_node${NC}"
}

# Menjalankan semua langkah
install_dependencies
check_docker_installation
ensure_chain_data_directory
create_docker_compose_file
run_docker_compose
wait_for_rpc
get_session_keys

# Menampilkan opsi untuk melihat logs
view_logs_option

# Menampilkan ajakan bergabung Channel Telegram
join_telegram_channel
