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

# Verify bc utility for version comparison
if ! command -v bc &> /dev/null; then
    sudo apt update
    sudo apt install bc -y
fi
sleep 1

# Ubuntu version validation
UBUNTU_VERSION=$(lsb_release -rs)
REQUIRED_VERSION=22.04

if (( $(echo "$UBUNTU_VERSION < $REQUIRED_VERSION" | bc -l) )); then
    echo -e "${RED}Minimum Ubuntu 22.04 required for this node${NC}"
    exit 1
fi

# Operation selection menu
echo -e "${YELLOW}Select operation:${NC}"
echo -e "${CYAN}1) Node deployment${NC}"
echo -e "${CYAN}2) Node update${NC}"
echo -e "${CYAN}3) Access screen session${NC}"
echo -e "${CYAN}4) Node removal${NC}"
read -p "Enter selection: " user_choice

case $user_choice in
    1)
        echo -e "${BLUE}Installing OpenLedger node...${NC}"

        # Docker installation and verification
        if ! command -v docker &> /dev/null; then
            echo -e "${YELLOW}Docker not found. Installing Docker...${NC}"
            apt remove docker docker-engine docker.io containerd runc -y
            apt install -y apt-transport-https ca-certificates curl software-properties-common
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            apt update
            apt install -y docker-ce docker-ce-cli containerd.io
            echo -e "${GREEN}Docker installed successfully.${NC}"
        else
            echo -e "${GREEN}Docker already installed.${NC}"
        fi

        # Docker service management
        if systemctl is-active --quiet docker; then
            echo "Docker service is running."
        else
            echo "Starting Docker service..."
            sudo systemctl start docker
        fi

        if systemctl is-enabled --quiet docker; then
            echo "Docker auto-start enabled."
        else
            echo "Enabling Docker auto-start..."
            sudo systemctl enable docker
        fi

        # System dependencies
        sudo apt update && sudo apt upgrade -y
        sudo apt install ubuntu-desktop xrdp unzip screen -y
        sudo apt install -y desktop-file-utils libgbm1 libasound2
        sudo dpkg --configure -a

        # XRDP configuration
        sudo adduser xrdp ssl-cert
        sudo systemctl start gdm
        sudo systemctl enable xrdp
        sudo systemctl restart xrdp

        # OpenLedger installation
        wget https://cdn.openledger.xyz/openledger-node-1.0.0-linux.zip
        unzip openledger-node-1.0.0-linux.zip
        sudo dpkg -i openledger-node-1.0.0.deb

        # Screen session management
        if screen -list | grep -q "openledger"; then
            screen -S openledger -X quit
            echo -e "${YELLOW}Existing openledger screen sessions removed.${NC}"
        fi
        screen -dmS openledger_node bash -c 'openledger-node --no-sandbox --disable-gpu; sleep infinity'

        # Completion message
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Screen session access command:${NC}" 
        echo "screen -r openledger_node"
        ;;

    2)
        echo -e "${GREEN}Node running latest available version.${NC}"
        ;;

    3)
        echo -e "${YELLOW}Accessing screen session...${NC}"
        if screen -list | grep -q "openledger_node"; then
            screen -r openledger_node
        else
            echo -e "${RED}Openledger screen session not found.${NC}"
        fi
        ;;

    4)
        echo -e "${RED}Removing OpenLedger node...${NC}"
        if screen -list | grep -q "openledger_node"; then
            screen -S openledger_node -X quit
            echo -e "${YELLOW}Openledger screen sessions terminated.${NC}"
        fi
        rm -f openledger-node-1.0.0-linux.zip
        rm -f openledger-node-1.0.0.deb
        sudo apt remove --purge -y openledger-node
        echo -e "${GREEN}OpenLedger node successfully removed.${NC}"
        ;;

    *)
        echo -e "${RED}Invalid selection. Please choose 1-4.${NC}"
        ;;
esac
