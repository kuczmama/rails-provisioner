#!/bin/sh

# check for correct number of arguments
if [ $# -ne 6 ]; then
echo "Usage: $0 <user> <password> <ip> <port> <app-name> <git-repo>"
exit 1
fi

# set variables
USER=$1
PASSWORD=$2
IP=$3
PORT=$4
APP_NAME=$5
GIT_REPO=$6
password_hash=$(openssl passwd -1 "${PASSWORD}" | sed -e 's/[\/&]/\\&/g')


echo "Using password hash: ${password_hash}"
# Rename node/default
#
# Replace port, username, password, pg_username, and pg_password
# Create a new file named {IP}.json
cp chef/nodes/default.json chef/nodes/${IP}.json
sed -i -e "s/default_port/${PORT}/g" chef/nodes/${IP}.json
sed -i -e "s/default_user/${USER}/g" chef/nodes/${IP}.json
sed -i -e "s/default_password/${password_hash}/g" chef/nodes/${IP}.json
sed -i -e "s/default_pg_user/${USER}/g" chef/nodes/${IP}.json
sed -i -e "s/default_pg_password/${PASSWORD}/g" chef/nodes/${IP}.json
rm chef/nodes/${IP}.json-e #idk why this file is created

# replace appname
sed -i -e "s/default_app_name/${APP_NAME}/g" chef/site-cookbooks/rails-server/attributes/default.rb
rm chef/site-cookbooks/rails-server/attributes/default.rb-e

if [ ! -f ~/.ssh/id_rsa.pub ]; then
	echo "ssh key doesn't exist create one at ~/.ssh/id_rsa.pub"
	ssh-keygen -t rsa -b 4096
fi

# # upload key for root
echo "Uploading ssh key for root"
ssh-copy-id -i ~/.ssh/id_rsa.pub root@$IP

# # install chef
echo "Instaling chef"
cd chef && knife solo prepare root@$IP

# # execute the run list
knife solo cook root@$IP

# upload key for user
ssh-copy-id -i ~/.ssh/id_rsa.pub $USER@$IP


ssh root@${IP} "mkdir /home/${USER}/.ssh && cp -rf .ssh/* /home/${USER}/.ssh && chown -R ${USER} /home/${USER}/.ssh" 

# Install and configure capistrano
if [ -f deploy.rb ]
then
	echo "Capistrano already exists... Ignoring the intall"
else
	gem install capistrano
	# Make sure the install is in the main app directory

	echo "Running cap install from ${pwd}"
	# .. 3 times because I'm in the chef directory
	cd ../../.. && cap install
	cd config


	# configure production.rb
cat <<EOT >> deploy/production.rb
	set :stage, :production
	set :rails_env, :production

	server "#{fetch(:deploy_user)}@${IP}", roles: %w{web app db}, primary: true

	set :ssh_options, {
	keys: %w(/home/${whoami}/.ssh/id_rsa),
	forward_agent: false,
	auth_methods: %w(password)
	}
EOT

cat <<EOT>> deploy.rb
	lock "3.7.2"


	set :application, '${APP_NAME}'
	set :repo_url, "${GIT_REPO}"

	set :deploy_to, "/var/www/#{fetch(:application)}"
	set :deploy_user, "${USER}"

	set :rbenv_type, :user
	set :rbenv_ruby, '2.4.0'
	set :rbenv_prefix, "RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"
	set :rbenv_map_bins, %w{rake gem bundle ruby rails}
	set :rbenv_roles, :all

	set :linked_files, %w{config/database.yml config/application.yml}
	set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

	set :keep_releases, 5
EOT

	cp rails-provisioner/deploy.rake ../lib/capistrano/tasks/
	cp rails-provisioner/setup.rake ../lib/capistrano/tasks/
fi

# # # upload app
# cd ../.. && cap production setup:all
cd .. && cap production deploy

# restart nginx
ssh -p $PORT -t $USER@$IP 'sudo service nginx restart'


