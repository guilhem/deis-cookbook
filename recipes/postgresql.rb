node.set['postgresql']['enable_pgdg_apt'] = true
include_recipe 'postgresql::server'
include_recipe 'database::postgresql'

postgresql_connection_info = {
  :host     => '127.0.0.1',
  :port     => node['postgresql']['config']['port'],
  :username => 'postgres',
  :password => node['postgresql']['password']['postgres']
}

postgresql_database node['deis']['database']['name'] do
  connection postgresql_connection_info
  template 'template0'
  encoding 'utf8'
  tablespace 'DEFAULT'
  connection_limit '-1'
  owner node['deis']['database']['user']
  action :create
end

postgresql_database_user node['deis']['database']['user'] do
  connection    postgresql_connection_info
  database_name node['deis']['database']['name']
  privileges    [:all]
  action        :create
end
