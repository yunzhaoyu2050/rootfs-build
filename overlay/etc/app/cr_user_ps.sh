#!/bin/bash

# create user and passwd
username=$1
password=$2

pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
useradd -G sudo -m -p $pass $username -s /bin/bash
[ $? -eq 0 ] && echo "add user:$username and pass:$password to system." || echo "add $username failed."
