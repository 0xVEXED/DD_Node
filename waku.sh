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
echo -e "${CYAN}4) Port replacement${NC}"
echo -e "${CYAN}5) Node removal${NC}"

echo -e "${YELLOW}Enter selection:${NC} "
read user_choice

case $user_choice in
    1)
        echo -e "${BLUE}Installing Waku node...${NC}"

        # System preparation and dependencies
        sudo apt update -y
        sudo apt upgrade -y
        sudo apt install -y curl iptables build-essential git wget jq make gcc nano tmux htop nvme-cli \
                            pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip

        # Docker version verification
        if ! command -v docker &> /dev/null; then
            echo -e "${YELLOW}Docker not found. Installing Docker version 24.0.7...${NC}"
            curl -fsSL https://get.docker.com | sh
        else
            DOCKER_VERSION=$(docker --version | grep -oP '\d+\.\d+\.\d+')
            MIN_DOCKER_VERSION="24.0.7"
            if [[ "$(printf '%s\n' "$MIN_DOCKER_VERSION" "$DOCKER_VERSION" | sort -V | head -n1)" != "$MIN_DOCKER_VERSION" ]]; then
                echo -e "${YELLOW}Upgrading Docker to version 24.0.7...${NC}"
                curl -fsSL https://get.docker.com | sh
            fi
        fi

        # Docker Compose version verification
        if ! command -v docker-compose &> /dev/null; then
            echo -e "${YELLOW}Docker Compose not found. Installing version 1.29.2...${NC}"
            sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
        else
            DOCKER_COMPOSE_VERSION=$(docker-compose --version | grep -oP '\d+\.\d+\.\d+')
            MIN_COMPOSE_VERSION="1.29.2"
            if [[ "$(printf '%s\n' "$MIN_COMPOSE_VERSION" "$DOCKER_COMPOSE_VERSION" | sort -V | head -n1)" != "$MIN_COMPOSE_VERSION" ]]; then
                echo -e "${YELLOW}Upgrading Docker Compose to version 1.29.2...${NC}"
                sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                sudo chmod +x /usr/local/bin/docker-compose
            fi
        fi

        # Repository setup
        cd $HOME
        git clone https://github.com/waku-org/nwaku-compose
        cd $HOME/nwaku-compose
        cp .env.example .env

        # User configuration input
        echo -e "${YELLOW}Enter RPC URL for testnet access:${NC}"
        read RPC_URL
        echo -e "${YELLOW}Enter your EVM wallet private key:${NC}"
        read ETH_KEY
        echo -e "${YELLOW}Enter RLN Membership password:${NC}"
        read RLN_PASSWORD

        # Environment configuration update
        sed -i "s|RLN_RELAY_ETH_CLIENT_ADDRESS=.*|RLN_RELAY_ETH_CLIENT_ADDRESS=$RPC_URL|" .env
        sed -i "s|ETH_TESTNET_KEY=.*|ETH_TESTNET_KEY=$ETH_KEY|" .env
        sed -i "s|RLN_RELAY_CRED_PASSWORD=.*|RLN_RELAY_CRED_PASSWORD=$RLN_PASSWORD|" .env

        # Node registration
        ./register_rln.sh

        # Service deployment
        docker-compose up -d

        # Completion message
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Log monitoring command:${NC}"
        echo -e "cd $HOME/nwaku-compose && docker-compose logs -f"
        sleep 2
        cd $HOME/nwaku-compose && docker-compose logs -f
        ;;

    2)
        echo -e "${BLUE}Updating Waku node...${NC}"
        cd $HOME/nwaku-compose
        docker-compose down
        sudo rm -fr rln_tree keystore
        git pull origin master
        ./register_rln.sh
        docker-compose up -d
        
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Log monitoring command:${NC}"
        echo -e "cd $HOME/nwaku-compose && docker-compose logs -f"
        sleep 2
        cd $HOME/nwaku-compose && docker-compose logs -f
        ;;

    3)
        echo -e "${BLUE}Monitoring Waku node logs...${NC}"
        cd $HOME/nwaku-compose
        docker-compose logs -f
        ;;

    4)
        # Docker compose file path
        COMPOSE_FILE="$HOME/nwaku-compose/docker-compose.yml"
        
        # File existence verification
        if [[ ! -f "$COMPOSE_FILE" ]]; then
            echo -e "${RED}Docker-compose.yml not found at: $COMPOSE_FILE${NC}"
            exit 1
        fi
        
        # Port replacement function
        replace_port() {
            local OLD_PORT="$1"
            local NEW_PORT="$2"
        
            # Verify old port existence
            if ! grep -qE "(:|[[:space:]])${OLD_PORT}:([0-9]+)" "$COMPOSE_FILE"; then
                echo -e "${RED}Port ${OLD_PORT} not found in file.${NC}"
                return 1
            fi
        
            # Replace only external port
            sed -i -E "s/(:|[[:space:]])(${OLD_PORT}):([0-9]+)/\1${NEW_PORT}:\3/g" "$COMPOSE_FILE"
        
            # Verify replacement success
            if grep -qE "(:|[[:space:]])${NEW_PORT}:([0-9]+)" "$COMPOSE_FILE"; then
                echo -e "${GREEN}Port ${OLD_PORT} successfully replaced with ${NEW_PORT}.${NC}"
            else
                echo -e "${RED}Error: failed to replace port ${OLD_PORT} with ${NEW_PORT}.${NC}"
                return 1
            fi
        }
        
        # Port input
        echo -e "${YELLOW}Enter external port to replace:${NC} \c"
        read OLD_PORT
        
        if ! [[ "$OLD_PORT" =~ ^[0-9]+$ ]]; then
            echo -e "${RED}Error: port must be numeric.${NC}"
            exit 1
        fi
        
        echo -e "${YELLOW}Enter new external port:${NC} \c"
        read NEW_PORT
        
        if ! [[ "$NEW_PORT" =~ ^[0-9]+$ ]]; then
            echo -e "${RED}Error: new port must be numeric.${NC}"
            exit 1
        fi
        
        # Confirmation
        echo -e "${YELLOW}Replace external port ${OLD_PORT} with ${NEW_PORT}? (y/n)${NC} \c"
        read CONFIRM
        if [[ "$CONFIRM" != "y" ]]; then
            echo -e "${CYAN}Operation cancelled by user.${NC}"
            exit 0
        fi
        
        # Service stop
        echo -e "${YELLOW}Stopping containers...${NC}"
        cd "$HOME/nwaku-compose" || exit
        docker-compose down
        
        # Port replacement
        replace_port "$OLD_PORT" "$NEW_PORT"
        
        # Service restart
        echo -e "${YELLOW}Restarting containers...${NC}"
        docker-compose up -d
        echo -e "${GREEN}Containers successfully restarted!${NC}"

        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Log monitoring command:${NC}"
        echo -e "cd $HOME/nwaku-compose && docker-compose logs -f"
        sleep 1
        ;;

    5)
        echo -e "${BLUE}Removing Waku node...${NC}"
        cd $HOME/nwaku-compose
        docker-compose down
        cd $HOME
        rm -rf nwaku-compose
        echo -e "${GREEN}Waku node successfully removed!${NC}"
        ;;

    *)
        echo -e "${RED}Invalid selection. Please choose 1-5.${NC}"
        ;;
esac
