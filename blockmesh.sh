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
echo -e "${BLUE}Checking system version...${NC}"
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
echo -e "${CYAN}2) Log monitoring (exit with CTRL+C)${NC}"
echo -e "${CYAN}3) Node update${NC}"
echo -e "${CYAN}4) Node restart${NC}"
echo -e "${CYAN}5) Node removal${NC}"

echo -e "${YELLOW}Enter selection:${NC} "
read user_choice

case $user_choice in
    1)
        echo -e "${BLUE}Installing BlockMesh node...${NC}"

        # Verify tar utility
        if ! command -v tar &> /dev/null; then
            sudo apt install tar -y
        fi
        sleep 1
        
        # Download BlockMesh binary
        wget https://github.com/block-mesh/block-mesh-monorepo/releases/download/v0.0.390/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz

        # Extract archive
        tar -xzvf blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz
        sleep 1

        # Cleanup archive
        rm blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz

        # Navigate to directory
        cd target/x86_64-unknown-linux-gnu/release/

        # User credentials input
        echo -e "${YELLOW}Enter your BlockMesh email:${NC} "
        read EMAIL
        echo -e "${YELLOW}Enter your BlockMesh password:${NC} "
        read PASSWORD

        # System service configuration
        USERNAME=$(whoami)
        HOME_DIR=$(eval echo ~$USERNAME)

        sudo bash -c "cat <<EOT > /etc/systemd/system/blockmesh.service
[Unit]
Description=BlockMesh CLI Service
After=network.target

[Service]
User=$USERNAME
ExecStart=$HOME_DIR/target/x86_64-unknown-linux-gnu/release/blockmesh-cli login --email $EMAIL --password $PASSWORD
WorkingDirectory=$HOME_DIR/target/x86_64-unknown-linux-gnu/release
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOT"

        # Service management
        sudo systemctl daemon-reload
        sudo systemctl restart systemd-journald
        sleep 1
        sudo systemctl enable blockmesh
        sudo systemctl start blockmesh

        # Completion message
        echo -e "${GREEN}Installation completed and node started!${NC}"

        # Final instructions
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Log monitoring command:${NC}" 
        echo "sudo journalctl -u blockmesh -f"
        sleep 2

        # Log verification
        sudo journalctl -u blockmesh -f
        ;;

    2)
        # Log monitoring
        sudo journalctl -u blockmesh -f
        ;;

    3)
        echo -e "${BLUE}Updating BlockMesh node...${NC}"

        # Service cleanup
        sudo systemctl stop blockmesh
        sudo systemctl disable blockmesh
        sudo rm /etc/systemd/system/blockmesh.service
        sudo systemctl daemon-reload
        sleep 1

        # Remove old files
        rm -rf target
        sleep 1

        # Download updated binary
        wget https://github.com/block-mesh/block-mesh-monorepo/releases/download/v0.0.377/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz

        # Extract archive
        tar -xzvf blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz
        sleep 1

        # Cleanup archive
        rm blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz

        # Navigate to directory
        cd target/x86_64-unknown-linux-gnu/release/

        # Updated credentials input
        echo -e "${YELLOW}Enter your BlockMesh email:${NC} "
        read EMAIL
        echo -e "${YELLOW}Enter your BlockMesh password:${NC} "
        read PASSWORD

        # Service reconfiguration
        USERNAME=$(whoami)
        HOME_DIR=$(eval echo ~$USERNAME)

        sudo bash -c "cat <<EOT > /etc/systemd/system/blockmesh.service
[Unit]
Description=BlockMesh CLI Service
After=network.target

[Service]
User=$USERNAME
ExecStart=$HOME_DIR/target/x86_64-unknown-linux-gnu/release/blockmesh-cli login --email $EMAIL --password $PASSWORD
WorkingDirectory=$HOME_DIR/target/x86_64-unknown-linux-gnu/release
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOT"

        # Service restart
        sudo systemctl daemon-reload
        sudo systemctl restart systemd-journald
        sleep 1
        sudo systemctl enable blockmesh
        sudo systemctl restart blockmesh

        # Completion message
        echo -e "${GREEN}Update completed and node restarted!${NC}"

        # Final instructions
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Log monitoring command:${NC}" 
        echo "sudo journalctl -u blockmesh -f"
        sleep 2

        # Log verification
        sudo journalctl -u blockmesh -f
        ;;

    4)
        echo -e "${BLUE}Restarting BlockMesh node...${NC}"

        # Service stop
        sudo systemctl stop blockmesh

        # Navigate to directory
        cd target/x86_64-unknown-linux-gnu/release/

        # Credentials re-input
        echo -e "${YELLOW}Enter your BlockMesh email:${NC} "
        read EMAIL
        echo -e "${YELLOW}Enter your BlockMesh password:${NC} "
        read PASSWORD

        # Service reconfiguration
        USERNAME=$(whoami)
        HOME_DIR=$(eval echo ~$USERNAME)

        sudo bash -c "cat <<EOT > /etc/systemd/system/blockmesh.service
[Unit]
Description=BlockMesh CLI Service
After=network.target

[Service]
User=$USERNAME
ExecStart=$HOME_DIR/target/x86_64-unknown-linux-gnu/release/blockmesh-cli login --email $EMAIL --password $PASSWORD
WorkingDirectory=$HOME_DIR/target/x86_64-unknown-linux-gnu/release
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOT"

        # Service restart with new credentials
        sudo systemctl daemon-reload
        sudo systemctl restart systemd-journald
        sleep 1
        sudo systemctl restart blockmesh

        # Completion message
        echo -e "${GREEN}Restart completed with updated credentials!${NC}"

        # Final instructions
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Log monitoring command:${NC}" 
        echo "sudo journalctl -u blockmesh -f"
        sleep 2

        # Log verification
        sudo journalctl -u blockmesh -f
        ;;

    5)
        echo -e "${BLUE}Removing BlockMesh node...${NC}"

        # Service cleanup
        sudo systemctl stop blockmesh
        sudo systemctl disable blockmesh
        sudo rm /etc/systemd/system/blockmesh.service
        sudo systemctl daemon-reload
        sleep 1

        # File cleanup
        rm -rf target

        echo -e "${GREEN}BlockMesh node successfully removed!${NC}"
        ;;
        
esac
