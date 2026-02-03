#!/bin/bash

#═══════════════════════════════════════════════════════════════════
# Hysteria2 Tunnel Uninstaller
# Repository: https://github.com/agbeast98/vadmin-tunnels
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
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }

# Banner
clear
echo -e "${RED}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║         Hysteria2 Tunnel Uninstaller                      ║
║         Hazf Kamel Tunnel                                 ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Check root
if [[ $EUID -ne 0 ]]; then
    print_error "In script bayad ba root ejra shavad"
    exit 1
fi

echo ""
print_warning "⚠️  Hoshdar: In amaliyat tamam tanzeemat ra hazf mikonad!"
echo ""
echo "Noe server ra entekhab konid:"
echo ""
echo -e "${YELLOW}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║${NC}                                                           ${YELLOW}║${NC}"
echo -e "${YELLOW}║${NC}  ${GREEN}[1]${NC} Server Kharej (External Server)                      ${YELLOW}║${NC}"
echo -e "${YELLOW}║${NC}      └─ Hazf Hysteria2 Server                            ${YELLOW}║${NC}"
echo -e "${YELLOW}║${NC}                                                           ${YELLOW}║${NC}"
echo -e "${YELLOW}║${NC}  ${GREEN}[2]${NC} Server Iran (Iran Server)                            ${YELLOW}║${NC}"
echo -e "${YELLOW}║${NC}      └─ Hazf Hysteria2 Client + HAProxy                  ${YELLOW}║${NC}"
echo -e "${YELLOW}║${NC}                                                           ${YELLOW}║${NC}"
echo -e "${YELLOW}║${NC}  ${BLUE}[0]${NC} Ensraf (Cancel)                                      ${YELLOW}║${NC}"
echo -e "${YELLOW}║${NC}                                                           ${YELLOW}║${NC}"
echo -e "${YELLOW}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

read -p "Entekhab shoma [0-2]: " choice

case $choice in
    1)
        # Uninstall external server
        echo ""
        print_warning "Hazf Hysteria2 Server..."
        echo ""
        read -p "Aya motmaen hastid? [y/N]: " confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            print_info "Ensraf"
            exit 0
        fi
        
        echo ""
        print_info "Shoro hazf server kharej..."
        
        # Stop service
        if systemctl is-active --quiet hysteria-server 2>/dev/null; then
            print_info "Toghf service..."
            systemctl stop hysteria-server
            print_success "Service motoghef shod"
        fi
        
        # Disable service
        if systemctl is-enabled --quiet hysteria-server 2>/dev/null; then
            systemctl disable hysteria-server >/dev/null 2>&1
            print_success "Service gheyr-faal shod"
        fi
        
        # Remove service file
        if [ -f /etc/systemd/system/hysteria-server.service ]; then
            rm -f /etc/systemd/system/hysteria-server.service
            print_success "File service hazf shod"
        fi
        
        # Reload systemd
        systemctl daemon-reload
        
        # Remove config files
        if [ -d /etc/hysteria ]; then
            rm -rf /etc/hysteria
            print_success "File-haye config hazf shod"
        fi
        
        # Remove binary
        if [ -f /usr/local/bin/hysteria ]; then
            rm -f /usr/local/bin/hysteria
            print_success "Binary hazf shod"
        fi
        
        # Remove info file
        if [ -f /root/hysteria-server-info.txt ]; then
            rm -f /root/hysteria-server-info.txt
            print_success "File etelaat hazf shod"
        fi
        
        # Remove firewall rules
        print_info "Paksazi Firewall..."
        if command -v ufw >/dev/null 2>&1; then
            # Only common ports
            for port in 443 53 8443 36712; do
                ufw delete allow $port/udp 2>/dev/null || true
            done
        fi
        
        echo ""
        print_success "✅ Hazf server kharej kamel shod!"
        ;;
        
    2)
        # Uninstall Iran server
        echo ""
        print_warning "Hazf Hysteria2 Client + HAProxy..."
        echo ""
        read -p "Aya motmaen hastid? [y/N]: " confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            print_info "Ensraf"
            exit 0
        fi
        
        echo ""
        print_info "Shoro hazf server iran..."
        
        # Stop services
        if systemctl is-active --quiet hysteria-client 2>/dev/null; then
            print_info "Toghf Hysteria Client..."
            systemctl stop hysteria-client
            print_success "Hysteria Client motoghef shod"
        fi
        
        # Disable service
        if systemctl is-enabled --quiet hysteria-client 2>/dev/null; then
            systemctl disable hysteria-client >/dev/null 2>&1
            print_success "Hysteria Client gheyr-faal shod"
        fi
        
        # Remove service file
        if [ -f /etc/systemd/system/hysteria-client.service ]; then
            rm -f /etc/systemd/system/hysteria-client.service
            print_success "File service hazf shod"
        fi
        
        # Reload systemd
        systemctl daemon-reload
        
        # Remove Hysteria config files
        if [ -d /etc/hysteria ]; then
            rm -rf /etc/hysteria
            print_success "File-haye config Hysteria hazf shod"
        fi
        
        # Remove binary
        if [ -f /usr/local/bin/hysteria ]; then
            rm -f /usr/local/bin/hysteria
            print_success "Binary Hysteria hazf shod"
        fi
        
        # Restore HAProxy
        print_info "Bazgardani HAProxy..."
        
        # Remove tunnel config from HAProxy
        if [ -f /etc/haproxy/haproxy.cfg ]; then
            # Find latest backup
            LATEST_BACKUP=$(ls -t /etc/haproxy/haproxy.cfg.backup.* 2>/dev/null | head -1)
            
            if [ -n "$LATEST_BACKUP" ]; then
                print_info "Bazgardani az backup..."
                cp "$LATEST_BACKUP" /etc/haproxy/haproxy.cfg
                print_success "HAProxy az backup bazgardani shod"
            else
                # Manual removal of tunnel section
                sed -i '/# Hysteria2 Tunnel Configuration/,/^$/d' /etc/haproxy/haproxy.cfg
                print_success "Config tunnel az HAProxy hazf shod"
            fi
            
            # Restart HAProxy
            systemctl restart haproxy
            print_success "HAProxy rahandazi mojadad shod"
        fi
        
        # Remove info file
        if [ -f /root/hysteria-client-info.txt ]; then
            rm -f /root/hysteria-client-info.txt
            print_success "File etelaat hazf shod"
        fi
        
        echo ""
        print_success "✅ Hazf server iran kamel shod!"
        echo ""
        print_info "HAProxy hamchenan nasb ast va sayer tanzeemat an hefz shode ast"
        ;;
        
    0)
        print_info "Ensraf"
        exit 0
        ;;
        
    *)
        print_error "Gozine namotabar!"
        exit 1
        ;;
esac

echo ""