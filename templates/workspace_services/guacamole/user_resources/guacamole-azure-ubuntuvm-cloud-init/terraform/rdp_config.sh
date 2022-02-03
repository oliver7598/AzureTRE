#!/bin/bash
NEXUS_URL="https://nexus-${tre_id}.azurewebsites.net"
sudo rm -r /var/lib/apt/lists/*
sudo rm /etc/apt/sources.list
echo "deb [trusted=yes] $NEXUS_URL/repository/ubuntu-proxy-repo bionic main restricted universe multiverse" >> /etc/apt/sources.list
echo "deb [trusted=yes] $NEXUS_URL/repository/ubuntu-proxy-repo bionic-updates main restricted universe multiverse" >> /etc/apt/sources.list
echo "deb [trusted=yes] $NEXUS_URL/repository/ubuntu-security-proxy-repo bionic main restricted universe multiverse" >> /etc/apt/sources.list
echo "deb [trusted=yes] $NEXUS_URL/repository/ubuntu-security-proxy-repo bionic-updates main restricted universe multiverse" >> /etc/apt/sources.list
echo "deb [trusted=yes] $NEXUS_URL/repository/ubuntu-packages-proxy-repo bionic main restricted universe multiverse" >> /etc/apt/sources.list
echo "deb [trusted=yes] $NEXUS_URL/repository/ubuntu-packages-proxy-repo bionic-updates main restricted universe multiverse" >> /etc/apt/sources.list
echo "deb [trusted=yes] $NEXUS_URL/repository/pypi-proxy-repo bionic main restricted universe multiverse" >> /etc/apt/sources.list
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install ubuntu-gnome-desktop -yq
sudo apt-get install xrdp -y
sudo adduser xrdp ssl-cert
sudo systemctl enable xrdp
