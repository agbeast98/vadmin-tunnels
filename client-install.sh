#!/bin/bash

#═══════════════════════════════════════════════════════════════════
# Hysteria2 Client + HAProxy Installation (Iran Server)
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
║    Hysteria2 Client + HAProxy Installation                ║
║    نصب سرور ایران                                       ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# قدم 1: بررسی سیستم
print_step "قدم 1/12: بررسی سیستم"

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

IRAN_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s api.ipify.org 2>/dev/null)
if [ -z "$IRAN_IP" ]; then
    print_warning "نمی‌توان IP را تشخیص داد"
    read -p "لطفاً IP سرور ایران را وارد کنید: " IRAN_IP
fi
print_success "IP سرور ایران: $IRAN_IP"

# بررسی نصب قبلی
if [ -f /etc/hysteria/config.yaml ]; then
    print_warning "Hysteria2 Client قبلاً نصب شده است"
    echo ""
    echo "[1] بروزرسانی (Update)"
    echo "[2] نصب مجدد (Reinstall)"
    echo "[0] انصراف"
    read -p "انتخاب [0-2]: " reinstall_choice
    
    case $reinstall_choice in
        1) print_info "ادامه با بروزرسانی..." ;;
        2)
            print_info "حذف نصب قبلی..."
            systemctl stop hysteria-client 2>/dev/null || true
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
print_step "قدم 2/12: نصب و بروزرسانی پیشنیازها"

print_info "بروزرسانی لیست پکیج‌ها..."
apt-get update -qq >/dev/null 2>&1

install_package "curl"
install_package "wget"
install_package "net-tools"
install_package "haproxy"

print_success "پیشنیازها آماده است"

# قدم 3: دریافت اطلاعات
print_step "قدم 3/12: دریافت اطلاعات پیکربندی"

echo ""
echo -e "${BLUE}ℹ IP سرور ایران: $IRAN_IP${NC}"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW} اطلاعات سرور خارج${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# IP سرور خارج
echo "[1/8] IP سرور خارج"
get_input "IP سرور خارج" "" "EXTERNAL_IP"

# پورت تانل
echo ""
echo "[2/8] پورت تانل سرور خارج"
get_input "پورت" "443" "TUNNEL_PORT"

# رمز
echo ""
echo "[3/8] رمز (از سرور خارج)"
echo "      این رمز در /root/hysteria-server-info.txt موجود است"
get_input "رمز" "" "PASSWORD"

# SNI
echo ""
echo "[4/8] Fake SNI"
echo "      باید دقیقاً مثل سرور خارج باشه"
get_input "SNI" "bing.com" "FAKE_SNI"

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW} پورت‌های X-UI (روی سرور خارج)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# پورت X-UI اول
echo "[5/8] پورت X-UI اول"
get_input "پورت" "8080" "XUI_PORT1"

# پورت X-UI دوم
echo ""
echo "[6/8] پورت X-UI دوم"
get_input "پورت" "8081" "XUI_PORT2"

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW} پورت‌های عمومی (برای کاربران)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# پورت عمومی اول
echo "[7/8] پورت عمومی اول"
get_input "پورت" "2097" "PUBLIC_PORT1"

# پورت عمومی دوم
echo ""
echo "[8/8] پورت عمومی دوم"
get_input "پورت" "2087" "PUBLIC_PORT2"

# خلاصه
echo ""
print_step "خلاصه تنظیمات"
echo ""
echo -e "  ${BLUE}سرور ایران:${NC}    $IRAN_IP"
echo -e "  ${BLUE}سرور خارج:${NC}     $EXTERNAL_IP:$TUNNEL_PORT"
echo -e "  ${BLUE}رمز:${NC}            ${PASSWORD:0:30}..."
echo -e "  ${BLUE}SNI:${NC}            $FAKE_SNI"
echo -e "  ${BLUE}پورت X-UI:${NC}      $XUI_PORT1, $XUI_PORT2"
echo -e "  ${BLUE}پورت عمومی:${NC}     $PUBLIC_PORT1, $PUBLIC_PORT2"
echo ""

read -p "ادامه می‌دهید؟ [Y/n]: " confirm
confirm=${confirm:-Y}
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    print_info "انصراف"
    exit 0
fi

# قدم 4: دانلود Hysteria2
print_step "قدم 4/12: دانلود Hysteria2"

if [ -f /usr/local/bin/hysteria ]; then
    print_info "Hysteria2 موجود است"
else
    print_info "دانلود Hysteria2..."
    
    # تلاش برای دانلود مستقیم
    if wget -q https://github.com/apernet/hysteria/releases/download/app%2Fv2.7.0/hysteria-linux-amd64 -O /usr/local/bin/hysteria 2>/dev/null; then
        print_success "دانلود از GitHub موفق بود"
    elif curl -sL https://github.com/apernet/hysteria/releases/download/app%2Fv2.7.0/hysteria-linux-amd64 -o /usr/local/bin/hysteria 2>/dev/null; then
        print_success "دانلود از GitHub موفق بود"
    else
        print_error "دانلود مستقیم ناموفق بود"
        echo ""
        echo "GitHub احتماالً فیلتر است. لطفاً دستی دانلود کنید:"
        echo ""
        echo "1. روی سرور خارج:"
        echo "   cd /tmp"
        echo "   wget https://github.com/apernet/hysteria/releases/download/app%2Fv2.7.0/hysteria-linux-amd64"
        echo ""
        echo "2. روی سرور ایران:"
        echo "   scp root@$EXTERNAL_IP:/tmp/hysteria-linux-amd64 /usr/local/bin/hysteria"
        echo "   chmod +x /usr/local/bin/hysteria"
        echo ""
        exit 1
    fi
fi

chmod +x /usr/local/bin/hysteria

if hysteria version >/dev/null 2>&1; then
    HYSTERIA_VERSION=$(hysteria version 2>/dev/null | head -1 || echo "نامشخص")
    print_success "Hysteria2: $HYSTERIA_VERSION"
else
    print_error "Hysteria2 نصب نشد"
    exit 1
fi

# قدم 5: ساخت کانفیگ Hysteria
print_step "قدم 5/12: ساخت کانفیگ Hysteria"

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

print_success "کانفیگ Hysteria ساخته شد"

# قدم 6: ساخت Service Hysteria
print_step "قدم 6/12: ساخت Service Hysteria"

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

print_success "Service Hysteria ساخته شد"

# قدم 7: راه‌اندازی Hysteria
print_step "قدم 7/12: راه‌اندازی Hysteria"

systemctl daemon-reload
systemctl enable hysteria-client >/dev/null 2>&1
systemctl restart hysteria-client

sleep 3

if systemctl is-active --quiet hysteria-client; then
    print_success "Service در حال اجرا است"
    
    # چک اتصال
    if journalctl -u hysteria-client -n 10 --no-pager 2>/dev/null | grep -q "connected to server"; then
        print_success "اتصال به سرور خارج برقرار شد ✓"
    else
        print_warning "وضعیت اتصال نامشخص"
    fi
else
    print_error "Service شروع نشد"
    journalctl -u hysteria-client -n 20 --no-pager
    exit 1
fi

# قدم 8: بک‌آپ HAProxy
print_step "قدم 8/12: پیکربندی HAProxy"

if [ -f /etc/haproxy/haproxy.cfg ]; then
    print_info "بک‌آپ از کانفیگ HAProxy..."
    cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.backup.$(date +%Y%m%d-%H%M%S)
    print_success "بک‌آپ ساخته شد"
fi

# قدم 9: اضافه کردن کانفیگ HAProxy
print_step "قدم 9/12: اضافه کردن کانفیگ تانل"

# حذف کانفیگ قبلی اگه وجود داره
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

print_success "کانفیگ HAProxy به‌روز شد"

# قدم 10: تست کانفیگ HAProxy
print_step "قدم 10/12: تست کانفیگ HAProxy"

if haproxy -c -f /etc/haproxy/haproxy.cfg >/dev/null 2>&1; then
    print_success "کانفیگ HAProxy معتبر است"
else
    print_error "کانفیگ HAProxy معتبر نیست!"
    haproxy -c -f /etc/haproxy/haproxy.cfg
    exit 1
fi

systemctl restart haproxy

if systemctl is-active --quiet haproxy; then
    print_success "HAProxy در حال اجرا است"
else
    print_error "HAProxy شروع نشد"
    journalctl -u haproxy -n 20 --no-pager
    exit 1
fi

# قدم 11: پیکربندی Firewall
print_step "قدم 11/12: پیکربندی Firewall"

if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q "Status: active"; then
    print_info "پیکربندی UFW..."
    ufw allow $PUBLIC_PORT1/tcp >/dev/null 2>&1 || true
    ufw allow $PUBLIC_PORT2/tcp >/dev/null 2>&1 || true
    print_success "UFW پیکربندی شد"
elif command -v firewall-cmd >/dev/null 2>&1; then
    print_info "پیکربندی firewalld..."
    firewall-cmd --permanent --add-port=$PUBLIC_PORT1/tcp >/dev/null 2>&1 || true
    firewall-cmd --permanent --add-port=$PUBLIC_PORT2/tcp >/dev/null 2>&1 || true
    firewall-cmd --reload >/dev/null 2>&1 || true
    print_success "firewalld پیکربندی شد"
else
    print_info "Firewall غیرفعال است"
fi

# قدم 12: تست نهایی
print_step "قدم 12/12: تست نهایی"

# تست SOCKS5
print_info "تست SOCKS5..."
sleep 2
TEST_IP=$(timeout 5 curl --socks5 127.0.0.1:1080 -s https://ifconfig.me 2>/dev/null || echo "")

if [ "$TEST_IP" == "$EXTERNAL_IP" ]; then
    print_success "تست SOCKS5: موفق ✓ (IP: $TEST_IP)"
else
    print_warning "تست SOCKS5: نامشخص"
fi

# چک پورت‌ها
print_info "بررسی پورت‌ها..."
if netstat -tlpn 2>/dev/null | grep -q ":$PUBLIC_PORT1 "; then
    print_success "پورت $PUBLIC_PORT1: باز ✓"
else
    print_warning "پورت $PUBLIC_PORT1: نامشخص"
fi

if netstat -tlpn 2>/dev/null | grep -q ":$PUBLIC_PORT2 "; then
    print_success "پورت $PUBLIC_PORT2: باز ✓"
else
    print_warning "پورت $PUBLIC_PORT2: نامشخص"
fi

# ذخیره اطلاعات
cat > /root/hysteria-client-info.txt << EOF
═══════════════════════════════════════════════════════════
Hysteria2 Client Information
═══════════════════════════════════════════════════════════
تاریخ نصب: $(date)

IP سرور ایران:    $IRAN_IP
پورت عمومی 1:      $PUBLIC_PORT1
پورت عمومی 2:      $PUBLIC_PORT2

سرور خارج:         $EXTERNAL_IP:$TUNNEL_PORT

فایل‌ها:
  کانفیگ Hysteria:  /etc/hysteria/config.yaml
  کانفیگ HAProxy:   /etc/haproxy/haproxy.cfg
  Service Hysteria:  /etc/systemd/system/hysteria-client.service

دستورات مفید:
  systemctl status hysteria-client haproxy
  journalctl -u hysteria-client -f
  journalctl -u haproxy -f
  curl --socks5 127.0.0.1:1080 ifconfig.me
  netstat -tlpn | grep -E "$PUBLIC_PORT1|$PUBLIC_PORT2"
  
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
echo -e "${YELLOW}📋 اطلاعات سرور ایران:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  ${BLUE}IP سرور ایران:${NC}    $IRAN_IP"
echo -e "  ${BLUE}پورت عمومی 1:${NC}      $PUBLIC_PORT1"
echo -e "  ${BLUE}پورت عمومی 2:${NC}      $PUBLIC_PORT2"
echo ""
echo -e "  ${BLUE}اتصال به:${NC}          $EXTERNAL_IP:$TUNNEL_PORT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${YELLOW}👥 اطلاعات برای کاربران:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  ${GREEN}Server:${NC}  $IRAN_IP"
echo -e "  ${GREEN}Port 1:${NC}  $PUBLIC_PORT1"
echo -e "  ${GREEN}Port 2:${NC}  $PUBLIC_PORT2"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}📝 اطلاعات ذخیره شد در:${NC} /root/hysteria-client-info.txt"
echo ""
echo -e "${CYAN}🔧 دستورات مدیریت:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${BLUE}[چک وضعیت]${NC}"
echo "  systemctl status hysteria-client"
echo "  systemctl status haproxy"
echo ""
echo -e "${BLUE}[چک لاگ زنده]${NC}"
echo "  journalctl -u hysteria-client -f"
echo "  journalctl -u haproxy -f"
echo ""
echo -e "${BLUE}[تست اتصال SOCKS5]${NC}"
echo "  curl --socks5 127.0.0.1:1080 ifconfig.me"
echo "  # باید IP سرور خارج ($EXTERNAL_IP) نشون بده"
echo ""
echo -e "${BLUE}[چک پورت‌ها]${NC}"
echo "  netstat -tlpn | grep -E '$PUBLIC_PORT1|$PUBLIC_PORT2'"
echo ""
echo -e "${BLUE}[Restart سرویس‌ها]${NC}"
echo "  systemctl restart hysteria-client"
echo "  systemctl restart haproxy"
echo ""
echo -e "${BLUE}[مشاهده کانفیگ]${NC}"
echo "  cat /etc/hysteria/config.yaml"
echo "  cat /etc/haproxy/haproxy.cfg"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""