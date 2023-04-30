#!/bin/bash -eu

# Run this on each VM to setup /pv mounting your NFS server for Persistent Volumes

NFS_PV=${1:?"Usage: [NFS source specifier like: IP ADDRESS:MOUNT_DIR]"}

set -x
sudo mkdir -m777 -p /pv

sudo apt-get install -yqq nfs-common
echo "$NFS_PV /pv nfs proto=tcp,nosuid,hard,intr,actimeo=1,nofail,noatime,nolock,tcp 0 0" |sudo tee -a /etc/fstab
sudo mount /pv
