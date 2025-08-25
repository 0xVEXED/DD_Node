#!/bin/bash

# Color definitions for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Function to check and install dependencies
check_dependencies() {
    if ! command -v curl &> /dev/null; then
        echo -e "${YELLOW}Installing required packages...${NC}"
        sudo apt update && sudo apt install -y curl
    fi
}

# Function to setup docker
setup_docker() {
    if command -v docker &> /dev/null; then
        echo -e "${GREEN}Docker is already installed${NC}"
        return 0
    fi
    
    echo -e "${BLUE}Setting up Docker environment...${NC}"
    sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common lsb-release gnupg2
    
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    echo -e "${GREEN}Docker installation completed${NC}"
}

# Function to setup docker-compose
setup_docker_compose() {
    if command -v docker-compose &> /dev/null; then
        echo -e "${GREEN}Docker Compose is ready${NC}"
        return 0
    fi
    
    echo -e "${BLUE}Getting Docker Compose...${NC}"
    local compose_version=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
    sudo curl -L "https://github.com/docker/compose/releases/download/$compose_version/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo -e "${GREEN}Docker Compose setup done${NC}"
}

# Function to configure user permissions
setup_permissions() {
    if ! groups $USER | grep -q '\bdocker\b'; then
        echo -e "${BLUE}Configuring user permissions...${NC}"
        sudo groupadd docker 2>/dev/null
        sudo usermod -aG docker $USER
        echo -e "${YELLOW}Please logout and login again for permissions to take effect${NC}"
    else
        echo -e "${GREEN}User permissions already configured${NC}"
    fi
}

# Function to deploy titan node
deploy_titan() {
    echo -e "${BLUE}Downloading Titan container image...${NC}"
    docker pull nezha123/titan-edge
    
    mkdir -p ~/.titanedge
    
    echo -e "${BLUE}Starting Titan node...${NC}"
    docker run --name titan --network=host -d -v ~/.titanedge:/root/.titanedge nezha123/titan-edge
    
    echo -e "${YELLOW}Please enter your node identity code:${NC}"
    read identity_code
    
    docker run --rm -it -v ~/.titanedge:/root/.titanedge nezha123/titan-edge bind --hash="$identity_code" https://api-test1.container1.titannet.io/api/v2/device/binding
}

# Function to display node logs
show_logs() {
    echo -e "${BLUE}Displaying node logs...${NC}"
    docker logs -f titan
}

# Function to cleanup node
remove_node() {
    echo -e "${RED}Removing Titan node...${NC}"
    docker stop titan 2>/dev/null
    docker rm titan 2>/dev/null
    docker rmi nezha123/titan-edge 2>/dev/null
    rm -rf ~/.titanedge 2>/dev/null
    echo -e "${GREEN}Cleanup completed${NC}"
}

# Main execution flow
check_dependencies

echo -e "${PURPLE}#########################################${NC}"
echo -e "${CYAN}    Titan Node Management Script${NC}"
echo -e "${PURPLE}#########################################${NC}"
echo -e "${YELLOW}1) Install and setup node${NC}"
echo -e "${YELLOW}2) Check for updates${NC}"
echo -e "${YELLOW}3) Monitor node logs${NC}"
echo -e "${YELLOW}4) Restart node service${NC}"
echo -e "${YELLOW}5) Remove node completely${NC}"
echo -e "${PURPLE}#########################################${NC}"

read -p "Select option [1-5]: " user_choice

case $user_choice in
    1)
        setup_docker
        setup_docker_compose
        setup_permissions
        deploy_titan
        echo -e "${GREEN}Node installation completed!${NC}"
        echo -e "${YELLOW}To check logs later: docker logs -f titan${NC}"
        ;;
    2)
        echo -e "${GREEN}Node is running latest version${NC}"
        ;;
    3)
        show_logs
        ;;
    4)
        echo -e "${BLUE}Restarting node...${NC}"
        docker restart titan
        sleep 3
        show_logs
        ;;
    5)
        remove_node
        ;;
    *)
        echo -e "${RED}Invalid selection${NC}"
        exit 1
        ;;
esac

echo -e "${PURPLE}#########################################${NC}"
echo -e "${CYAN}Operation completed${NC}"
