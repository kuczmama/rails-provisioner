# Configure Rails Server

This is a very opinionated rails server that will be provisioned with chef.  It uses.

- nginx
- unicorn
- rbenv
- redis
- postgres

So if you don't use that exact combination of packages it won't work for you

# Installation

Put it in your [rails_project]/config/

directory and run the init.sh script

This sets up your server username and password to be the same as your postgres username and password

