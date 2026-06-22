# Raspberry Pi Rover — Phase 1 Setup Guide

*Brain setup: flashing the OS, getting WiFi + SSH working, and preparing the Pi 3B for the rest of the build.*

## Overview

This guide covers everything done to get the Raspberry Pi 3 Model B (the rover's "brain") flashed, connected to WiFi, and reachable over SSH from a Mac. By the end, the Pi is headless (no monitor/keyboard needed for normal use), reachable at a stable local IP, and ready for Python and Arduino work in later phases.

Follow the steps in order. The **Blockers Encountered** section at the end documents every problem hit along the way and exactly how each was fixed — read it if you hit the same symptoms.

## What You Need Before Starting

* Raspberry Pi 3 Model B
* MicroSD card, 16GB or larger, Class 10
* A proper 5V/2.5A+ wall charger with micro USB — **not** a laptop/Mac USB port (see Blockers section for why this matters)
* A Mac (or PC) with an SD card reader, or a USB SD card adapter
* Home WiFi network name (SSID) and password

---

## Step 1 — Install Raspberry Pi Imager

1. Download Raspberry Pi Imager from `raspberrypi.com/software`
2. Install it like any normal Mac app (drag to Applications)
3. Insert the MicroSD card into your Mac

## Step 2 — Choose Device, OS, and Storage

1. Open Raspberry Pi Imager
2. Choose Device → **Raspberry Pi 3**
3. Choose OS → **Raspberry Pi OS (other)** → **Raspberry Pi OS Lite (64-bit)**
   *Lite is used because there's no need for a desktop GUI — everything is controlled via SSH, which is faster and lighter on the Pi 3B's resources.*
4. Choose Storage → select the MicroSD card (double check this is the SD card, not your Mac's main drive)

## Step 3 — Configure OS Customisation Settings

After selecting Device, OS, and Storage, the Imager will ask to apply OS customisation settings. Click **Edit Settings** — this configures WiFi and SSH before the image is even written, so the Pi connects automatically on first boot.

### General tab

* **Set hostname** — e.g. `th3pl4gu3-rover`
* **Set username and password** — choose a username and a memorable password
* **Configure wireless LAN** — enter the WiFi network name (SSID) and password exactly. If the network is hidden, that's fine — just make sure the password is character-for-character correct (copy-paste from the router admin page rather than retyping, if possible)
* **Set locale settings** — timezone set to Mauritius, keyboard layout "us" (or preference)

### Services tab

* **Enable SSH** — tick this
* Select **"Allow public-key authentication only"** and paste in a public SSH key (see below for how to generate one)

### Generating an SSH key (on the Mac, before pasting it in)

Open Terminal and run:

```bash
ssh-keygen -t ed25519 -C "your-key-comment"
```

Accept the default save location, and either set a passphrase or press Enter twice for none. Then display the public key:

```bash
cat ~/.ssh/id_ed25519.pub
```

Copy the full output line (starts with `ssh-ed25519`) and paste it into the Imager's public key field.

> **Why ed25519 instead of RSA?**
> The Pi 3B fully supports ed25519 — this is a software (OpenSSH) feature, not a hardware limitation. ed25519 keys are shorter, faster, and at least as secure as RSA. There's no reason to use RSA unless a specific legacy system requires it.

## Step 4 — Write the Image

1. Click **Save** on the customisation screen, then click **Write**
2. Confirm the warning about erasing the storage — as long as it's showing the MicroSD card, this is correct
3. Wait for the write and verification to finish (a few minutes)

## Step 5 — First Boot

1. Insert the MicroSD card into the Pi
2. Connect a proper 5V/2.5A wall charger (not a Mac/laptop USB port)
3. Wait 1–2 minutes for first boot to complete (it does extra setup work the first time)

## Step 6 — Connect via SSH

From the Mac, try the hostname first:

```bash
ssh yourusername@yourhostname.local
```

If that resolves and connects, you're in — skip to Step 7.

If you get "Could not resolve hostname" or it hangs, find the Pi's IP address directly instead:

```bash
ifconfig | grep -A 1 "en0\|en1"
ipconfig getifaddr en0
```

This shows your Mac's own WiFi IP and interface name. Use that interface name in a network scan:

```bash
brew install arp-scan
sudo arp-scan --interface=en0 --localnet
```

Look through the results for a device labelled **"Raspberry Pi Trading Ltd"** or **"Raspberry Pi Foundation"** — that's the Pi, and the IP next to it is what you connect to:

```bash
ssh yourusername@<that-ip-address>
```

## Step 7 — Set Up a Stable IP Address

Rather than editing network config on the Pi itself, set a DHCP reservation on the router — this tells the router to always hand the same IP to this device, while leaving the Pi's own configuration untouched.

1. On the Pi, get its WiFi MAC address:
   ```bash
   ip a show wlan0 | grep ether
   ```
2. Log into the router's admin page (commonly `192.168.0.1` or `192.168.1.1` in a browser)
3. Find the DHCP Reservation / Address Reservation / Static Lease section
4. Match the MAC address from step 1 and assign it a fixed IP
5. Reboot the Pi cleanly (see Step 8) and reconnect using the new IP

> **Note:** A reservation can take more than one reboot cycle to actually apply on some routers. If the Pi comes up on a different IP than reserved right after the first reboot, that's not a failure — just re-scan the network, confirm it's still reachable, and check again after a second reboot.

## Step 8 — Always Shut Down Cleanly

Before ever disconnecting power, always run:

```bash
sudo shutdown -h now
```

Wait until the green activity LED stops blinking and stays off before unplugging power. This is **not optional** — see the Blockers section for what happens if you skip this.

## Step 9 — Update the System and Confirm Python

```bash
sudo apt update && sudo apt full-upgrade -y
sudo reboot
```

After it reboots and you reconnect, confirm Python is present:

```bash
python3 --version
```

Raspberry Pi OS ships with Python 3 pre-installed — this should return a recent version with no further action needed.

## Step 10 — Install pip, venv, and git

```bash
sudo apt install python3-pip python3-venv git -y
```

## Step 11 — Create the project folder structure

```bash
mkdir -p ~/rover/{control,camera,logs}
cd ~/rover
```

## Step 12 — Set up a Python virtual environment

```bash
python3 -m venv venv
source venv/bin/activate
```

The prompt will change to show `(venv)` — this means the virtual environment is active. All Python packages installed from here go into `~/rover/venv/`, not system-wide.

## Step 13 — Confirm Bluetooth is working

```bash
sudo systemctl status bluetooth
hciconfig
```

You want to see `active (running)` from the first command, and a `hci0` device listed from the second. If either check fails, Bluetooth needs to be debugged before Phase 1 is complete.

---

## End of Phase 1

* ✅ Pi 3B flashed, boots reliably on a proper power source
* ✅ Connects to WiFi automatically on boot, including on a hidden network
* ✅ Reachable via SSH using key authentication (no password prompt)
* ✅ Has a stable, reserved local IP address
* ✅ System packages updated, Python 3.13 confirmed present
* ⏳ Install pip, venv, git
* ⏳ Create `~/rover/{control,camera,logs}` folder structure
* ⏳ Set up Python virtual environment
* ⏳ Confirm Bluetooth working (`systemctl status bluetooth`, `hciconfig`)

---

## Blockers Encountered (and How Each Was Fixed)

Every real problem hit during this setup, in the order they came up. If something looks similar to what you're seeing, the fix is right here — no need to re-debug from scratch.

### Blocker 1 — SSH and ping couldn't find the Pi by hostname

**Symptom:** `ssh: Could not resolve hostname` and `ping: cannot resolve host` when using the `.local` hostname.

**Cause:** mDNS (`.local` resolution) wasn't working reliably on this network.

**Fix:** bypassed hostname resolution entirely and found the Pi's actual IP address with `arp-scan` instead (see Step 6 above), then connected directly using that IP.

### Blocker 2 — arp-scan found nothing on the first attempt

**Symptom:** `arp-scan` ran but returned 0 responses, with a warning about interface `ap1` having no IP address.

**Cause:** the scan ran against the wrong network interface on the Mac (a virtual interface, not the real WiFi connection).

**Fix:** identified the correct interface first with `ifconfig` / `ipconfig getifaddr`, then re-ran `arp-scan` specifying that interface explicitly with `--interface=en0`.

### Blocker 3 — Found a Raspberry Pi on the network, but it was the wrong one

**Symptom:** `arp-scan` showed a device labelled "Raspberry Pi Trading Ltd" — but SSH-ing into it connected to a different, already-owned Pi 5, not the rover's Pi 3B.

**Cause:** more than one Raspberry Pi was active on the same network.

**Fix:** confirmed identity by successfully SSH-ing into that device with the Pi 5's known key, ruling it out, then kept scanning for a second entry with a different MAC address prefix, which turned out to be the actual rover Pi 3B.

### Blocker 4 — Boot loop with a multicolor screen, WiFi never connecting

**Symptom:** the Pi powered on, briefly showed boot text, flashed a multicolor screen, then restarted — repeating endlessly. WiFi never came up because the Pi never finished booting.

**Cause:** insufficient power. The Pi was being powered from a Mac's USB port, which supplies roughly 0.5–0.9A — well under the 2.5A the Pi 3B needs. The multicolor screen is the Pi's built-in low-voltage warning.

**Fix:** switched to a proper 5V/2.5A wall charger (a phone charger plugged into a wall socket, not a computer's USB port). The Pi booted normally on the first attempt afterward.

> **Rule going forward:** Never power the Pi 3B from a laptop or Mac USB port. Always use a wall charger rated at least 5V/2.5A. A Mac's USB port being able to charge a phone does not mean it can reliably power a Raspberry Pi.

### Blocker 5 — DHCP reservation didn't apply on the first reboot

**Symptom:** after configuring a DHCP reservation on the router and rebooting, the Pi came up on a different IP than the one reserved.

**Cause:** some routers only apply a new reservation on the next full DHCP renewal cycle, not immediately on the next reboot.

**Fix:** rather than chasing the exact reserved address, confirmed the Pi was reachable at whatever IP it actually received, and treated that as the working address for now. The reservation can be revisited later — what matters day to day is that the IP stays consistent across reboots, which it did.

### Blocker 6 — WiFi stopped working entirely after a sudden power loss

**Symptom:** the Pi had been working fine — connected, pingable, reachable over SSH — until power was cut unexpectedly. After that, it would boot, but `wlan0` stayed down, and key network configuration files (such as the `wpa_supplicant` config) were missing or empty entirely.

**Cause:** filesystem corruption caused by an abrupt power loss while the Pi was running. Linux can be mid-write to config files, logs, or filesystem journal entries at any moment — cutting power during that is what caused the corruption.

**Fix:** re-flashed the MicroSD card from scratch using the same Imager settings as before. This fully resolved it.

> **Rule going forward:** Never unplug the Pi's power while it's running. Always run `sudo shutdown -h now` first and wait for the green activity LED to stop blinking before disconnecting power. This single habit prevents this entire category of problem.
