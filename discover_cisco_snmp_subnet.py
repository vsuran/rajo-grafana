#!/usr/bin/env python3

import subprocess
import yaml
import re
import sys

# ========================
# CONFIG
# ========================

SUBNETS = [
    "10.0.99.0/24",
    # "10.1.0.0/24",
]

SNMP_COMMUNITY = "public"
SNMP_VERSION = "2c"
SNMP_TIMEOUT = 2

OUTPUT_FILE = "/etc/prometheus/targets/cisco-switches.yml"

DEFAULT_LABELS = {
    "job": "cisco_snmp",
    "role": "cisco-switch",
    "site": "dc1"
}

CISCO_OID_PREFIX = "1.3.6.1.4.1.9"

# ========================
# FUNCTIONS
# ========================

def nmap_snmp_hosts(subnet):
    """
    Returns list of IPs with UDP/161 open
    """
    cmd = [
        "nmap",
        "-n",
        "-Pn",
        "-sU",
        "-p", "161",
        "--open",
        subnet
    ]

    try:
        output = subprocess.check_output(cmd, stderr=subprocess.DEVNULL).decode()
    except subprocess.CalledProcessError:
        return []

    ips = re.findall(r"Nmap scan report for ([0-9\.]+)", output)
    return ips


def snmp_is_cisco(ip):
    cmd = [
        "snmpget",
        f"-v{SNMP_VERSION}",
        "-c", SNMP_COMMUNITY,
        "-t", str(SNMP_TIMEOUT),
        "-r", "1",
        ip,
        "1.3.6.1.2.1.1.2.0"
    ]

    try:
        output = subprocess.check_output(cmd, stderr=subprocess.DEVNULL).decode()
        return CISCO_OID_PREFIX in output
    except subprocess.CalledProcessError:
        return False


# ========================
# MAIN
# ========================

targets = []

for subnet in SUBNETS:
    print(f"Scanning {subnet}...")
    for ip in nmap_snmp_hosts(subnet):
        if snmp_is_cisco(ip):
            print(f"  [+] Cisco switch found: {ip}")
            targets.append({
                "targets": [ip],
                "labels": DEFAULT_LABELS
            })

if targets:
    with open(OUTPUT_FILE, "w") as f:
        yaml.safe_dump(targets, f, default_flow_style=False)

    print(f"\nWritten {len(targets)} targets to {OUTPUT_FILE}")
else:
    print("\nNo Cisco devices found – output not updated")