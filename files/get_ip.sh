#!/bin/bash

ip_address=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
subnet_size=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$(curl -s http://169.254.169.254/latest/meta-data/mac)/subnet-ipv4-cidr-block)

echo '{"ip_address":"'$ip_address'","subnet_size":"'$subnet_size'"}'

