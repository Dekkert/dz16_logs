#!/bin/bash
sudo su

yum install -y vim


cp /usr/share/zoneinfo/Europe/Moscow /etc/localtime

systemctl restart chronyd
yum install -y epel-release
yum update
yum install -y nginx
systemctl start nginx
systemctl enable nginx
