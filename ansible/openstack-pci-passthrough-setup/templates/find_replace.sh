#!/bin/bash
sudo sed -i '/alias =/s/'\''/\"/g' /etc/nova/nova.conf
sudo sed -i '/passthrough_whitelist =/s/'\''/\"/g' /etc/nova/nova.conf
