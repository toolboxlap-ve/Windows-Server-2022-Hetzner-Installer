# Windows Server 2022 Hetzner Installer

Automated Windows Server 2022 installer for Hetzner dedicated servers using QEMU/KVM + UEFI boot support.

---

## Features

- Fully automated Windows Server 2022 installation
- UEFI / GPT boot support
- Fixed reboot / bootloop issue on Hetzner servers
- Automatic VNC setup
- Automatic RDP forwarding
- Works with Hetzner Rescue System
- Uses native disk installation
- TOOLBOXLAP branded installer

---

## Quick Install

Run this command inside Hetzner Rescue Mode:

```bash
wget -O install-windows2022.sh https://raw.githubusercontent.com/toolboxlap-ve/Windows-Server-2022-Hetzner-Installer/main/install-windows2022.sh && chmod +x install-windows2022.sh && ./install-windows2022.sh
```

---

## Requirements

- Hetzner Dedicated Server
- Rescue System enabled
- VNC Viewer installed on your PC

---

## Installation Steps

### 1. Enable Rescue Mode

From Hetzner Robot Panel:

- Go to Rescue
- Enable Linux Rescue System
- Reboot server

---

### 2. Connect to Rescue System

Use SSH:

```bash
ssh root@YOUR_SERVER_IP
```

---

### 3. Run Installer

```bash
wget -O install-windows2022.sh https://raw.githubusercontent.com/toolboxlap-ve/Windows-Server-2022-Hetzner-Installer/main/install-windows2022.sh && chmod +x install-windows2022.sh && ./install-windows2022.sh
```

---

### 4. Connect Using VNC

Example:

```text
YOUR_SERVER_IP:5901
```

Complete Windows installation normally.

---

### 5. IMPORTANT AFTER INSTALLATION

After Windows setup finishes:

1. Shutdown Windows completely
2. Disable Rescue Mode from Hetzner panel
3. Execute automatic hardware reset
4. Connect using RDP

---

## RDP Connection

```text
YOUR_SERVER_IP:3389
```

---

## Notes

- This installer wipes the target disk completely
- UEFI/GPT mode is required on modern Hetzner servers
- Keep SSH window open during installation
- Do NOT close QEMU terminal while Windows is installing

---

## Troubleshooting

### VNC not opening

Wait 10-20 seconds after launch and retry.

---

### Server not booting after installation

Make sure:

- Rescue Mode is disabled
- Hardware reset was executed
- Installation completed successfully

---

## TOOLBOXLAP

Website:
https://toolboxlap.com/

YouTube:
https://www.youtube.com/channel/UCDT4fs9JwrnQIXPrXX8yHeQ
