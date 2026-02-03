#!/bin/bash

#═══════════════════════════════════════════════════════════════════
# Hysteria2 Tunnel Installer - Main Menu
# Repository: https://github.com/agbeast98/vadmin-tunnels
# Version: 1.0
#═══════════════════════════════════════════════════════════════════

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Paths
REPO_URL="https://raw.githubusercontent.com/agbeast98/vadmin-tunnels/main"

# Functions
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_header() {
    clear
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                                                           ║"
    echo "║        Hysteria2 Tunnel Installer v1.0                    ║"
    echo "║        github.com/agbeast98/vadmin-tunnels                ║"
    echo "║                                                           ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Check root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "In script bayad ba dastresi root ejra shavad!"
        echo ""
        echo "Lotfan dobare ba sudo ejra konid:"
        echo "  sudo bash install.sh"
        exit 1
    fi
}

# Download and run script
run_script() {
    local script_name=$1
    local script_url="${REPO_URL}/${script_name}"
    
    print_info "Dar hal download script..."
    
    if curl -fsSL "$script_url" -o "/tmp/${script_name}"; then
        chmod +x "/tmp/${script_name}"
        bash "/tmp/${script_name}"
        rm -f "/tmp/${script_name}"
    else
        print_error "Khata dar download script!"
        echo ""
        echo "Lotfan ettesal internet khod ra barresi konid."
        exit 1
    fi
}

# Main menu
show_menu() {
    print_header
    
    echo ""
    echo "Lotfan yeki az gozine-haye zir ra entekhab konid:"
    echo ""
    echo -e "${YELLOW}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║${NC}                                                           ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}  ${GREEN}[1]${NC} Server Kharej (External Server)                      ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}      └─ Nasb Hysteria2 Server                            ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}                                                           ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}  ${GREEN}[2]${NC} Server Iran (Iran Server)                            ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}      └─ Nasb Hysteria2 Client + HAProxy                  ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}                                                           ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}  ${RED}[3]${NC} Hazf (Uninstall)                                     ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}      └─ Hazf kamel tunnel                                ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}                                                           ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}  ${BLUE}[0]${NC} Khorooj (Exit)                                       ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}                                                           ${YELLOW}║${NC}"
    echo -e "${YELLOW}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    read -p "Entekhab shoma [0-3]: " choice
    
    case $choice in
        1)
            echo ""
            print_info "Shoro nasb server kharej..."
            sleep 1
            run_script "server-install.sh"
            ;;
        2)
            echo ""
            print_info "Shoro nasb server iran..."
            sleep 1
            run_script "client-install.sh"
            ;;
        3)
            echo ""
            print_info "Shoro hazf..."
            sleep 1
            run_script "uninstall.sh"
            ;;
        0)
            echo ""
            print_info "Khorooj az barnameh..."
            exit 0
            ;;
        *)
            echo ""
            print_error "Gozine namotabar! Lotfan dobare talash konid."
            sleep 2
            show_menu
            ;;
    esac
}

# Main
main() {
    check_root
    show_menu
}

main "$@"