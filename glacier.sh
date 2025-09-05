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
echo -e "${CYAN}1) Node deployment${NC}"
echo -e "${CYAN}2) Node update${NC}"
echo -e "${CYAN}3) Log monitoring${NC}"
echo -e "${CYAN}4) Node removal${NC}"

echo -e "${YELLOW}Enter selection:${NC} "
read user_choice

case $user_choice in
    1)
        echo -e "${BLUE}Initializing Glacier node setup...${NC}"

        # System preparation
        sudo apt update -y
        sudo apt upgrade -y

        # Docker environment verification
        if ! command -v docker &> /dev/null; then
            echo -e "${BLUE}Docker not found. Installing Docker...${NC}"
            sudo apt install docker.io -y
        fi

        # Private key input
        echo -e "${YELLOW}Enter your wallet private key:${NC}"
        read -r WALLET_PRIVATE_KEY

        # Container deployment
        docker run -d -e PRIVATE_KEY=$WALLET_PRIVATE_KEY --name glacier-verifier docker.io/glaciernetwork/glacier-verifier:v0.0.4

        # Completion message
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Log monitoring command:${NC}"
        echo "docker logs -f glacier-verifier"
        sleep 2

        # Log verification
        docker logs -f glacier-verifier
        ;;

    2)
        echo -e "${BLUE}Updating Glacier node...${NC}"

        # Private key input
        echo -e "${YELLOW}Enter your wallet private key:${NC}"
        read -r WALLET_PRIVATE_KEY

        # Container update process
        docker stop glacier-verifier
        docker rm glacier-verifier
        docker images --filter=reference='glaciernetwork/glacier-verifier:*' -q | xargs -r docker rmi
        docker run -d -e PRIVATE_KEY=$WALLET_PRIVATE_KEY --name glacier-verifier docker.io/glaciernetwork/glacier-verifier:v0.0.4

        # Status message
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Log monitoring command:${NC}"
        echo "docker logs -f glacier-verifier"
        sleep 2

        # Log verification
        docker logs -f glacier-verifier
        ;;

    3)
        echo -e "${BLUE}Monitoring Glacier logs...${NC}"
        docker logs -f glacier-verifier
        ;;

    4)
        echo -e "${BLUE}Removing Glacier node...${NC}"

        # Container cleanup
        docker stop glacier-verifier
        docker rm glacier-verifier
        docker images --filter=reference='glaciernetwork/glacier-verifier:*' -q | xargs -r docker rmi

        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}Glacier node successfully removed!${NC}"
        sleep 1
        ;;

    *)
        echo -e "${RED}Invalid selection. Please choose 1-4.${NC}"
        ;;
esac
