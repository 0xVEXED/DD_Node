#!/bin/bash

# Terminal color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Verify curl availability
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi
sleep 1

# Operation selection menu
echo -e "${YELLOW}Select operation:${NC}"
echo -e "${CYAN}1) Install dependencies${NC}"
echo -e "${CYAN}2) Start Merkle service${NC}"
echo -e "${CYAN}3) Launch node${NC}"
echo -e "${CYAN}4) Monitor node logs${NC}"
echo -e "${CYAN}5) Restart node${NC}"
echo -e "${CYAN}6) Update node${NC}"
echo -e "${CYAN}7) Remove node${NC}"

echo -e "${YELLOW}Enter selection:${NC} "
read user_choice

case $user_choice in
    1)
        echo -e "${BLUE}Installing dependencies...${NC}"

        # System preparation and dependencies
        sudo apt update && sudo apt-get upgrade -y
        sudo apt install -y git screen htop curl wget build-essential

        git clone https://github.com/Layer-Edge/light-node.git
        cd light-node

        VER="1.21.3"
        wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
        sudo rm -rf /usr/local/go
        sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
        rm "go$VER.linux-amd64.tar.gz"
        [ ! -f ~/.bash_profile ] && touch ~/.bash_profile
        echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
        source $HOME/.bash_profile
        [ ! -d ~/go/bin ] && mkdir -p ~/go/bin

        if ! command -v rustc &> /dev/null; then
            echo -e "${BLUE}Rust not found. Installing via rustup...${NC}"
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
            source $HOME/.cargo/env
            echo -e "${GREEN}Rust installed successfully.${NC}"
        else
            echo -e "${BLUE}Rust already installed. Updating via rustup...${NC}"
            rustup update
            source $HOME/.cargo/env
            echo -e "${GREEN}Rust updated successfully.${NC}"
        fi

        curl -L https://risczero.com/install | bash
        source "$HOME/.bashrc"
        sleep 5
        rzup install

        # Private key input
        echo -e "${YELLOW}Enter your private key (without 0x):${NC} "
        read PRIV_KEY
        
        # Create .env configuration
        echo "GRPC_URL=grpc.testnet.layeredge.io:9090" > .env
        echo "CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709" >> .env
        echo "ZK_PROVER_URL=http://127.0.0.1:3001" >> .env
        echo "ZK_PROVER_URL=https://layeredge.mintair.xyz" >> .env
        echo "API_REQUEST_TIMEOUT=100" >> .env
        echo "POINTS_API=https://light-node.layeredge.io" >> .env
        echo "PRIVATE_KEY='$PRIV_KEY'" >> .env

        cd ~
        
        echo -e "${GREEN}Dependencies installed and configured!${NC}"
        ;;
    2)
        echo -e "${BLUE}Starting Merkle service...${NC}"

        # System service configuration
        USERNAME=$(whoami)
        HOME_DIR=$(eval echo ~$USERNAME)

        sudo bash -c "cat <<EOT > /etc/systemd/system/merkle.service
[Unit]
Description=Merkle Service for Light Node
After=network.target

[Service]
User=$USERNAME
Environment=PATH=$HOME/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin
WorkingDirectory=$HOME_DIR/light-node/risc0-merkle-service
ExecStart=/usr/bin/env bash -c \"cargo build && cargo run --release\"
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOT"

        sudo systemctl daemon-reload
        sleep 2
        sudo systemctl enable merkle.service
        sudo systemctl start merkle.service
        # Log monitoring
        sudo journalctl -u merkle.service -f
        ;;
    3)
        echo -e "${BLUE}Launching node...${NC}"
        USERNAME=$(whoami)
        HOME_DIR=$(eval echo ~$USERNAME)

        # Go path verification
        GO_PATH=$(which go)
        
        if [ -z "$GO_PATH" ]; then
            echo "Go not found in PATH. Please verify Go installation."
            exit 1
        fi

        sudo bash -c "cat <<EOT > /etc/systemd/system/light-node.service
[Unit]
Description=LayerEdge Light Node Service
After=network.target

[Service]
User=$USERNAME
WorkingDirectory=$HOME_DIR/light-node
ExecStartPre=$GO_PATH build
ExecStart=$HOME_DIR/light-node/light-node
Restart=always
RestartSec=10
TimeoutStartSec=200

[Install]
WantedBy=multi-user.target
EOT"

        sudo systemctl daemon-reload
        sleep 2
        sudo systemctl enable light-node.service
        sudo systemctl start light-node.service

        # Completion message
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Log monitoring command:${NC}"
        echo "sudo journalctl -u light-node.service -f"
        sleep 2
        sudo journalctl -u light-node.service -f
        ;;
    4)
        echo -e "${BLUE}Monitoring node logs...${NC}"
        sudo journalctl -u light-node.service -f
        ;;
    5)
        echo -e "${BLUE}Restarting node...${NC}"
        sudo systemctl restart light-node.service
        sudo journalctl -u light-node.service -f
        ;;
    6)
        echo -e "${BLUE}Updating node...${NC}"
        cd light-node
        sudo systemctl stop light-node.service

        rm -f .env

        # Private key input for update
        echo -e "${YELLOW}Enter your private key (without 0x):${NC} "
        read PRIV_KEY
        
        # Recreate configuration
        echo "GRPC_URL=grpc.testnet.layeredge.io:9090" > .env
        echo "CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709" >> .env
        echo "ZK_PROVER_URL=http://127.0.0.1:3001" >> .env
        echo "ZK_PROVER_URL=https://layeredge.mintair.xyz" >> .env
        echo "API_REQUEST_TIMEOUT=100" >> .env
        echo "POINTS_API=https://light-node.layeredge.io" >> .env
        echo "PRIVATE_KEY='$PRIV_KEY'" >> .env

        cd ~
        
        sudo systemctl restart light-node.service
        sudo journalctl -u light-node.service -f
        ;;
    7)
        echo -e "${BLUE}Removing node...${NC}"
        sudo systemctl stop light-node.service
        sudo systemctl disable light-node.service
        sudo systemctl stop merkle.service
        sudo systemctl disable merkle.service

        sudo rm /etc/systemd/system/light-node.service
        sudo rm /etc/systemd/system/merkle.service
        sudo systemctl daemon-reload

        rm -rf ~/light-node

        echo -e "${GREEN}Node successfully removed!${NC}"
        sleep 1
        ;;
    *)
        echo -e "${RED}Invalid selection. Please choose 1-7.${NC}"
        ;;
esac
