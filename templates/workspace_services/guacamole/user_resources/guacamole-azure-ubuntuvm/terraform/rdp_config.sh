#!/bin/bash
NEXUS_URL="https://nexus-${tre_id}.azurewebsites.net"
sudo rm -r /var/lib/apt/lists/*
sudo rm /etc/apt/sources.list
echo "deb [trusted=yes] $NEXUS_URL/repository/ubuntu-proxy-repo bionic main restricted universe multiverse" >> /etc/apt/sources.list
echo "deb [trusted=yes] $NEXUS_URL/repository/ubuntu-proxy-repo bionic-updates main restricted universe multiverse" >> /etc/apt/sources.list
echo "deb [trusted=yes] $NEXUS_URL/repository/ubuntu-security-proxy-repo bionic main restricted universe multiverse" >> /etc/apt/sources.list
echo "deb [trusted=yes] $NEXUS_URL/repository/ubuntu-security-proxy-repo bionic-updates main restricted universe multiverse" >> /etc/apt/sources.list
echo "deb [trusted=yes] $NEXUS_URL/repository/pypi-proxy-repo bionic main restricted universe multiverse" >> /etc/apt/sources.list
sudo apt-get update
if [ ${image} != "Ubuntu 18.04 Data Science VM" ]; then
  sudo DEBIAN_FRONTEND=noninteractive apt-get install ubuntu-gnome-desktop -yq
fi
sudo apt-get install xrdp -y
sudo adduser xrdp ssl-cert
sudo sed -i 's|!/bin/sh|!/bin/bash|g' /etc/xrdp/startwm.sh
sudo systemctl enable xrdp
