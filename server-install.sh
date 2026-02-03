#!/bin/bash

#═══════════════════════════════════════════════════════════════════
# Hysteria2 Server Installation (External Server)
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

print_step() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN} $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Check and install/update package
install_package() {
    local package=$1
    
    if dpkg -l | grep -q "^ii  $package "; then
        print_success "$package mojood ast"
        apt-get install --only-upgrade -y $package >/dev/null 2>&1 || true
    else
        print_info "Nasb $package..."
        if apt-get install -y $package >/dev/null 2>&1; then
            print_success "$package nasb shod"
        else
            print_error "Khata dar nasb $package"
            return 1
        fi
    fi
}

# Get input with default
get_input() {
    local prompt=$1
    local default=$2
    local var_name=$3
    
    if [ -n "$default" ]; then
        read -p "$prompt [Pishfarz: $default]: " input
        input=${input:-$default}
    else
        while true; do
            read -p "$prompt: " input
            if [ -n "$input" ]; then
                break
            fi
            print_error "In field nemitavanad khali bashad!"
        done
    fi
    
    eval $var_name="'$input'"
}

# Banner
clear
echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║         Hysteria2 Server Installation                     ║
║         Nasb Server Kharej                                ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Step 1: Check system
print_step "Gham 1/8: Barresi System"

if [[ $EUID -ne 0 ]]; then
    print_error "In script bayad ba root ejra shavad"
    exit 1
fi
print_success "Dastresi root: OK"

if [ -f /etc/os-release ]; then
    . /etc/os-release
    print_success "System amel: $ID $VERSION_ID"
else
    print_error "Nemitavan system amel ra tashkhis dad"
    exit 1
fi

SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s api.ipify.org 2>/dev/null)
if [ -z "$SERVER_IP" ]; then
    print_warning "Nemitavan IP ra tashkhis dad"
    read -p "Lotfan IP server kharej ra vared konid: " SERVER_IP
fi
print_success "IP server: $SERVER_IP"

# Check previous installation
if [ -f /etc/hysteria/config.yaml ]; then
    print_warning "Hysteria2 gablan nasb shode ast"
    echo ""
    echo "[1] Borozresani (Update)"
    echo "[2] Nasb mojadad (Reinstall)"
    echo "[0] Ensraf"
    read -p "Entekhab [0-2]: " reinstall_choice
    
    case $reinstall_choice in
        1) print_info "Edame ba borozresani..." ;;
        2)
            print_info "Hazf nasb gabli..."
            systemctl stop hysteria-server 2>/dev/null || true
            rm -rf /etc/hysteria
            print_success "Hazf shod"
            ;;
        *)
            print_info "Ensraf"
            exit 0
            ;;
    esac
fi

# Step 2: Install prerequisites
print_step "Gham 2/8: Nasb va Borozresani Pishniazha"

print_info "Borozresani list package-ha..."
apt-get update -qq >/dev/null 2>&1

install_package "curl"
install_package "wget"
install_package "openssl"
install_package "net-tools"

print_success "Pishniazha amade ast"

# Step 3: Get information
print_step "Gham 3/8: Daryaft Etelaat Peykarebandi"

echo ""
echo -e "${BLUE}ℹ IP server shoma: $SERVER_IP${NC}"
echo ""

# Tunnel port
echo "[1/4] Port Tunnel (UDP)"
echo "      Pishnehadi: 443 (Kamtar filter mishavad)"
get_input "Port" "443" "TUNNEL_PORT"

# Generate password
echo ""
echo "[2/4] Tolid Ramz"
print_info "Dar hal tolid ramz amn..."
PASSWORD=$(openssl rand -base64 32)
print_success "Ramz tolid shod"

# SNI
echo ""
echo "[3/4] Domain Fake SNI"
echo "      Pishnehadi: microsoft.com, bing.com, cloudflare.com"
get_input "SNI" "bing.com" "FAKE_SNI"

# Bandwidth
echo ""
echo "[4/4] Mahdoodiyat Sorat"
get_input "Bandwidth" "1 gbps" "BANDWIDTH"

# Summary
echo ""
print_step "Kholase Tanzeemat"
echo ""
echo -e "  ${BLUE}IP Server:${NC}     $SERVER_IP"
echo -e "  ${BLUE}Port Tunnel:${NC}   $TUNNEL_PORT (UDP)"
echo -e "  ${BLUE}Ramz:${NC}          ${PASSWORD:0:30}..."
echo -e "  ${BLUE}SNI:${NC}           $FAKE_SNI"
echo -e "  ${BLUE}Bandwidth:${NC}     $BANDWIDTH"
echo ""

read -p "Edame midahid? [Y/n]: " confirm
confirm=${confirm:-Y}
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    print_info "Ensraf"
    exit 0
fi

# Step 4: Install Hysteria2
print_step "Gham 4/8: Nasb Hysteria2"

if [ -f /usr/local/bin/hysteria ]; then
    print_info "Borozresani Hysteria2..."
else
    print_info "Nasb Hysteria2..."
fi

if bash <(curl -fsSL https://get.hy2.sh/) >/dev/null 2>&1; then
    HYSTERIA_VERSION=$(hysteria version 2>/dev/null | head -1 || echo "Namoshakhas")
    print_success "Hysteria2: $HYSTERIA_VERSION"
else
    print_error "Khata dar nasb Hysteria2"
    exit 1
fi

# Step 5: Generate certificate
print_step "Gham 5/8: Sakht Certificate"

mkdir -p /etc/hysteria

print_info "Tolid Certificate..."
openssl req -x509 -nodes -days 36500 -newkey rsa:2048 \
    -keyout /etc/hysteria/server.key \
    -out /etc/hysteria/server.crt \
    -subj "/CN=$FAKE_SNI" >/dev/null 2>&1

chmod 600 /etc/hysteria/server.key
print_success "Certificate sakhte shod"

# Step 6: Create config
print_step "Gham 6/8: Sakht File Config"

cat > /etc/hysteria/config.yaml << EOF
listen: 0.0.0.0:$TUNNEL_PORT

tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key

auth:
  type: password
  password: $PASSWORD

masquerade:
  type: proxy
  proxy:
    url: https://www.$FAKE_SNI
    rewriteHost: true

quic:
  initStreamReceiveWindow: 26843545
  maxStreamReceiveWindow: 26843545
  initConnReceiveWindow: 67108864
  maxConnReceiveWindow: 67108864

bandwidth:
  up: $BANDWIDTH
  down: $BANDWIDTH
EOF

print_success "File config sakhte shod"

# Step 7: Create and start service
print_step "Gham 7/8: Rahandazi Service"

cat > /etc/systemd/system/hysteria-server.service << EOF
[Unit]
Description=Hysteria Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/hysteria server --config /etc/hysteria/config.yaml
Restart=always
RestartSec=5
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable hysteria-server >/dev/null 2>&1
systemctl restart hysteria-server

sleep 2

if systemctl is-active --quiet hysteria-server; then
    print_success "Service dar hal ejra ast"
else
    print_error "Service shoro nashod"
    journalctl -u hysteria-server -n 20 --no-pager
    exit 1
fi

# Step 8: Configure firewall
print_step "Gham 8/8: Peykarebandi Firewall"

if command -v ufw >/dev/null 2>&1; then
    print_info "Peykarebandi UFW..."
    ufw allow $TUNNEL_PORT/udp >/dev/null 2>&1 || true
    print_success "UFW peykarebandi shod"
elif command -v firewall-cmd >/dev/null 2>&1; then
    print_info "Peykarebandi firewalld..."
    firewall-cmd --permanent --add-port=$TUNNEL_PORT/udp >/dev/null 2>&1 || true
    firewall-cmd --reload >/dev/null 2>&1 || true
    print_success "firewalld peykarebandi shod"
else
    print_warning "Firewall yaft nashod - dasti peykarebandi konid"
fi

# Save information
cat > /root/hysteria-server-info.txt << EOF
═══════════════════════════════════════════════════════════
Hysteria2 Server Information
═══════════════════════════════════════════════════════════
Tarikh Nasb: $(date)

IP Server:     $SERVER_IP
Port Tunnel:   $TUNNEL_PORT (UDP)
Ramz:          $PASSWORD
SNI:           $FAKE_SNI
Bandwidth:     $BANDWIDTH

File-ha:
  Config:      /etc/hysteria/config.yaml
  Certificate: /etc/hysteria/server.crt
  Service:     /etc/systemd/system/hysteria-server.service

Dastorat Mofid:
  systemctl status hysteria-server
  journalctl -u hysteria-server -f
  systemctl restart hysteria-server
  netstat -ulpn | grep $TUNNEL_PORT
  
═══════════════════════════════════════════════════════════
EOF

# Final display
clear
echo -e "${GREEN}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║              🎉 Nasb Ba Movafaghiat Kamel Shod! 🎉        ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${YELLOW}📋 Etelaat Server Kharej:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  ${BLUE}IP Server:${NC}     $SERVER_IP"
echo -e "  ${BLUE}Port Tunnel:${NC}   $TUNNEL_PORT (UDP)"
echo -e "  ${BLUE}Ramz:${NC}          $PASSWORD"
echo -e "  ${BLUE}SNI:${NC}           $FAKE_SNI"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${YELLOW}⚠️  In etelaat ra yaddasht konid!${NC}"
echo -e "${YELLOW}⚠️  Baraye nasb server iran be in etelaat niaz darid${NC}"
echo ""
echo -e "${GREEN}📝 Etelaat zakhire shod dar:${NC} /root/hysteria-server-info.txt"
echo ""
echo -e "${CYAN}🔧 Dastorat Modiriyat:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${BLUE}[Check Vaziat]${NC}"
echo "  systemctl status hysteria-server"
echo ""
echo -e "${BLUE}[Check Log Zende]${NC}"
echo "  journalctl -u hysteria-server -f"
echo ""
echo -e "${BLUE}[Moshahede 50 Khat Akhar Log]${NC}"
echo "  journalctl -u hysteria-server -n 50"
echo ""
echo -e "${BLUE}[Restart Service]${NC}"
echo "  systemctl restart hysteria-server"
echo ""
echo -e "${BLUE}[Stop Service]${NC}"
echo "  systemctl stop hysteria-server"
echo ""
echo -e "${BLUE}[Check Port]${NC}"
echo "  netstat -ulpn | grep $TUNNEL_PORT"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${YELLOW}➡️  Marhale Bad: Nasb Client roye Server Iran${NC}"
echo ""
echo "  Baraye nasb server iran in dastor ra ejra konid:"
echo -e "  ${GREEN}bash <(curl -Ls https://raw.githubusercontent.com/agbeast98/vadmin-tunnels/main/install.sh)${NC}"
echo ""
echo "  Va gozine [2] ra entekhab konid."
echo ""