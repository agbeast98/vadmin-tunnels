#!/bin/bash

#═══════════════════════════════════════════════════════════════════
# Hysteria2 Server Installation (External Server)
# Repository: https://github.com/agbeast98/vadmin-tunnels
#═══════════════════════════════════════════════════════════════════

set -e

# رنگ‌ها
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# توابع
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

# چک و نصب/بروزرسانی پکیج
install_package() {
    local package=$1
    
    if dpkg -l | grep -q "^ii  $package "; then
        print_success "$package موجود است"
        # بروزرسانی
        apt-get install --only-upgrade -y $package >/dev/null 2>&1 || true
    else
        print_info "نصب $package..."
        if apt-get install -y $package >/dev/null 2>&1; then
            print_success "$package نصب شد"
        else
            print_error "خطا در نصب $package"
            return 1
        fi
    fi
}

# دریافت ورودی با default
get_input() {
    local prompt=$1
    local default=$2
    local var_name=$3
    
    if [ -n "$default" ]; then
        read -p "$prompt [پیش‌فرض: $default]: " input
        input=${input:-$default}
    else
        while true; do
            read -p "$prompt: " input
            if [ -n "$input" ]; then
                break
            fi
            print_error "این فیلد نمی‌تواند خالی باشد!"
        done
    fi
    
    eval $var_name="'$input'"
}

# بنر
clear
echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║         Hysteria2 Server Installation                     ║
║         نصب سرور خارج                                    ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# قدم 1: بررسی سیستم
print_step "قدم 1/8: بررسی سیستم"

if [[ $EUID -ne 0 ]]; then
    print_error "این اسکریپت باید با root اجرا شود"
    exit 1
fi
print_success "دسترسی root: OK"

if [ -f /etc/os-release ]; then
    . /etc/os-release
    print_success "سیستم عامل: $ID $VERSION_ID"
else
    print_error "نمی‌توان سیستم عامل را تشخیص داد"
    exit 1
fi

SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s api.ipify.org 2>/dev/null)
if [ -z "$SERVER_IP" ]; then
    print_warning "نمی‌توان IP را تشخیص داد"
    read -p "لطفاً IP سرور خارج را وارد کنید: " SERVER_IP
fi
print_success "IP سرور: $SERVER_IP"

# بررسی نصب قبلی
if [ -f /etc/hysteria/config.yaml ]; then
    print_warning "Hysteria2 قبلاً نصب شده است"
    echo ""
    echo "[1] بروزرسانی (Update)"
    echo "[2] نصب مجدد (Reinstall)"  
    echo "[0] انصراف"
    read -p "انتخاب [0-2]: " reinstall_choice
    
    case $reinstall_choice in
        1) print_info "ادامه با بروزرسانی..." ;;
        2) 
            print_info "حذف نصب قبلی..."
            systemctl stop hysteria-server 2>/dev/null || true
            rm -rf /etc/hysteria
            print_success "حذف شد"
            ;;
        *) 
            print_info "انصراف"
            exit 0
            ;;
    esac
fi

# قدم 2: نصب پیشنیازها
print_step "قدم 2/8: نصب و بروزرسانی پیشنیازها"

print_info "بروزرسانی لیست پکیج‌ها..."
apt-get update -qq >/dev/null 2>&1

install_package "curl"
install_package "wget"
install_package "openssl"
install_package "net-tools"

print_success "پیشنیازها آماده است"

# قدم 3: دریافت اطلاعات
print_step "قدم 3/8: دریافت اطلاعات پیکربندی"

echo ""
echo -e "${BLUE}ℹ IP سرور شما: $SERVER_IP${NC}"
echo ""

# پورت تانل
echo "[1/4] پورت تانل (UDP)"
echo "      پیشنهادی: 443 (کمتر فیلتر می‌شود)"
get_input "پورت" "443" "TUNNEL_PORT"

# تولید رمز خودکار
echo ""
echo "[2/4] تولید رمز"
print_info "در حال تولید رمز امن..."
PASSWORD=$(openssl rand -base64 32)
print_success "رمز تولید شد"

# SNI
echo ""
echo "[3/4] دامنه Fake SNI"
echo "      پیشنهادی: microsoft.com, bing.com, cloudflare.com"
get_input "SNI" "bing.com" "FAKE_SNI"

# Bandwidth
echo ""
echo "[4/4] محدودیت سرعت"
get_input "Bandwidth" "1 gbps" "BANDWIDTH"

# خلاصه
echo ""
print_step "خلاصه تنظیمات"
echo ""
echo -e "  ${BLUE}IP سرور:${NC}     $SERVER_IP"
echo -e "  ${BLUE}پورت تانل:${NC}   $TUNNEL_PORT (UDP)"
echo -e "  ${BLUE}رمز:${NC}          ${PASSWORD:0:30}..."
echo -e "  ${BLUE}SNI:${NC}          $FAKE_SNI"
echo -e "  ${BLUE}Bandwidth:${NC}    $BANDWIDTH"
echo ""

read -p "ادامه می‌دهید؟ [Y/n]: " confirm
confirm=${confirm:-Y}
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    print_info "انصراف"
    exit 0
fi

# قدم 4: نصب Hysteria2
print_step "قدم 4/8: نصب Hysteria2"

if [ -f /usr/local/bin/hysteria ]; then
    print_info "بروزرسانی Hysteria2..."
else
    print_info "نصب Hysteria2..."
fi

if bash <(curl -fsSL https://get.hy2.sh/) >/dev/null 2>&1; then
    HYSTERIA_VERSION=$(hysteria version 2>/dev/null | head -1 || echo "نامشخص")
    print_success "Hysteria2: $HYSTERIA_VERSION"
else
    print_error "خطا در نصب Hysteria2"
    exit 1
fi

# قدم 5: ساخت Certificate
print_step "قدم 5/8: ساخت Certificate"

mkdir -p /etc/hysteria

print_info "تولید Certificate..."
openssl req -x509 -nodes -days 36500 -newkey rsa:2048 \
    -keyout /etc/hysteria/server.key \
    -out /etc/hysteria/server.crt \
    -subj "/CN=$FAKE_SNI" >/dev/null 2>&1

chmod 600 /etc/hysteria/server.key
print_success "Certificate ساخته شد"

# قدم 6: ساخت کانفیگ
print_step "قدم 6/8: ساخت فایل کانفیگ"

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

print_success "فایل کانفیگ ساخته شد"

# قدم 7: ساخت و راه‌اندازی Service
print_step "قدم 7/8: راه‌اندازی Service"

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
    print_success "Service در حال اجرا است"
else
    print_error "Service شروع نشد"
    journalctl -u hysteria-server -n 20 --no-pager
    exit 1
fi

# قدم 8: پیکربندی Firewall
print_step "قدم 8/8: پیکربندی Firewall"

if command -v ufw >/dev/null 2>&1; then
    print_info "پیکربندی UFW..."
    ufw allow $TUNNEL_PORT/udp >/dev/null 2>&1 || true
    print_success "UFW پیکربندی شد"
elif command -v firewall-cmd >/dev/null 2>&1; then
    print_info "پیکربندی firewalld..."
    firewall-cmd --permanent --add-port=$TUNNEL_PORT/udp >/dev/null 2>&1 || true
    firewall-cmd --reload >/dev/null 2>&1 || true
    print_success "firewalld پیکربندی شد"
else
    print_warning "Firewall یافت نشد - دستی پیکربندی کنید"
fi

# ذخیره اطلاعات
cat > /root/hysteria-server-info.txt << EOF
═══════════════════════════════════════════════════════════
Hysteria2 Server Information
═══════════════════════════════════════════════════════════
تاریخ نصب: $(date)

IP سرور:     $SERVER_IP
پورت تانل:   $TUNNEL_PORT (UDP)
رمز:          $PASSWORD
SNI:          $FAKE_SNI
Bandwidth:    $BANDWIDTH

فایل‌ها:
  کانفیگ:     /etc/hysteria/config.yaml
  Certificate: /etc/hysteria/server.crt
  Service:     /etc/systemd/system/hysteria-server.service

دستورات مفید:
  systemctl status hysteria-server
  journalctl -u hysteria-server -f
  systemctl restart hysteria-server
  netstat -ulpn | grep $TUNNEL_PORT
  
═══════════════════════════════════════════════════════════
EOF

# نمایش نهایی
clear
echo -e "${GREEN}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║              🎉 نصب با موفقیت کامل شد! 🎉                 ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${YELLOW}📋 اطلاعات سرور خارج:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  ${BLUE}IP سرور:${NC}     $SERVER_IP"
echo -e "  ${BLUE}پورت تانل:${NC}   $TUNNEL_PORT (UDP)"
echo -e "  ${BLUE}رمز:${NC}          $PASSWORD"
echo -e "  ${BLUE}SNI:${NC}          $FAKE_SNI"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${YELLOW}⚠️  این اطلاعات را یادداشت کنید!${NC}"
echo -e "${YELLOW}⚠️  برای نصب سرور ایران به این اطلاعات نیاز دارید${NC}"
echo ""
echo -e "${GREEN}📝 اطلاعات ذخیره شد در:${NC} /root/hysteria-server-info.txt"
echo ""
echo -e "${CYAN}🔧 دستورات مدیریت:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${BLUE}[چک وضعیت]${NC}"
echo "  systemctl status hysteria-server"
echo ""
echo -e "${BLUE}[چک لاگ زنده]${NC}"
echo "  journalctl -u hysteria-server -f"
echo ""
echo -e "${BLUE}[مشاهده 50 خط آخر لاگ]${NC}"
echo "  journalctl -u hysteria-server -n 50"
echo ""
echo -e "${BLUE}[Restart سرویس]${NC}"
echo "  systemctl restart hysteria-server"
echo ""
echo -e "${BLUE}[Stop سرویس]${NC}"
echo "  systemctl stop hysteria-server"
echo ""
echo -e "${BLUE}[چک پورت]${NC}"
echo "  netstat -ulpn | grep $TUNNEL_PORT"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${YELLOW}➡️  مرحله بعد: نصب Client روی سرور ایران${NC}"
echo ""
echo "  برای نصب سرور ایران این دستور را اجرا کنید:"
echo -e "  ${GREEN}bash <(curl -Ls https://raw.githubusercontent.com/agbeast98/vadmin-tunnels/main/install.sh)${NC}"
echo ""
echo "  و گزینه [2] را انتخاب کنید."
echo ""