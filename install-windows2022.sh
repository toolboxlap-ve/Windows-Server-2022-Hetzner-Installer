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
echo -e "${BLUE}[0/6] Cleaning old sessions...${NC}"
pkill -f qemu-system || true
screen -wipe || true

mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo
echo -e "${BLUE}[1/6] Installing required packages...${NC}"
apt update -y
apt install -y wget qemu-system-x86 screen curl

echo
echo -e "${BLUE}[2/6] Downloading Windows Server 2022 ISO...${NC}"
if [ ! -f "$ISO_NAME" ]; then
    wget -O "$ISO_NAME" "$ISO_URL"
else
    echo -e "${GREEN}ISO already exists. Skipping download.${NC}"
fi

echo
echo -e "${BLUE}[3/6] Detecting disks...${NC}"
lsblk
echo
echo -e "${GREEN}Selected Disk:${NC} $DISK"

echo
echo -e "${BLUE}[4/6] Getting server IPv4...${NC}"
SERVER_IP=$(curl -4 -s ifconfig.me || hostname -I | awk '{print $1}')

echo
echo -e "${GREEN}VNC ADDRESS:${NC}"
echo "$SERVER_IP:5901"
echo
echo -e "${GREEN}RDP AFTER WINDOWS INSTALL:${NC}"
echo "$SERVER_IP:3389"
echo

echo -e "${YELLOW}Note: Open VNC using IPv4 only, not IPv6.${NC}"
echo -e "${YELLOW}If VNC does not open immediately, wait 10 seconds and try again.${NC}"
echo

echo -e "${BLUE}[5/6] Launching Windows installer with QEMU...${NC}"
echo

screen -dmS toolboxlap-wininstall qemu-system-x86_64 \
-m 10G \
-smp 2 \
-cpu qemu64 \
-net nic \
-net user,hostfwd=tcp::3389-:3389 \
-localtime \
-usbdevice tablet \
-k en-us \
-cdrom "$WORKDIR/$ISO_NAME" \
-hda "$DISK" \
-vnc 0.0.0.0:1 \
-boot d

sleep 5

echo
echo -e "${BLUE}[6/6] Checking QEMU status...${NC}"

if screen -list | grep -q "toolboxlap-wininstall"; then
    echo
    echo -e "${GREEN}QEMU started successfully.${NC}"
    echo
    echo -e "${GREEN}Connect now using VNC:${NC}"
    echo "$SERVER_IP:5901"
    echo
    echo -e "${GREEN}After Windows installation, enable Remote Desktop inside Windows.${NC}"
    echo -e "${GREEN}Then connect using RDP:${NC}"
    echo "$SERVER_IP:3389"
    echo
    echo -e "${YELLOW}To view the running installer console:${NC}"
    echo "screen -r toolboxlap-wininstall"
    echo
    echo -e "${YELLOW}To detach from screen:${NC}"
    echo "CTRL + A then D"
else
    echo
    echo -e "${RED}[ERROR] QEMU failed to start.${NC}"
    echo
    echo -e "${YELLOW}Run this command manually to see the full error:${NC}"
    echo
    echo "cd $WORKDIR"
    echo "qemu-system-x86_64 -m 10G -smp 2 -cpu qemu64 -net nic -net user,hostfwd=tcp::3389-:3389 -localtime -usbdevice tablet -k en-us -cdrom $WORKDIR/$ISO_NAME -hda $DISK -vnc 0.0.0.0:1 -boot d"
    exit 1
fi
