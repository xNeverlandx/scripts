#!/bin/bash

#install cli and configure
sudo apt-get install awscli
aws configure

#install jq to parse JSON results returned by the AWS CLI
sudo apt install jq

#chronic to suppress output unless there's a non-zero exit code
sudo apt install moreutils

#kops to create the actual kubernetes cluster
wget https://github.com/kubernetes/kops/releases/download/1.6.2/kops-linux-amd64
chmod +x kops-linux-amd64
sudo mv kops-linux-amd64 /usr/local/bin/kops
