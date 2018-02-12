# chatter
An IRC client for Ubuntu devices created by Robert Ancell.
https://launchpad.net/chatter

How to build :

cd chatter
docker run -it -v ${PWD}:/chatter clickable/ubuntu-sdk:15.04-armhf bash

while inside the container

export QT_SELECT=qt5
apt-get install jq
cd /chatter
make version.h
make irc_client_moc.cpp
make all
make click
