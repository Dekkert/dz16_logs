#!/bin/bash
sudo su

yum install -y vim


cp /usr/share/zoneinfo/Europe/Moscow /etc/localtime

systemctl restart chronyd
