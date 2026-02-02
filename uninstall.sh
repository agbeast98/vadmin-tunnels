#!/bin/bash

#═══════════════════════════════════════════════════════════════════
# Hysteria2 Tunnel Uninstaller
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

# بنر
clear
echo -e "${RED}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║         Hysteria2 Tunnel Uninstaller                      ║
║         حذف کامل تانل                                    ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# چک root
if [[ $EUID -ne 0 ]]; then
    print_error "این اسکریپت باید با root اجرا شود"
    exit 1
fi

echo ""
print_warning "⚠️  هشدار: این عملیات تمام تنظیمات را حذف می‌کند!"
echo ""
echo "نوع سرور را انتخاب کنید:"
echo ""
echo -e "${YELLOW}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║${NC}                                                           ${YELLOW}║${NC}"
echo -e "${YELLOW}║${NC}  ${GREEN}[1]${NC} سرور خارج (External Server)                       ${YELLOW}║${NC}"
echo -e "${YELLOW}║${NC}      └─ حذف Hysteria2 Server                            ${YELLOW}║${NC}"
echo -e "${YELLOW}║${NC}                                                           ${YELLOW}║${NC}"
echo -e "${YELLOW}║${NC}  ${GREEN}[2]${NC} سرور ایران (Iran Server)                          ${YELLOW}║${NC}"
echo -e "${YELLOW}║${NC}      └─ حذف Hysteria2 Client + HAProxy                  ${YELLOW}║${NC}"
echo -e "${YELLOW}║${NC}                                                           ${YELLOW}║${NC}"
echo -e "${YELLOW}║${NC}  ${BLUE}[0]${NC} انصراف (Cancel)                                    ${YELLOW}║${NC}"
echo -e "${YELLOW}║${NC}                                                           ${YELLOW}║${NC}"
echo -e "${YELLOW}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

read -p "انتخاب شما [0-2]: " choice

case $choice in
    1)
        # حذف سرور خارج
        echo ""
        print_warning "حذف Hysteria2 Server..."
        echo ""
        read -p "آیا مطمئن هستید؟ [y/N]: " confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            print_info "انصراف"
            exit 0
        fi
        
        echo ""
        print_info "شروع حذف سرور خارج..."
        
        # توقف سرویس
        if systemctl is-active --quiet hysteria-server 2>/dev/null; then
            print_info "توقف سرویس..."
            systemctl stop hysteria-server
            print_success "سرویس متوقف شد"
        fi
        
        # غیرفعال کردن
        if systemctl is-enabled --quiet hysteria-server 2>/dev/null; then
            systemctl disable hysteria-server >/dev/null 2>&1
            print_success "سرویس غیرفعال شد"
        fi
        
        # حذف فایل service
        if [ -f /etc/systemd/system/hysteria-server.service ]; then
            rm -f /etc/systemd/system/hysteria-server.service
            print_success "فایل service حذف شد"
        fi
        
        # reload systemd
        systemctl daemon-reload
        
        # حذف فایل‌های کانفیگ
        if [ -d /etc/hysteria ]; then
            rm -rf /etc/hysteria
            print_success "فایل‌های کانفیگ حذف شد"
        fi
        
        # حذف باینری
        if [ -f /usr/local/bin/hysteria ]; then
            rm -f /usr/local/bin/hysteria
            print_success "باینری حذف شد"
        fi
        
        # حذف فایل اطلاعات
        if [ -f /root/hysteria-server-info.txt ]; then
            rm -f /root/hysteria-server-info.txt
            print_success "فایل اطلاعات حذف شد"
        fi
        
        # حذف قوانین Firewall
        print_info "پاکسازی Firewall..."
        if command -v ufw >/dev/null 2>&1; then
            # فقط اگه پورت‌های معمول باشه
            for port in 443 53 8443 36712; do
                ufw delete allow $port/udp 2>/dev/null || true
            done
        fi
        
        echo ""
        print_success "✅ حذف سرور خارج کامل شد!"
        ;;
        
    2)
        # حذف سرور ایران
        echo ""
        print_warning "حذف Hysteria2 Client + HAProxy..."
        echo ""
        read -p "آیا مطمئن هستید؟ [y/N]: " confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            print_info "انصراف"
            exit 0
        fi
        
        echo ""
        print_info "شروع حذف سرور ایران..."
        
        # توقف سرویس‌ها
        if systemctl is-active --quiet hysteria-client 2>/dev/null; then
            print_info "توقف Hysteria Client..."
            systemctl stop hysteria-client
            print_success "Hysteria Client متوقف شد"
        fi
        
        # غیرفعال کردن
        if systemctl is-enabled --quiet hysteria-client 2>/dev/null; then
            systemctl disable hysteria-client >/dev/null 2>&1
            print_success "Hysteria Client غیرفعال شد"
        fi
        
        # حذف فایل service
        if [ -f /etc/systemd/system/hysteria-client.service ]; then
            rm -f /etc/systemd/system/hysteria-client.service
            print_success "فایل service حذف شد"
        fi
        
        # reload systemd
        systemctl daemon-reload
        
        # حذف فایل‌های کانفیگ Hysteria
        if [ -d /etc/hysteria ]; then
            rm -rf /etc/hysteria
            print_success "فایل‌های کانفیگ Hysteria حذف شد"
        fi
        
        # حذف باینری
        if [ -f /usr/local/bin/hysteria ]; then
            rm -f /usr/local/bin/hysteria
            print_success "باینری Hysteria حذف شد"
        fi
        
        # بازگردانی HAProxy
        print_info "بازگردانی HAProxy..."
        
        # حذف کانفیگ تانل از HAProxy
        if [ -f /etc/haproxy/haproxy.cfg ]; then
            # پیدا کردن آخرین بک‌آپ
            LATEST_BACKUP=$(ls -t /etc/haproxy/haproxy.cfg.backup.* 2>/dev/null | head -1)
            
            if [ -n "$LATEST_BACKUP" ]; then
                print_info "بازگردانی از بک‌آپ..."
                cp "$LATEST_BACKUP" /etc/haproxy/haproxy.cfg
                print_success "HAProxy از بک‌آپ بازگردانی شد"
            else
                # حذف دستی قسمت تانل
                sed -i '/# Hysteria2 Tunnel Configuration/,/^$/d' /etc/haproxy/haproxy.cfg
                print_success "کانفیگ تانل از HAProxy حذف شد"
            fi
            
            # Restart HAProxy
            systemctl restart haproxy
            print_success "HAProxy راه‌اندازی مجدد شد"
        fi
        
        # حذف فایل اطلاعات
        if [ -f /root/hysteria-client-info.txt ]; then
            rm -f /root/hysteria-client-info.txt
            print_success "فایل اطلاعات حذف شد"
        fi
        
        echo ""
        print_success "✅ حذف سرور ایران کامل شد!"
        echo ""
        print_info "HAProxy همچنان نصب است و سایر تنظیمات آن حفظ شده است"
        ;;
        
    0)
        print_info "انصراف"
        exit 0
        ;;
        
    *)
        print_error "گزینه نامعتبر!"
        exit 1
        ;;
esac

echo ""