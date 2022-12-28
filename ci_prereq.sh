#!/bin/sh

sudo add-apt-repository ppa:dosemu2/ppa

sudo apt update -q

sudo apt install -y \
  dosemu2 \
  fdpp \
  comcom32

