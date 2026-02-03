#!/bin/bash

#═══════════════════════════════════════════════════════════════════
# Vadmin Mini Tunnel - Quick Setup
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
    echo "║        Vadmin Mini Tunnel - Quick Setup                   ║"
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
        echo "  sudo bash vadmin-mini-tunnel.sh"
        exit 1
    fi
}

# Validate IP
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Setup External Server (Kharej)
setup_external() {
    print_header
    echo ""
    print_info "Tanzim Server Kharej..."
    echo ""
    
    # Get Iran IP
    while true; do
        read -p "IP server Iran ra vared konid: " IRAN_IP
        if validate_ip "$IRAN_IP"; then
            break
        else
            print_error "IP namotabar ast! Lotfan dobare talash konid."
        fi
    done
    
    # Get External IP
    while true; do
        read -p "IP server Kharej ra vared konid: " EXTERNAL_IP
        if validate_ip "$EXTERNAL_IP"; then
            break
        else
            print_error "IP namotabar ast! Lotfan dobare talash konid."
        fi
    done
    
    echo ""
    print_info "Dar hal tanzim tunnel..."
    
    # Setup tunnel
    modprobe sit
    ip tunnel add sit1 mode sit local "$EXTERNAL_IP" remote "$IRAN_IP" ttl 255
    ip link set sit1 up
    ip addr add fd00::2/64 dev sit1
    ip link set sit1 mtu 1480
    
    print_success "Tunnel ba movafaqiat tanzim shod!"
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}  Etelaat Tunnel:                                          ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  ─────────────────────                                    ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  IP Kharej: ${YELLOW}$EXTERNAL_IP${NC}                                  ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  IP Iran: ${YELLOW}$IRAN_IP${NC}                                        ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  IPv6 Kharej: ${YELLOW}fd00::2${NC}                                     ${GREEN}║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Setup Iran Server
setup_iran() {
    print_header
    echo ""
    print_info "Tanzim Server Iran..."
    echo ""
    
    # Get Iran IP
    while true; do
        read -p "IP server Iran ra vared konid: " IRAN_IP
        if validate_ip "$IRAN_IP"; then
            break
        else
            print_error "IP namotabar ast! Lotfan dobare talash konid."
        fi
    done
    
    # Get External IP
    while true; do
        read -p "IP server Kharej ra vared konid: " EXTERNAL_IP
        if validate_ip "$EXTERNAL_IP"; then
            break
        else
            print_error "IP namotabar ast! Lotfan dobare talash konid."
        fi
    done
    
    echo ""
    print_info "Dar hal tanzim tunnel..."
    
    # Setup tunnel
    modprobe sit
    ip tunnel add sit1 mode sit local "$IRAN_IP" remote "$EXTERNAL_IP" ttl 255
    ip link set sit1 up
    ip addr add fd00::1/64 dev sit1
    ip link set sit1 mtu 1480
    
    print_success "Tunnel ba movafaqiat tanzim shod!"
    echo ""
    
    # Install HAProxy
    print_info "Dar hal nasb HAProxy..."
    apt update -qq
    apt install haproxy -y -qq
    print_success "HAProxy nasb shod!"
    echo ""
    
    # Get number of ports
    while true; do
        read -p "Chand ta port config darid? " PORT_COUNT
        if [[ "$PORT_COUNT" =~ ^[0-9]+$ ]] && [ "$PORT_COUNT" -gt 0 ]; then
            break
        else
            print_error "Lotfan yek adad motabar vared konid!"
        fi
    done
    
    # Get ports
    declare -a PORTS
    echo ""
    for ((i=1; i<=PORT_COUNT; i++)); do
        while true; do
            read -p "Port $i ra vared konid: " PORT
            if [[ "$PORT" =~ ^[0-9]+$ ]] && [ "$PORT" -ge 1 ] && [ "$PORT" -le 65535 ]; then
                PORTS+=("$PORT")
                break
            else
                print_error "Port namotabar! (1-65535)"
            fi
        done
    done
    
    echo ""
    print_info "Dar hal tanzim HAProxy..."
    
    # Generate HAProxy config
    cat > /etc/haproxy/haproxy.cfg << EOF
global
    maxconn 4096
    daemon
    user haproxy
    group haproxy

defaults
    mode tcp
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms


# Frontends
EOF

    # Add frontends
    for PORT in "${PORTS[@]}"; do
        cat >> /etc/haproxy/haproxy.cfg << EOF
frontend ${PORT}in
    bind *:${PORT}
    use_backend ${PORT}out
EOF
    done

    # Add backends section
    cat >> /etc/haproxy/haproxy.cfg << EOF

# Backends
EOF

    # Add backends
    for PORT in "${PORTS[@]}"; do
        cat >> /etc/haproxy/haproxy.cfg << EOF
backend ${PORT}out
    server tunnel fd00::2:${PORT}
EOF
    done
    
    # Restart HAProxy
    systemctl restart haproxy
    systemctl enable haproxy
    
    print_success "HAProxy ba movafaqiat tanzim shod!"
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}  Etelaat Tunnel:                                          ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  ─────────────────────                                    ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  IP Iran: ${YELLOW}$IRAN_IP${NC}                                        ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  IP Kharej: ${YELLOW}$EXTERNAL_IP${NC}                                  ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  IPv6 Iran: ${YELLOW}fd00::1${NC}                                       ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}                                                           ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  Port haye tunnel shode:                                  ${GREEN}║${NC}"
    for PORT in "${PORTS[@]}"; do
        echo -e "${GREEN}║${NC}    • ${YELLOW}${PORT}${NC}                                                    ${GREEN}║${NC}"
    done
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Main menu
show_menu() {
    print_header
    
    echo ""
    echo "Server shoma dar koja gharar darad?"
    echo ""
    echo -e "${YELLOW}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║${NC}                                                           ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}  ${GREEN}[1]${NC} Server Kharej (External Server)                      ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}                                                           ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}  ${GREEN}[2]${NC} Server Iran (Iran Server)                            ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}                                                           ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}  ${BLUE}[0]${NC} Khorooj (Exit)                                       ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}                                                           ${YELLOW}║${NC}"
    echo -e "${YELLOW}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    read -p "Entekhab shoma [0-2]: " choice
    
    case $choice in
        1)
            setup_external
            ;;
        2)
            setup_iran
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
