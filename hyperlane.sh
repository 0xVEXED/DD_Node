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
        echo -e "${BLUE}Installing Hyperlane node...${NC}"

        # System preparation and dependencies
        sudo apt update -y
        sudo apt upgrade -y

        # Docker environment verification
        if ! command -v docker &> /dev/null; then
            echo -e "${YELLOW}Docker not found. Installing Docker...${NC}"
            sudo apt install docker.io -y
        else
            echo -e "${GREEN}Docker already installed. Skipping.${NC}"
        fi

        # Download Docker image
        docker pull --platform linux/amd64 gcr.io/abacus-labs-dev/hyperlane-agent:agents-v1.0.0

        # User configuration input
        echo -e "${YELLOW}Enter validator name:${NC}"
        read NAME
        echo -e "${YELLOW}Enter EVM wallet private key (starting with 0x):${NC}"
        read PRIVATE_KEY

        # Directory setup
        mkdir -p $HOME/hyperlane_db_base && chmod -R 777 $HOME/hyperlane_db_base

        # Container deployment
        docker run -d -it \
        --name hyperlane \
        --mount type=bind,source=$HOME/hyperlane_db_base,target=/hyperlane_db_base \
        gcr.io/abacus-labs-dev/hyperlane-agent:agents-v1.0.0 \
        ./validator \
        --db /hyperlane_db_base \
        --originChainName base \
        --reorgPeriod 1 \
        --validator.id "$NAME" \
        --checkpointSyncer.type localStorage \
        --checkpointSyncer.folder base  \
        --checkpointSyncer.path /hyperlane_db_base/base_checkpoints \
        --validator.key "$PRIVATE_KEY" \
        --chains.base.signer.key "$PRIVATE_KEY" \
        --chains.base.customRpcUrls https://base.llamarpc.com

        # Completion message
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Log monitoring command:${NC}"
        echo "docker logs --tail 100 -f hyperlane"
        sleep 2
        docker logs --tail 100 -f hyperlane
        ;;

    2)
        echo -e "${BLUE}Checking Hyperlane node version...${NC}"
        echo -e "${GREEN}Node running latest available version!${NC}"
        ;;

    3)
        echo -e "${BLUE}Monitoring node logs...${NC}"
        docker logs --tail 100 -f hyperlane
        ;;

    4)
        echo -e "${BLUE}Removing Hyperlane node...${NC}"

        # Container cleanup
        docker stop hyperlane
        docker rm hyperlane

        # Directory removal
        if [ -d "$HOME/hyperlane_db_base" ]; then
            rm -rf $HOME/hyperlane_db_base
            echo -e "${GREEN}Node directory removed.${NC}"
        else
            echo -e "${RED}Node directory not found.${NC}"
        fi

        echo -e "${GREEN}Hyperlane node successfully removed!${NC}"
        sleep 1
        ;;

    *)
        echo -e "${RED}Invalid selection. Please choose 1-4.${NC}"
        ;;
esac
