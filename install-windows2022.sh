#!/bin/bash

# ==========================================
# TOOLBOXLAP Windows Server 2022 Installer
# Website: https://toolboxlap.com/
# YouTube: https://www.youtube.com/channel/UCDT4fs9JwrnQIXPrXX8yHeQ
# ==========================================

set -e

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

CHANNEL_NAME="TOOLBOXLAP - Toolbox Lab"
YOUTUBE_URL="https://www.youtube.com/channel/UCDT4fs9JwrnQIXPrXX8yHeQ"
WEBSITE_URL="https://toolboxlap.com/"

ISO_URL="https://software-download.microsoft.com/download/sg/20348.169.210806-2348.fe_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso"
ISO_NAME="windows_server_2022_eval.iso"

WORKDIR="/tmp/toolboxlap-winserver"
DISK="/dev/nvme0n1"

clear

echo -e "${BLUE}"
echo '████████╗ ██████╗  ██████╗ ██╗     ██████╗  ██████╗ ██╗  ██╗'
echo '╚══██╔══╝██╔═══██╗██╔═══██╗██║     ██╔══██╗██╔═══██╗╚██╗██╔╝'
echo '   ██║   ██║   ██║██║   ██║██║     ██████╔╝██║   ██║ ╚███╔╝ '
echo '   ██║   ██║   ██║██║   ██║██║     ██╔══██╗██║   ██║ ██╔██╗ '
echo '   ██║   ╚██████╔╝╚██████╔╝███████╗██████╔╝╚██████╔╝██╔╝ ██╗'
echo '   ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝'
echo -e "${NC}"

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN} $CHANNEL_NAME${NC}"
echo -e "${GREEN} Windows Server 2022 Installer for Hetzner${NC}"
echo -e "${GREEN} Website: $WEBSITE_URL${NC}"
echo -e "${GREEN} YouTube: $YOUTUBE_URL${NC}"
echo -e "${GREEN}================================================${NC}"
echo

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}[ERROR] Please run this script as root.${NC}"
   exit 1
fi

if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
    echo -e "${YELLOW}[INFO] QEMU is not installed yet. It will be installed automatically.${NC}"
fi

if ! grep -E -q '(vmx|svm)' /proc/cpuinfo; then
    echo -e "${YELLOW}[WARNING] CPU virtualization flag not detected.${NC}"
    echo -e "${YELLOW}The installer may fail if KVM is not available.${NC}"
fi

if [ ! -b "$DISK" ]; then
    echo -e "${RED}[ERROR] Target disk not found: $DISK${NC}"
    echo
    echo -e "${YELLOW}Available disks:${NC}"
    lsblk
    exit 1
fi

echo -e "${YELLOW}[WARNING] This will start Windows installation on:${NC} $DISK"
echo -e "${RED}[WARNING] Existing data on this disk may be overwritten during Windows setup.${NC}"
echo
read -p "Type TOOLBOXLAP to continue: " confirm

if [ "$confirm" != "TOOLBOXLAP" ]; then
    echo -e "${RED}Installation cancelled.${NC}"
    exit 1
fi

mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo
echo -e "${BLUE}[1/5] Installing required packages...${NC}"
apt update -y
apt install -y wget qemu-system-x86 screen curl

echo
echo -e "${BLUE}[2/5] Downloading Windows Server 2022 ISO...${NC}"
if [ ! -f "$ISO_NAME" ]; then
    wget -O "$ISO_NAME" "$ISO_URL"
else
    echo -e "${GREEN}ISO already exists. Skipping download.${NC}"
fi

echo
echo -e "${BLUE}[3/5] Detecting disks...${NC}"
lsblk
echo
echo -e "${GREEN}Selected Disk:${NC} $DISK"

echo
echo -e "${BLUE}[4/5] Preparing VNC information...${NC}"
SERVER_IP=$(curl -s ifconfig.me || echo "SERVER_IP")

echo
echo -e "${GREEN}VNC ADDRESS:${NC}"
echo "$SERVER_IP:5901"
echo
echo -e "${GREEN}RDP AFTER WINDOWS INSTALL:${NC}"
echo "$SERVER_IP:3389"
echo
echo -e "${YELLOW}Note: If VNC does not open immediately, wait 10 seconds and try again.${NC}"
echo

echo -e "${BLUE}[5/5] Launching Windows installer with QEMU...${NC}"
echo

screen -dmS toolboxlap-wininstall qemu-system-x86_64 \
-enable-kvm \
-m 10G \
-smp 2 \
-cpu host \
-net nic \
-net user,hostfwd=tcp::3389-:3389 \
-localtime \
-usbdevice tablet \
-k en-us \
-cdrom "$WORKDIR/$ISO_NAME" \
-hda "$DISK" \
-vnc :1 \
-boot d

sleep 3

if screen -list | grep -q "toolboxlap-wininstall"; then
    echo -e "${GREEN}QEMU started successfully.${NC}"
    echo
    echo -e "${GREEN}Connect now using VNC:${NC} $SERVER_IP:5901"
    echo
    echo -e "${YELLOW}To view the running installer screen:${NC}"
    echo "screen -r toolboxlap-wininstall"
    echo
    echo -e "${YELLOW}To detach from screen:${NC}"
    echo "CTRL + A then D"
else
    echo -e "${RED}[ERROR] QEMU failed to start.${NC}"
    echo
    echo -e "${YELLOW}Try running this command to see the error:${NC}"
    echo "qemu-system-x86_64 -enable-kvm -m 10G -smp 2 -cpu host -net nic -net user,hostfwd=tcp::3389-:3389 -localtime -usbdevice tablet -k en-us -cdrom $WORKDIR/$ISO_NAME -hda $DISK -vnc :1 -boot d"
    exit 1
fi
