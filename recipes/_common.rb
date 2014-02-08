#
# Cookbook Name:: deis
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

home_dir = node['deis']['dir']
username = node['deis']['username']

# create deis user with ssh access, auth keys
# and the ability to run 'sudo chef-client'

user username do
  system true
  uid 324 # "reserved" for deis
  shell '/bin/bash'
  comment 'deis system account'
  home home_dir
  supports :manage_home => true
  action :create
end

sudo "deis" do
  user username
  nopasswd true
  commands ['/usr/bin/chef-client',
            '/bin/cat /etc/chef/client.pem',
            '/bin/cat /etc/chef/validation.pem',
            '/sbin/restart deis-server',
            '/sbin/restart deis-worker',]
end

# create a log directory writeable by the deis user

directory node['deis']['log_dir'] do
  user username
  group group
  mode 0755
end

include_recipe "apt"

# always install these packages

include_recipe 'fail2ban'

include_recipe 'git'

node.default['build_essential']['compiletime'] = true
include_recipe 'build-essential'

include_recipe 'python'

package 'debootstrap'
