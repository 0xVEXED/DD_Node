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
echo -e "${CYAN}2) Node status check${NC}"
echo -e "${CYAN}3) Node removal${NC}"

echo -e "${YELLOW}Enter choice:${NC} "
read selection

case $selection in
    1)
        echo -e "${BLUE}Starting node deployment...${NC}"

        # System preparation
        sudo apt update && sudo apt upgrade -y

        # Cleanup previous installation files
        rm -f ~/install.sh ~/update.sh ~/start.sh
        
        # Download installation script
        echo -e "${BLUE}Downloading client package...${NC}"
        wget https://mdeck-download.s3.us-east-1.amazonaws.com/client/linux/install.sh
        source ./install.sh

        # Download update package
        echo -e "${BLUE}Updating components...${NC}"
        wget https://mdeck-download.s3.us-east-1.amazonaws.com/client/linux/update.sh
        source ./update.sh

        # Navigate to installation directory
        cd ~/multipleforlinux

        # Start node service
        echo -e "${BLUE}Launching multiple-node service...${NC}"
        wget https://mdeck-download.s3.us-east-1.amazonaws.com/client/linux/start.sh
        source ./start.sh

        # Account configuration
        echo -e "${YELLOW}Enter your Account ID:${NC}"
        read IDENTIFIER
        echo -e "${YELLOW}Set your PIN code:${NC}"
        read PIN

        # Bind account to node
        echo -e "${BLUE}Linking account ID: $IDENTIFIER with PIN: $PIN...${NC}"
        multiple-cli bind --bandwidth-download 100 --identifier $IDENTIFIER --pin $PIN --storage 200 --bandwidth-upload 100

        # Completion message
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Node status check command:${NC}"
        echo "cd ~/multipleforlinux && ./multiple-cli status"
        sleep 2
        cd ~/multipleforlinux && ./multiple-cli status
        ;;

    2)
        # Node status verification
        echo -e "${BLUE}Checking node status...${NC}"
        cd ~/multipleforlinux && ./multiple-cli status
        ;;

    3)
        echo -e "${BLUE}Initiating node removal...${NC}"

        # Terminate node processes
        pkill -f multiple-node

        # Remove installation files
        cd ~
        sudo rm -rf multipleforlinux

        echo -e "${GREEN}Node successfully removed!${NC}"
        sleep 1
        ;;
        
    *)
        echo -e "${RED}Invalid selection. Please choose 1-3.${NC}"
        ;;
esac
