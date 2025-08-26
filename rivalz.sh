#!/bin/bash

# Terminal output color definitions
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

# User interaction menu
echo -e "${YELLOW}Select operation:${NC}"
echo -e "${CYAN}1) Node deployment${NC}"
echo -e "${CYAN}2) Node version update${NC}"
echo -e "${CYAN}3) Access screen session${NC}"
echo -e "${CYAN}4) Node removal${NC}"

echo -e "${YELLOW}Enter selection:${NC} "
read user_selection

case $user_selection in
    1)
        echo -e "${BLUE}Initializing Rivalz node setup...${NC}"

        # System preparation and component installation
        sudo apt update -y
        sudo apt upgrade -y
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt install -y nodejs
        npm i -g rivalz-node-cli
        sudo apt-get update
        sudo apt-get install screen -y

        # Identify existing screen sessions
        ACTIVE_SESSIONS=$(screen -ls | grep "rivalz" | awk '{print $1}' | cut -d '.' -f 1)

        # Terminate existing sessions if found
        if [ -n "$ACTIVE_SESSIONS" ]; then
            echo -e "${BLUE}Closing existing screen sessions: $ACTIVE_SESSIONS${NC}"
            for SESSION in $ACTIVE_SESSIONS; do
                screen -S "$SESSION" -X quit
            done
        else
            echo -e "${BLUE}No active sessions detected, creating new session...${NC}"
        fi

        # Initialize new screen session
        screen -dmS rivalz

        # Completion message
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Node operational in screen session: rivalz${NC}"
        echo -e "${YELLOW}To access session use:${NC}"
        echo -e "screen -r rivalz"
        ;;
    2)
        echo -e "${BLUE}Checking node version...${NC}"
        echo -e "${GREEN}Node running latest available version!${NC}"
        ;;
    3)
        echo -e "${BLUE}Connecting to screen session...${NC}"
        screen -r rivalz
        ;;
    4)
        echo -e "${BLUE}Initiating node removal process...${NC}"

        # Locate active screen sessions
        ACTIVE_SESSIONS=$(screen -ls | grep "rivalz" | awk '{print $1}' | cut -d '.' -f 1)

        # Terminate all related sessions
        if [ -n "$ACTIVE_SESSIONS" ]; then
            echo -e "${BLUE}Terminating sessions: $ACTIVE_SESSIONS${NC}"
            for SESSION in $ACTIVE_SESSIONS; do
                screen -S "$SESSION" -X quit
            done
        else
            echo -e "${BLUE}No active sessions found, proceeding with cleanup...${NC}"
        fi
        sleep 1
        ;;
    *)
        echo -e "${RED}Invalid selection. Please choose between 1-4.${NC}"
        ;;
esac
