# Linode

An easy way to setup a server is to make use of a StackScript. Once such a
script is created it can be used to *Deploy New Linode* systems. See the
following code for an example of such a script:

	#!/bin/bash -e

	useradd -m commander
	echo "commander ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
	visudo -c
	cp -R /root/.ssh /home/commander/.ssh
	chown -R commander:commander /home/commander/.ssh

This creates a new user (which is used by the playbook). It also copies all SSH
keys so that login should work. The playbook disables `root` login. This is why
a new user is needed.

Select `ubuntu20.04` as the target image when creating the StackScript.
