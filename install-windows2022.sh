#!/bin/bash
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
echo -e "${GREEN} Windows Server 2022 UEFI Installer for Hetzner${NC}"
echo -e "${GREEN} Website: $WEBSITE_URL${NC}"
echo -e "${GREEN} YouTube: $YOUTUBE_URL${NC}"
echo -e "${GREEN}================================================${NC}"
echo

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}[ERROR] Please run as root.${NC}"
   exit 1
fi

if [ ! -b "$DISK" ]; then
    echo -e "${RED}[ERROR] Disk not found: $DISK${NC}"
    lsblk
    exit 1
fi

echo -e "${RED}[WARNING] This will ERASE all data on: $DISK${NC}"
echo -e "${YELLOW}This version uses UEFI/GPT to fix boot after restart.${NC}"
echo
read -p "Type TOOLBOXLAP to continue: " confirm

if [ "$confirm" != "TOOLBOXLAP" ]; then
    echo -e "${RED}Cancelled.${NC}"
    exit 1
fi

echo
read -p "Type WIPE to erase $DISK and continue: " wipeconfirm

if [ "$wipeconfirm" != "WIPE" ]; then
    echo -e "${RED}Cancelled. Disk was not wiped.${NC}"
    exit 1
fi

echo
echo -e "${BLUE}[0/7] Cleaning old QEMU sessions...${NC}"
pkill -f qemu-system || true
screen -wipe || true

cd "$WORKDIR"

echo
echo -e "${BLUE}[1/7] Installing required packages...${NC}"
apt update -y
apt install -y wget tar curl screen gdisk util-linux ovmf

echo
echo -e "${BLUE}[2/7] Downloading TOOLBOXLAP KVM files...${NC}"
wget -qO- "$VKVM_URL" | tar xvz -C /tmp

if [ ! -f "$QEMU_BIN" ]; then
    echo -e "${RED}[ERROR] QEMU binary not found: $QEMU_BIN${NC}"
    exit 1
fi

chmod +x "$QEMU_BIN"

echo
echo -e "${BLUE}[3/7] Finding OVMF UEFI firmware...${NC}"

OVMF_CODE=""
for f in \
"/usr/share/OVMF/OVMF_CODE.fd" \
"/usr/share/ovmf/OVMF.fd" \
"/usr/share/qemu/OVMF.fd"
do
    if [ -f "$f" ]; then
        OVMF_CODE="$f"
        break
    fi
done

if [ -z "$OVMF_CODE" ]; then
    echo -e "${RED}[ERROR] OVMF firmware not found.${NC}"
    exit 1
fi

echo -e "${GREEN}Using OVMF:${NC} $OVMF_CODE"

echo
echo -e "${BLUE}[4/7] Wiping disk for clean GPT/UEFI install...${NC}"
sgdisk --zap-all "$DISK" || true
wipefs -a "$DISK" || true
partprobe "$DISK" || true
sleep 3

echo
echo -e "${BLUE}[5/7] Downloading Windows Server 2022 ISO...${NC}"
if [ ! -f "$ISO_NAME" ]; then
    wget -O "$ISO_NAME" "$ISO_URL"
else
    echo -e "${GREEN}ISO already exists. Skipping download.${NC}"
fi

echo
echo -e "${BLUE}[6/7] Disk information...${NC}"
lsblk
echo
echo -e "${GREEN}Selected Disk:${NC} $DISK"

SERVER_IP=$(curl -4 -s ifconfig.me || hostname -I | awk '{print $1}')

echo
echo -e "${GREEN}VNC ADDRESS:${NC}"
echo "$SERVER_IP:5901"
echo
echo -e "${GREEN}RDP AFTER WINDOWS INSTALL:${NC}"
echo "$SERVER_IP:3389"
echo
echo -e "${YELLOW}Important: Keep this terminal open while Windows is installing.${NC}"
echo -e "${YELLOW}After Windows finishes installing, disable Rescue Mode from Hetzner, then do hardware reset.${NC}"
echo

echo -e "${BLUE}[7/7] Launching Windows Server 2022 installer in UEFI mode...${NC}"
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
-bios "$OVMF_CODE" \
-cdrom "$WORKDIR/$ISO_NAME" \
-drive file="$DISK",format=raw,media=disk,if=ide \
-vnc :1 \
-boot d
