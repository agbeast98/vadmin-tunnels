#!/bin/bash

#═══════════════════════════════════════════════════════════════════
# Hysteria2 Client + HAProxy Installation (Iran Server)
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
║    Hysteria2 Client + HAProxy Installation                ║
║    Nasb Server Iran                                       ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Step 1: Check system
print_step "Gham 1/12: Barresi System"

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

IRAN_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s api.ipify.org 2>/dev/null)
if [ -z "$IRAN_IP" ]; then
    print_warning "Nemitavan IP ra tashkhis dad"
    read -p "Lotfan IP server iran ra vared konid: " IRAN_IP
fi
print_success "IP server iran: $IRAN_IP"

# Check previous installation
if [ -f /etc/hysteria/config.yaml ]; then
    print_warning "Hysteria2 Client gablan nasb shode ast"
    echo ""
    echo "[1] Borozresani (Update)"
    echo "[2] Nasb mojadad (Reinstall)"
    echo "[0] Ensraf"
    read -p "Entekhab [0-2]: " reinstall_choice
    
    case $reinstall_choice in
        1) print_info "Edame ba borozresani..." ;;
        2)
            print_info "Hazf nasb gabli..."
            systemctl stop hysteria-client 2>/dev/null || true
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
print_step "Gham 2/12: Nasb va Borozresani Pishniazha"

print_info "Borozresani list package-ha..."
apt-get update -qq >/dev/null 2>&1

install_package "curl"
install_package "wget"
install_package "net-tools"
install_package "haproxy"

print_success "Pishniazha amade ast"

# Step 3: Get information
print_step "Gham 3/12: Daryaft Etelaat Peykarebandi"

echo ""
echo -e "${BLUE}ℹ IP server iran shoma: $IRAN_IP${NC}"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW} Etelaat Server Kharej${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# External server IP
echo "[1/8] IP Server Kharej"
get_input "IP server kharej" "" "EXTERNAL_IP"

# Tunnel port
echo ""
echo "[2/8] Port Tunnel Server Kharej"
get_input "Port" "443" "TUNNEL_PORT"

# Password
echo ""
echo "[3/8] Ramz (az server kharej)"
echo "      In ramz dar /root/hysteria-server-info.txt mojood ast"
get_input "Ramz" "" "PASSWORD"

# SNI
echo ""
echo "[4/8] Fake SNI"
echo "      Bayad daghighan mesle server kharej bashad"
get_input "SNI" "bing.com" "FAKE_SNI"

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW} Port-haye X-UI (roye server kharej)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# X-UI port 1
echo "[5/8] Port X-UI Aval"
get_input "Port" "8080" "XUI_PORT1"

# X-UI port 2
echo ""
echo "[6/8] Port X-UI Dovom"
get_input "Port" "8081" "XUI_PORT2"

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW} Port-haye Omoomi (baraye karbaran)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Public port 1
echo "[7/8] Port Omoomi Aval"
get_input "Port" "2097" "PUBLIC_PORT1"

# Public port 2
echo ""
echo "[8/8] Port Omoomi Dovom"
get_input "Port" "2087" "PUBLIC_PORT2"

# Summary
echo ""
print_step "Kholase Tanzeemat"
echo ""
echo -e "  ${BLUE}Server Iran:${NC}      $IRAN_IP"
echo -e "  ${BLUE}Server Kharej:${NC}    $EXTERNAL_IP:$TUNNEL_PORT"
echo -e "  ${BLUE}Ramz:${NC}             ${PASSWORD:0:30}..."
echo -e "  ${BLUE}SNI:${NC}              $FAKE_SNI"
echo -e "  ${BLUE}Port-haye X-UI:${NC}   $XUI_PORT1, $XUI_PORT2"
echo -e "  ${BLUE}Port-haye Omoomi:${NC} $PUBLIC_PORT1, $PUBLIC_PORT2"
echo ""

read -p "Edame midahid? [Y/n]: " confirm
confirm=${confirm:-Y}
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    print_info "Ensraf"
    exit 0
fi

# Step 4: Download Hysteria2
print_step "Gham 4/12: Download Hysteria2"

if [ -f /usr/local/bin/hysteria ]; then
    print_info "Hysteria2 mojood ast"
else
    print_info "Download Hysteria2..."
    
    # Try direct download
    if wget -q https://github.com/apernet/hysteria/releases/download/app%2Fv2.7.0/hysteria-linux-amd64 -O /usr/local/bin/hysteria 2>/dev/null; then
        print_success "Download az GitHub movafagh bood"
    elif curl -sL https://github.com/apernet/hysteria/releases/download/app%2Fv2.7.0/hysteria-linux-amd64 -o /usr/local/bin/hysteria 2>/dev/null; then
        print_success "Download az GitHub movafagh bood"
    else
        print_error "Download mostaghim namovafagh bood"
        echo ""
        echo "GitHub ehtemaalan filter ast. Lotfan dasti download konid:"
        echo ""
        echo "1. Roye server kharej:"
        echo "   cd /tmp"
        echo "   wget https://github.com/apernet/hysteria/releases/download/app%2Fv2.7.0/hysteria-linux-amd64"
        echo ""
        echo "2. Roye server iran:"
        echo "   scp root@$EXTERNAL_IP:/tmp/hysteria-linux-amd64 /usr/local/bin/hysteria"
        echo "   chmod +x /usr/local/bin/hysteria"
        echo ""
        exit 1
    fi
fi

chmod +x /usr/local/bin/hysteria

if hysteria version >/dev/null 2>&1; then
    HYSTERIA_VERSION=$(hysteria version 2>/dev/null | head -1 || echo "Namoshakhas")
    print_success "Hysteria2: $HYSTERIA_VERSION"
else
    print_error "Hysteria2 nasb nashod"
    exit 1
fi

# Step 5: Create Hysteria config
print_step "Gham 5/12: Sakht Config Hysteria"

mkdir -p /etc/hysteria

cat > /etc/hysteria/config.yaml << EOF
server: $EXTERNAL_IP:$TUNNEL_PORT

auth: $PASSWORD

tls:
  sni: $FAKE_SNI
  insecure: true

bandwidth:
  up: 200 mbps
  down: 200 mbps

socks5:
  listen: 127.0.0.1:1080

tcpForwarding:
  - listen: 127.0.0.1:12097
    remote: $EXTERNAL_IP:$XUI_PORT1
  
  - listen: 127.0.0.1:12087
    remote: $EXTERNAL_IP:$XUI_PORT2
EOF

print_success "Config Hysteria sakhte shod"

# Step 6: Create Hysteria service
print_step "Gham 6/12: Sakht Service Hysteria"

cat > /etc/systemd/system/hysteria-client.service << EOF
[Unit]
Description=Hysteria Client
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/hysteria client --config /etc/hysteria/config.yaml
Restart=always
RestartSec=5
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

print_success "Service Hysteria sakhte shod"

# Step 7: Start Hysteria
print_step "Gham 7/12: Rahandazi Hysteria"

systemctl daemon-reload
systemctl enable hysteria-client >/dev/null 2>&1
systemctl restart hysteria-client

sleep 3

if systemctl is-active --quiet hysteria-client; then
    print_success "Service dar hal ejra ast"
    
    # Check connection
    if journalctl -u hysteria-client -n 10 --no-pager 2>/dev/null | grep -q "connected to server"; then
        print_success "Ettesal be server kharej bargharar shod ✓"
    else
        print_warning "Vaziat ettesal namoshakhas"
    fi
else
    print_error "Service shoro nashod"
    journalctl -u hysteria-client -n 20 --no-pager
    exit 1
fi

# Step 8: Backup HAProxy
print_step "Gham 8/12: Peykarebandi HAProxy"

if [ -f /etc/haproxy/haproxy.cfg ]; then
    print_info "Backup az config HAProxy..."
    cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.backup.$(date +%Y%m%d-%H%M%S)
    print_success "Backup sakhte shod"
fi

# Step 9: Add HAProxy config
print_step "Gham 9/12: Ezafe Kardan Config Tunnel"

# Remove old config if exists
sed -i '/# Hysteria2 Tunnel Configuration/,/^$/d' /etc/haproxy/haproxy.cfg

cat >> /etc/haproxy/haproxy.cfg << EOF

#═══════════════════════════════════════
# Hysteria2 Tunnel Configuration
#═══════════════════════════════════════

frontend vless_$PUBLIC_PORT1
    bind *:$PUBLIC_PORT1
    mode tcp
    default_backend hysteria_$PUBLIC_PORT1

backend hysteria_$PUBLIC_PORT1
    mode tcp
    server hysteria1 127.0.0.1:12097 check

#───────────────────────────────────────

frontend vless_$PUBLIC_PORT2
    bind *:$PUBLIC_PORT2
    mode tcp
    default_backend hysteria_$PUBLIC_PORT2

backend hysteria_$PUBLIC_PORT2
    mode tcp
    server hysteria1 127.0.0.1:12087 check

EOF

print_success "Config HAProxy berooz shod"

# Step 10: Test HAProxy config
print_step "Gham 10/12: Test Config HAProxy"

if haproxy -c -f /etc/haproxy/haproxy.cfg >/dev/null 2>&1; then
    print_success "Config HAProxy motabar ast"
else
    print_error "Config HAProxy motabar nist!"
    haproxy -c -f /etc/haproxy/haproxy.cfg
    exit 1
fi

systemctl restart haproxy

if systemctl is-active --quiet haproxy; then
    print_success "HAProxy dar hal ejra ast"
else
    print_error "HAProxy shoro nashod"
    journalctl -u haproxy -n 20 --no-pager
    exit 1
fi

# Step 11: Configure firewall
print_step "Gham 11/12: Peykarebandi Firewall"

if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q "Status: active"; then
    print_info "Peykarebandi UFW..."
    ufw allow $PUBLIC_PORT1/tcp >/dev/null 2>&1 || true
    ufw allow $PUBLIC_PORT2/tcp >/dev/null 2>&1 || true
    print_success "UFW peykarebandi shod"
elif command -v firewall-cmd >/dev/null 2>&1; then
    print_info "Peykarebandi firewalld..."
    firewall-cmd --permanent --add-port=$PUBLIC_PORT1/tcp >/dev/null 2>&1 || true
    firewall-cmd --permanent --add-port=$PUBLIC_PORT2/tcp >/dev/null 2>&1 || true
    firewall-cmd --reload >/dev/null 2>&1 || true
    print_success "firewalld peykarebandi shod"
else
    print_info "Firewall gheyr-faal ast"
fi

# Step 12: Final test
print_step "Gham 12/12: Test Nahaei"

# Test SOCKS5
print_info "Test SOCKS5..."
sleep 2
TEST_IP=$(timeout 5 curl --socks5 127.0.0.1:1080 -s https://ifconfig.me 2>/dev/null || echo "")

if [ "$TEST_IP" == "$EXTERNAL_IP" ]; then
    print_success "Test SOCKS5: Movafagh ✓ (IP: $TEST_IP)"
else
    print_warning "Test SOCKS5: Namoshakhas"
fi

# Check ports
print_info "Barresi port-ha..."
if netstat -tlpn 2>/dev/null | grep -q ":$PUBLIC_PORT1 "; then
    print_success "Port $PUBLIC_PORT1: Baz ✓"
else
    print_warning "Port $PUBLIC_PORT1: Namoshakhas"
fi

if netstat -tlpn 2>/dev/null | grep -q ":$PUBLIC_PORT2 "; then
    print_success "Port $PUBLIC_PORT2: Baz ✓"
else
    print_warning "Port $PUBLIC_PORT2: Namoshakhas"
fi

# Save information
cat > /root/hysteria-client-info.txt << EOF
═══════════════════════════════════════════════════════════
Hysteria2 Client Information
═══════════════════════════════════════════════════════════
Tarikh Nasb: $(date)

IP Server Iran:    $IRAN_IP
Port Omoomi 1:     $PUBLIC_PORT1
Port Omoomi 2:     $PUBLIC_PORT2

Server Kharej:     $EXTERNAL_IP:$TUNNEL_PORT

File-ha:
  Config Hysteria: /etc/hysteria/config.yaml
  Config HAProxy:  /etc/haproxy/haproxy.cfg
  Service Hysteria: /etc/systemd/system/hysteria-client.service

Dastorat Mofid:
  systemctl status hysteria-client haproxy
  journalctl -u hysteria-client -f
  journalctl -u haproxy -f
  curl --socks5 127.0.0.1:1080 ifconfig.me
  netstat -tlpn | grep -E "$PUBLIC_PORT1|$PUBLIC_PORT2"
  
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
echo -e "${YELLOW}📋 Etelaat Server Iran:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  ${BLUE}IP Server Iran:${NC}    $IRAN_IP"
echo -e "  ${BLUE}Port Omoomi 1:${NC}     $PUBLIC_PORT1"
echo -e "  ${BLUE}Port Omoomi 2:${NC}     $PUBLIC_PORT2"
echo ""
echo -e "  ${BLUE}Ettesal Be:${NC}        $EXTERNAL_IP:$TUNNEL_PORT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${YELLOW}👥 Etelaat Baraye Karbaran:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  ${GREEN}Server:${NC}  $IRAN_IP"
echo -e "  ${GREEN}Port 1:${NC}  $PUBLIC_PORT1"
echo -e "  ${GREEN}Port 2:${NC}  $PUBLIC_PORT2"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}📝 Etelaat zakhire shod dar:${NC} /root/hysteria-client-info.txt"
echo ""
echo -e "${CYAN}🔧 Dastorat Modiriyat:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${BLUE}[Check Vaziat]${NC}"
echo "  systemctl status hysteria-client"
echo "  systemctl status haproxy"
echo ""
echo -e "${BLUE}[Check Log Zende]${NC}"
echo "  journalctl -u hysteria-client -f"
echo "  journalctl -u haproxy -f"
echo ""
echo -e "${BLUE}[Test Ettesal SOCKS5]${NC}"
echo "  curl --socks5 127.0.0.1:1080 ifconfig.me"
echo "  # Bayad IP server kharej ($EXTERNAL_IP) neshan bedahad"
echo ""
echo -e "${BLUE}[Check Port-ha]${NC}"
echo "  netstat -tlpn | grep -E '$PUBLIC_PORT1|$PUBLIC_PORT2'"
echo ""
echo -e "${BLUE}[Restart Service-ha]${NC}"
echo "  systemctl restart hysteria-client"
echo "  systemctl restart haproxy"
echo ""
echo -e "${BLUE}[Moshahede Config]${NC}"
echo "  cat /etc/hysteria/config.yaml"
echo "  cat /etc/haproxy/haproxy.cfg"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""