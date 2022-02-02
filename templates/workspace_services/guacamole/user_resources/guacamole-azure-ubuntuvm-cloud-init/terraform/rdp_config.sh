#!/bin/bash
NEXUS_URL="https://nexus-${tre_id}.azurewebsites.net"
sudo rm -r /var/lib/apt/lists/*
sudo rm /etc/apt/sources.list
echo "deb [trusted=yes] $NEXUS_URL/service/rest/v1/repositories/apt/proxy/ubuntu-proxy-repo bionic main restricted" >>
echo "deb [trusted=yes] $NEXUS_URL/service/rest/v1/repositories/apt/proxy/ubuntu-proxy-repo bionic universe" >> /etc/apt/sources.list
echo "deb [trusted=yes] $NEXUS_URL/service/rest/v1/repositories/apt/proxy/ubuntu-proxy-repo bionic multiverse" >> /etc/apt/sources.list
echo "deb [trusted=yes] $NEXUS_URL/service/rest/v1/repositories/apt/proxy/ubuntu-security-proxy-repo bionic main restricted" >> /etc/apt/sources.list
echo "deb [trusted=yes] $NEXUS_URL/service/rest/v1/repositories/apt/proxy/ubuntu-security-proxy-repo bionic universe" >> /etc/apt/sources.list
echo "deb [trusted=yes] $NEXUS_URL/service/rest/v1/repositories/apt/proxy/ubuntu-security-proxy-repo bionic multiverse" >> /etc/apt/sources.list
echo "deb [trusted=yes] $NEXUS_URL/service/rest/v1/repositories/apt/proxy/ubuntu-packages-proxy-repo bionic main restricted" >> /etc/apt/sources.list
echo "deb [trusted=yes] $NEXUS_URL/service/rest/v1/repositories/apt/proxy/ubuntu-packages-proxy-repo bionic universe" >> /etc/apt/sources.list
echo "deb [trusted=yes] $NEXUS_URL/service/rest/v1/repositories/apt/proxy/ubuntu-packages-proxy-repo bionic multiverse" >> /etc/apt/sources.list
echo "deb [trusted=yes] $NEXUS_URL/service/rest/v1/repositories/apt/proxy/pypi-proxy-repo bionic main restricted" >> /etc/apt/sources.list
echo "deb [trusted=yes] $NEXUS_URL/service/rest/v1/repositories/apt/proxy/pypi-proxy-repo bionic universe" >> /etc/apt/sources.list
echo "deb [trusted=yes] $NEXUS_URL/service/rest/v1/repositories/apt/proxy/pypi-proxy-repo bionic multiverse" >> /etc/apt/sources.list
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install ubuntu-gnome-desktop -yq
sudo apt-get install xrdp -y
sudo adduser xrdp ssl-cert
sudo systemctl enable xrdp
sudo reboot
