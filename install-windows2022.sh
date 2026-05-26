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

VKVM_URL="https://github.com/CDLD/KVM/raw/main/vkvm.tar.gz"

ISO_URL="https://software-download.microsoft.com/download/sg/20348.169.210806-2348.fe_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso"
ISO_NAME="20348.169.210806-2348.fe_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso"

WORKDIR="/tmp"
DISK="/dev/nvme0n1"
QEMU_BIN="/tmp/qemu-system-x86_64"

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

echo
echo -e "${BLUE}[0/6] Cleaning old QEMU sessions...${NC}"
pkill -f qemu-system || true
screen -wipe || true

cd "$WORKDIR"

echo
echo -e "${BLUE}[1/6] Installing required packages...${NC}"
apt update -y
apt install -y wget tar screen curl

echo
echo -e "${BLUE}[2/6] Downloading TOOLBOXLAP KVM files...${NC}"
wget -qO- "$VKVM_URL" | tar xvz -C /tmp

if [ ! -f "$QEMU_BIN" ]; then
    echo -e "${RED}[ERROR] QEMU binary was not found at: $QEMU_BIN${NC}"
    exit 1
fi

chmod +x "$QEMU_BIN"

echo
echo -e "${BLUE}[3/6] Downloading Windows Server 2022 ISO...${NC}"
if [ ! -f "$ISO_NAME" ]; then
    wget -O "$ISO_NAME" "$ISO_URL"
else
    echo -e "${GREEN}ISO already exists. Skipping download.${NC}"
fi

echo
echo -e "${BLUE}[4/6] Detecting disks...${NC}"
lsblk
echo
echo -e "${GREEN}Selected Disk:${NC} $DISK"

echo
echo -e "${BLUE}[5/6] Preparing VNC information...${NC}"
SERVER_IP=$(curl -4 -s ifconfig.me || hostname -I | awk '{print $1}')

echo
echo -e "${GREEN}VNC ADDRESS:${NC}"
echo "$SERVER_IP:5901"
echo
echo -e "${GREEN}RDP AFTER WINDOWS INSTALL:${NC}"
echo "$SERVER_IP:3389"
echo
echo -e "${YELLOW}Note: Open VNC using IPv4 only.${NC}"
echo -e "${YELLOW}Important: Keep this terminal open while Windows is installing.${NC}"
echo -e "${YELLOW}If you close this terminal, the Windows installer will stop.${NC}"
echo

echo -e "${BLUE}[6/6] Launching Windows installer with TOOLBOXLAP KVM...${NC}"
echo

"$QEMU_BIN" \
-net nic \
-net user,hostfwd=tcp::3389-:3389 \
-m 10000M \
-localtime \
-enable-kvm \
-cpu core2duo,+nx \
-smp 2 \
-usbdevice tablet \
-k en-us \
-cdrom "$WORKDIR/$ISO_NAME" \
-hda "$DISK" \
-vnc :1 \
-boot d
