#!/usr/bin/env bash
# Run this script as root

mkdir -p /root/.local/bin/
cp -r bin/* /root/.local/bin/
cp systemd/* /etc/systemd/system/
systemctl daemon-reload
