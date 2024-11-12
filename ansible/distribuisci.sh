@echo off
#!/bin/bash
echo Testo i server in inventario hosts.ini, se non va a buon fine interrompi!
ansible all -m ping -i ./inventory/hosts.ini
pause

sudo apt-get install sshpass -y
chmod +x distribute_ssh_keys.py
./distribute_ssh_keys.py -i ./inventory/hosts.ini -u root -p your_password


