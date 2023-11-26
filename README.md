# Mikrotik Check VPN Performance

This script simplifies the configuration of L2TP, SSTP, and ZeroTier VPN interfaces on MikroTik routers. It enforces a specific naming convention for VPN interfaces and hardcodes the ZeroTier private IP. Follow the instructions below to set up your VPN interfaces.

## Prerequisites

- A MikroTik router with RouterOS installed.
- Access to the MikroTik router either via Winbox or SSH.

## Usage

1. **Download the Script:**
   Download the `vpn-config-script.rsc` script from this repository.

2. **Upload Script to MikroTik:**
   Use Winbox or SCP to upload the script to your MikroTik router.

3. **Run the Script:**
   In the MikroTik terminal, run the following command:
```bash
   /import vpn-performance-script.rsc
```
