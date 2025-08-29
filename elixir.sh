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
echo -e "${CYAN}1) Testnet node deployment${NC}"
echo -e "${CYAN}2) Testnet node update${NC}"
echo -e "${CYAN}3) Testnet logs monitoring${NC}"
echo -e "${CYAN}4) Testnet node removal${NC}"
echo -e "${CYAN}5) Mainnet node deployment${NC}"
echo -e "${CYAN}6) Mainnet node update${NC}"
echo -e "${CYAN}7) Mainnet logs monitoring${NC}"
echo -e "${CYAN}8) Mainnet node removal${NC}"

echo -e "${YELLOW}Enter selection:${NC} "
read user_choice

case $user_choice in
    1)
        echo -e "${BLUE}Initializing testnet node setup...${NC}"

        # System preparation and dependencies
        sudo apt update -y
        sudo apt upgrade -y
        sudo apt install -y curl git jq lz4 build-essential unzip

        # Docker environment verification
        if ! command -v docker &> /dev/null; then
            echo -e "${YELLOW}Docker not found. Installing Docker...${NC}"
            sudo apt install docker.io -y
        fi

        if ! command -v docker-compose &> /dev/null; then
            echo -e "${YELLOW}Docker Compose not found. Installing...${NC}"
            sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
        fi

        # Project directory setup
        mkdir -p $HOME/elixir
        cd $HOME/elixir
        wget https://files.elixir.finance/validator.env

        # User configuration input
        echo -e "${YELLOW}Enter server IP address:${NC}"
        read STRATEGY_EXECUTOR_IP_ADDRESS

        echo -e "${YELLOW}Enter validator name:${NC}"
        read STRATEGY_EXECUTOR_DISPLAY_NAME

        echo -e "${YELLOW}Enter EVM address:${NC}"
        read STRATEGY_EXECUTOR_BENEFICIARY

        echo -e "${YELLOW}Enter EVM private key:${NC}"
        read SIGNER_PRIVATE_KEY

        # Configuration file update
        sed -i 's|ENV=prod|ENV=testnet-3|' validator.env
        echo "STRATEGY_EXECUTOR_IP_ADDRESS=$STRATEGY_EXECUTOR_IP_ADDRESS" >> validator.env
        echo "STRATEGY_EXECUTOR_DISPLAY_NAME=$STRATEGY_EXECUTOR_DISPLAY_NAME" >> validator.env
        echo "STRATEGY_EXECUTOR_BENEFICIARY=$STRATEGY_EXECUTOR_BENEFICIARY" >> validator.env
        echo "SIGNER_PRIVATE_KEY=$SIGNER_PRIVATE_KEY" >> validator.env

        # Docker image acquisition
        docker pull elixirprotocol/validator:testnet --platform linux/amd64

        # User confirmation
        echo -e "${YELLOW}Follow the guide and claim tokens on platform. Press Enter when ready...${NC}"
        read -p ""

        # Container deployment
        docker run --name elixir --env-file validator.env --platform linux/amd64 -p 17690:17690 --restart unless-stopped elixirprotocol/validator:testnet

        # Completion message
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Log monitoring command:${NC}"
        echo "docker logs -f elixir"
        sleep 2      
        ;;
    2)
        echo -e "${BLUE}Updating testnet node...${NC}"

        # Container management
        cd $HOME/elixir
        docker ps -a | grep " elixir$" | awk '{print $1}' | xargs docker stop
        docker ps -a | grep " elixir$" | awk '{print $1}' | xargs docker rm

        # Version update
        docker pull elixirprotocol/validator:testnet --platform linux/amd64

        # Container restart
        docker run --name elixir --env-file validator.env --platform linux/amd64 -p 17690:17690 --restart unless-stopped elixirprotocol/validator:testnet

        # Status message
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Log monitoring command:${NC}"
        echo "docker logs -f elixir"
        sleep 2
        ;;
    3)
        # Log monitoring
        docker logs -f elixir
        ;;
    4)
        echo -e "${BLUE}Removing testnet node...${NC}"

        # Container cleanup
        cd $HOME/elixir
        docker ps -a | grep " elixir$" | awk '{print $1}' | xargs docker stop
        docker ps -a | grep " elixir$" | awk '{print $1}' | xargs docker rm

        # Project removal
        rm -rf $HOME/elixir

        echo -e "${GREEN}Node successfully removed!${NC}"
        sleep 1
        ;;
    5)
        echo -e "${BLUE}Initializing mainnet node setup...${NC}"

        # System preparation
        sudo apt update -y
        sudo apt upgrade -y
        sudo apt install -y curl git jq lz4 build-essential unzip

        # Docker verification
        if ! command -v docker &> /dev/null; then
            echo -e "${YELLOW}Docker not found. Installing...${NC}"
            sudo apt install docker.io -y
        fi

        if ! command -v docker-compose &> /dev/null; then
            echo -e "${YELLOW}Docker Compose not found. Installing...${NC}"
            sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
        fi

        # Mainnet directory setup
        mkdir -p $HOME/elixir-main
        cd $HOME/elixir-main
        wget https://files.elixir.finance/validator.env

        # Configuration input
        echo -e "${YELLOW}Enter server IP address:${NC}"
        read STRATEGY_EXECUTOR_IP_ADDRESS

        echo -e "${YELLOW}Enter validator name:${NC}"
        read STRATEGY_EXECUTOR_DISPLAY_NAME

        echo -e "${YELLOW}Enter EVM address:${NC}"
        read STRATEGY_EXECUTOR_BENEFICIARY

        echo -e "${YELLOW}Enter EVM private key:${NC}"
        read SIGNER_PRIVATE_KEY

        # Configuration update
        sed -i 's|ENV=prod|ENV=prod|' validator.env
        echo "STRATEGY_EXECUTOR_IP_ADDRESS=$STRATEGY_EXECUTOR_IP_ADDRESS" >> validator.env
        echo "STRATEGY_EXECUTOR_DISPLAY_NAME=$STRATEGY_EXECUTOR_DISPLAY_NAME" >> validator.env
        echo "STRATEGY_EXECUTOR_BENEFICIARY=$STRATEGY_EXECUTOR_BENEFICIARY" >> validator.env
        echo "SIGNER_PRIVATE_KEY=$SIGNER_PRIVATE_KEY" >> validator.env

        # Image acquisition
        docker pull elixirprotocol/validator --platform linux/amd64

        # Container deployment
        docker run --name elixir-main --env-file validator.env --platform linux/amd64 -p 17691:17690 --restart unless-stopped elixirprotocol/validator

        # Completion message
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Log monitoring command:${NC}"
        echo "docker logs -f elixir-main"
        sleep 2
        ;;
    6)
        echo -e "${BLUE}Updating mainnet node...${NC}"

        # Container management
        cd $HOME/elixir-main
        docker ps -a | grep " elixir-main$" | awk '{print $1}' | xargs docker stop
        docker ps -a | grep " elixir-main$" | awk '{print $1}' | xargs docker rm

        # Version update
        docker pull elixirprotocol/validator --platform linux/amd64

        # Container restart
        docker run --name elixir-main --env-file validator.env --platform linux/amd64 -p 17691:17690 --restart unless-stopped elixirprotocol/validator

        # Status message
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Log monitoring command:${NC}"
        echo "docker logs -f elixir-main"
        sleep 2
        ;;
    7)
        # Log monitoring
        docker logs -f elixir-main
        ;;
    8)
        echo -e "${BLUE}Removing mainnet node...${NC}"

        # Container cleanup
        cd $HOME/elixir-main
        docker ps -a | grep " elixir-main$" | awk '{print $1}' | xargs docker stop
        docker ps -a | grep " elixir-main$" | awk '{print $1}' | xargs docker rm

        # Project removal
        rm -rf $HOME/elixir-main

        echo -e "${GREEN}Node successfully removed!${NC}"
        sleep 1
        ;;
    *)
        echo -e "${RED}Invalid selection. Please choose from menu options.${NC}"
        ;;
esac
