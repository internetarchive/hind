#!/bin/bash -ex

# Installs latest stable docker-ce version for current ubuntu OS.

[ "$( docker -v 2> /dev/null )" = "" ]  ||  echo 'docker already installed - exiting'
[ "$( docker -v 2> /dev/null )" = "" ]  ||  exit 0

sudo apt-get -yqq update
sudo apt-get -yqq install   ca-certificates   curl   gnupg

curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list

sudo apt-get -yqq update

sudo apt-get -yqq install docker-ce
