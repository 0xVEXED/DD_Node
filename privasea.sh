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

# Operation selection menu
echo -e "${YELLOW}Select operation:${NC}"
echo -e "${CYAN}1) Node deployment${NC}"
echo -e "${CYAN}2) Node startup${NC}"
echo -e "${CYAN}3) Log monitoring${NC}"
echo -e "${CYAN}4) Node restart${NC}"
echo -e "${CYAN}5) Node update${NC}"
echo -e "${CYAN}6) Node removal${NC}"

read -p "Enter selection: " user_choice

case $user_choice in
    1)
        echo -e "${BLUE}Initializing Privasea node setup...${NC}"

        # System preparation
        sudo apt update && sudo apt upgrade -y

        # Docker environment verification
        if ! command -v docker &> /dev/null; then
            echo -e "${BLUE}Docker not found. Installing Docker...${NC}"
            sudo apt install docker.io -y
            if ! command -v docker &> /dev/null; then
                echo -e "${RED}Error: Docker installation failed${NC}"
                exit 1
            fi
        fi

        if ! command -v docker-compose &> /dev/null; then
            echo -e "${BLUE}Docker Compose not found. Installing...${NC}"
            sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
            if ! command -v docker-compose &> /dev/null; then
                echo -e "${RED}Error: Docker Compose installation failed${NC}"
                exit 1
            fi
        fi

        # Project setup
        docker pull privasea/acceleration-node-beta:latest
        mkdir -p ~/privasea/config
        ;;

    2)
        echo -e "${BLUE}Starting Privasea node...${NC}"

        # Password input
        echo -e "${YELLOW}Enter wallet password (used during creation):${NC}"
        read -s -p "Password: " WALLET_PASSWORD
        echo

        # Container deployment
        docker run -d --name privanetix-node -v "$HOME/privasea/config:/app/config" -e KEYSTORE_PASSWORD=$WALLET_PASSWORD --restart unless-stopped privasea/acceleration-node-beta:latest
        if [ $? -ne 0 ]; then
            echo -e "${RED}Failed to start Docker container${NC}"
            exit 1
        fi

        # Completion message
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Log monitoring command:${NC}"
        echo "docker logs -f privanetix-node"
        sleep 2

        docker logs -f privanetix-node
        ;;

    3)
        echo -e "${BLUE}Monitoring Privasea logs...${NC}"
        docker logs -f privanetix-node
        ;;

    4)
        echo -e "${BLUE}Restarting Privasea node...${NC}"

        # Container restart
        docker restart privanetix-node
        sleep 2

        # Post-restart monitoring
        docker logs -f privanetix-node
        ;;

    5)
        echo -e "${GREEN}Privasea node is running latest version${NC}"
        ;;

    6)
        echo -e "${BLUE}Removing Privasea node...${NC}"

        # Container cleanup
        docker stop privanetix-node
        docker rm privanetix-node
        rm -rf ~/privasea
        sleep 2
        ;;

    *)
        echo -e "${RED}Invalid selection!${NC}"
        ;;
esac
