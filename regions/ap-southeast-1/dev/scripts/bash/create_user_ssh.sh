#!/bin/bash
PASSWORD="P@ssw0rd12"
useradd -m localpwn
echo "localpwn:$PASSWORD" | chpasswd