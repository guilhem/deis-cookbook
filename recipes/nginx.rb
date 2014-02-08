#
# Cookbook Name:: deis-proxy
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

node.default['nginx']['default_site_enabled'] = false

include_recipe 'nginx'
