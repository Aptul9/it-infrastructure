#!/usr/bin/env python3
import os
import sys
import subprocess
import argparse
from pathlib import Path

def read_inventory(inventory_path):
    """Read hosts from Ansible inventory file."""
    hosts = []
    try:
        with open(inventory_path, 'r') as f:
            for line in f:
                # Skip comments and empty lines
                line = line.strip()
                if line and not line.startswith(('#', '[')):
                    # Extract hostname/IP from potential ansible_host definition
                    host = line.split()[0]
                    if 'ansible_host=' in line:
                        for part in line.split():
                            if part.startswith('ansible_host='):
                                host = part.split('=')[1]
                    hosts.append(host)
    except Exception as e:
        print(f"Error reading inventory file: {e}")
        sys.exit(1)
    return hosts

def distribute_ssh_key(host, username, password, ssh_key_path="~/.ssh/id_rsa.pub"):
    """
    Distribute SSH key to a remote host using sshpass.
    Returns True if successful, False otherwise.
    """
    ssh_key_path = os.path.expanduser(ssh_key_path)
    
    if not os.path.exists(ssh_key_path):
        print(f"SSH key not found at {ssh_key_path}")
        return False
    
    try:
        # Ensure .ssh directory exists on remote host
        mkdir_cmd = f'sshpass -p "{password}" ssh -o StrictHostKeyChecking=no {username}@{host} "mkdir -p ~/.ssh"'
        subprocess.run(mkdir_cmd, shell=True, check=True, stderr=subprocess.PIPE)
        
        # Copy SSH key
        copy_cmd = f'sshpass -p "{password}" ssh-copy-id -i {ssh_key_path} -o StrictHostKeyChecking=no {username}@{host}'
        subprocess.run(copy_cmd, shell=True, check=True, stderr=subprocess.PIPE)
        
        print(f"Successfully copied SSH key to {host}")
        return True
        
    except subprocess.CalledProcessError as e:
        print(f"Error copying key to {host}: {e.stderr.decode() if e.stderr else str(e)}")
        return False

def main():
    parser = argparse.ArgumentParser(description='Distribute SSH keys to hosts in Ansible inventory')
    parser.add_argument('--inventory', '-i', required=True, help='Path to Ansible inventory file')
    parser.add_argument('--username', '-u', required=True, help='SSH username')
    parser.add_argument('--password', '-p', required=True, help='SSH password')
    parser.add_argument('--ssh-key', '-k', default='~/.ssh/id_rsa.pub', help='Path to SSH public key')
    
    args = parser.parse_args()
    
    # Check if sshpass is installed
    try:
        subprocess.run(['which', 'sshpass'], check=True, capture_output=True)
    except subprocess.CalledProcessError:
        print("Error: sshpass is not installed. Please install it first:")
        print("Ubuntu/Debian: sudo apt-get install sshpass")
        print("RHEL/CentOS: sudo yum install sshpass")
        print("macOS: brew install hudochenkov/sshpass/sshpass")
        sys.exit(1)
    
    # Read hosts from inventory
    hosts = read_inventory(args.inventory)
    if not hosts:
        print("No hosts found in inventory file")
        sys.exit(1)
    
    # Distribute keys
    success_count = 0
    for host in hosts:
        if distribute_ssh_key(host, args.username, args.password, args.ssh_key):
            success_count += 1
    
    print(f"\nKey distribution completed: {success_count}/{len(hosts)} successful")

if __name__ == "__main__":
    main()