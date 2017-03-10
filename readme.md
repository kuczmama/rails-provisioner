# Configure Rails Server

This is a very opinionated rails server that will be provisioned with chef.  It uses.

- nginx
- unicorn
- rbenv
- redis
- postgres

So if you don't use that exact combination of packages it won't work for you.  Also it doesn't have much error
checking so use at your own risk.  I would advise against running twice (for now).

# Installation

Put it in your [rails_project]/config/

directory and run the init.sh script

Run init.sh as follows

./init.sh <user> <password> <ip> <port> <app-name>

ex:

`./init.sh deploy monkey123 127.0.0.1 12345 myapp`


## Before you run

1. Put `gem 'unicorn', '~> 5.2'` gem into your gemfile
2. ssh into your server at least once, and setup any default password
3. Setup ssh key for server with github or whatever git repository you want to use

eg.
./init.sh deploy monkey123 127.0.0.1 12345 myapp



This sets up your server username and password to be the same as your postgres username and password

Also the script may ask you for passwords, so don't just run it and forget it.

# Gotchas

- Make sure there is no default password on your server, and that you can ssh in before running the script
- You need to make sure you add your server's private key onto github
- if you use the wrong app name everything will break.  You might as well just start over