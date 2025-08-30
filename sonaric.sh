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

# Display project branding
curl -s https://raw.githubusercontent.com/noxuspace/cryptofortochka/main/logo_club.sh | bash

# Check for bc utility
echo -e "${BLUE}Verifying system version...${NC}"
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
echo -e "${CYAN}3) Node status check${NC}"
echo -e "${CYAN}4) Points verification${NC}"
echo -e "${CYAN}5) Node backup${NC}"
echo -e "${CYAN}6) Node registration${NC}"
echo -e "${CYAN}7) Node removal${NC}"

echo -e "${YELLOW}Enter selection:${NC} "
read user_selection

case $user_selection in
    1)
        echo -e "${BLUE}Initializing Sonaric node setup...${NC}"

        # System preparation and dependencies
        sudo apt update -y
        sudo apt upgrade -y
        sudo apt install git -y
        sudo apt install jq -y
        sudo apt install build-essential -y
        sudo apt install gcc -y
        sudo apt install unzip -y
        sudo apt install wget -y
        sudo apt install lz4 -y

        # Node.js installation
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install nodejs -y

        # Sonaric deployment
        sh -c "$(curl -fsSL http://get.sonaric.xyz/scripts/install.sh)"

        # Completion message
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Node status check command:${NC}"
        echo "sonaric node-info"
        sleep 2
        sonaric node-info
        ;;
    2)
        echo -e "${BLUE}Updating Sonaric node...${NC}"
        
        sh -c "$(curl -fsSL http://get.sonaric.xyz/scripts/install.sh)"

        # Status message
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Node status check command:${NC}"
        echo "sonaric node-info"
        sleep 2
        sonaric node-info
        ;;
    3)
        echo -e "${BLUE}Checking node status...${NC}"
        sonaric node-info
        ;;
    4)
        echo -e "${BLUE}Verifying points balance...${NC}"
        sonaric points
        ;;
    5)
        echo -e "${YELLOW}Enter your node name (used during setup):${NC}"
        read NODE_NAME

        sonaric identity-export -o "$NODE_NAME.identity"

        echo -e "${GREEN}Backup created: ${NODE_NAME}.identity${NC}"
        cd && cat ${NODE_NAME}.identity
        ;;
    6)
        # Registration code input
        echo -e "${YELLOW}Paste code received from Discord:${NC}"
        read DISCORD_CODE

        # Code validation
        if [ -z "$DISCORD_CODE" ]; then
            echo -e "${YELLOW}No code provided. Please try again.${NC}"
            exit 1
        fi
        
        # Node registration
        sonaric node-register "$DISCORD_CODE"
        ;;
    7)
        echo -e "${BLUE}Removing Sonaric node...${NC}"

        sudo systemctl stop sonaricd
        sudo rm -rf $HOME/.sonaric

        echo -e "${GREEN}Sonaric node successfully removed!${NC}"
        sleep 1
        ;;
    *)
        echo -e "${RED}Invalid selection. Please choose 1-7.${NC}"
        ;;
esac
