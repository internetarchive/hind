#!/bin/bash -exu

# really nice `ctop` - a container monitoring more specialized version of `top`
# https://github.com/bcicen/ctop

curl -fsSL https://azlux.fr/repo.gpg.key \
  | sudo gpg --dearmor -o /usr/share/keyrings/azlux-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/azlux-archive-keyring.gpg] http://packages.azlux.fr/debian \
  stable main" | sudo tee /etc/apt/sources.list.d/azlux.list >/dev/null

sudo apt-get -yqq update
sudo apt-get install -yqq docker-ctop
