#!/bin/bash

#═══════════════════════════════════════════════════════════════════
# Hysteria2 Tunnel Installer - Main Menu
# Repository: https://github.com/agbeast98/vadmin-tunnels
# Version: 1.0
#═══════════════════════════════════════════════════════════════════

set -e

# رنگ‌ها
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# متغیرهای مسیر
REPO_URL="https://raw.githubusercontent.com/agbeast98/vadmin-tunnels/main"

# توابع
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

# چک root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "این اسکریپت باید با دسترسی root اجرا شود!"
        echo ""
        echo "لطفاً دوباره با sudo اجرا کنید:"
        echo "  sudo bash install.sh"
        exit 1
    fi
}

# دانلود و اجرای اسکریپت
run_script() {
    local script_name=$1
    local script_url="${REPO_URL}/${script_name}"
    
    print_info "دانلود اسکریپت..."
    
    if curl -fsSL "$script_url" -o "/tmp/${script_name}"; then
        chmod +x "/tmp/${script_name}"
        bash "/tmp/${script_name}"
        rm -f "/tmp/${script_name}"
    else
        print_error "خطا در دانلود اسکریپت!"
        echo ""
        echo "لطفاً اتصال اینترنت خود را بررسی کنید."
        exit 1
    fi
}

# منوی اصلی
show_menu() {
    print_header
    
    echo ""
    echo "لطفاً یکی از گزینه‌های زیر را انتخاب کنید:"
    echo ""
    echo -e "${YELLOW}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║${NC}                                                           ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}  ${GREEN}[1]${NC} سرور خارج (External Server)                       ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}      └─ نصب Hysteria2 Server                            ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}                                                           ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}  ${GREEN}[2]${NC} سرور ایران (Iran Server)                          ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}      └─ نصب Hysteria2 Client + HAProxy                  ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}                                                           ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}  ${RED}[3]${NC} حذف (Uninstall)                                    ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}      └─ حذف کامل تانل                                   ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}                                                           ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}  ${BLUE}[0]${NC} خروج (Exit)                                        ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}                                                           ${YELLOW}║${NC}"
    echo -e "${YELLOW}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    read -p "انتخاب شما [0-3]: " choice
    
    case $choice in
        1)
            echo ""
            print_info "شروع نصب سرور خارج..."
            sleep 1
            run_script "server-install.sh"
            ;;
        2)
            echo ""
            print_info "شروع نصب سرور ایران..."
            sleep 1
            run_script "client-install.sh"
            ;;
        3)
            echo ""
            print_info "شروع حذف..."
            sleep 1
            run_script "uninstall.sh"
            ;;
        0)
            echo ""
            print_info "خروج از برنامه..."
            exit 0
            ;;
        *)
            echo ""
            print_error "گزینه نامعتبر! لطفاً دوباره تلاش کنید."
            sleep 2
            show_menu
            ;;
    esac
}

# اجرای اصلی
main() {
    check_root
    show_menu
}

main "$@"