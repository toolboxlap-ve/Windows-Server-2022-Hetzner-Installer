#!/bin/bash

# ==========================================
# TOOLBOXLAP Windows Installer
# https://toolboxlap.com/
# https://www.youtube.com/channel/UCDT4fs9JwrnQIXPrXX8yHeQ
# ==========================================

set -e

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

CHANNEL_NAME="TOOLBOXLAP - Toolbox Lab"
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
echo -e "${GREEN} Windows Server Installer for Hetzner${NC}"
echo -e "${GREEN} Website: https://toolboxlap.com/${NC}"
echo -e "${GREEN} YouTube: TOOLBOXLAP${NC}"
echo -e "${GREEN}================================================${NC}"
echo

# Root Check
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}[ERROR] Please run as root.${NC}"
   exit 1
fi

# KVM Check
if ! grep -E -q '(vmx|svm)' /proc/cpuinfo; then
    echo -e "${RED}[ERROR] KVM virtualization not detected.${NC}"
    exit 1
fi

echo -e "${YELLOW}[WARNING] This will install Windows on:${NC} ${DISK}"
echo -e "${RED}[WARNING] ALL DATA WILL BE ERASED!${NC}"
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
echo -e "${BLUE}[2/5] Downloading Windows Server ISO...${NC}"

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

sleep 3

echo
echo -e "${BLUE}[4/5] Starting Windows Virtual Machine...${NC}"

echo
echo -e "${GREEN}VNC ADDRESS:${NC}"
echo "SERVER_IP:5901"
echo
echo -e "${GREEN}RDP AFTER INSTALL:${NC}"
echo "SERVER_IP:3389"
echo

echo -e "${BLUE}[5/5] Launching QEMU...${NC}"

screen -S toolboxlap-wininstall qemu-system-x86_64 \
-enable-kvm \
-machine type=q35 \
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
