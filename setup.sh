#!/bin/bash

#install openresty
sudo wget https://openresty.org/package/amazon/openresty.repo
sudo mv openresty.repo /etc/yum.repos.d/
sudo yum check-update
sudo yum install -y openresty

#setup nginx location behavior
sudo mkdir /usr/local/openresty/nginx/scripts
aws s3 cp s3://assessment-temp-bucket/files/get_ip.sh /usr/local/openresty/nginx/scripts/get_ip.sh
sudo chmod 755 -R /usr/local/openresty/nginx/scripts
aws s3 cp s3://assessment-temp-bucket/files/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
sudo chmod 644 /usr/local/openresty/nginx/conf/nginx.conf
sudo systemctl start openresty

#setup cloudwatch config
sudo yum install amazon-cloudwatch-agent -y
sudo aws s3 cp s3://assessment-temp-bucket/files/file-config.json /opt/aws/amazon-cloudwatch-agent/etc/file-config.json
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:///opt/aws/amazon-cloudwatch-agent/etc/file-config.json


