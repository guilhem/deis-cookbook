
docker_image node.deis.logger.repository do
  repository node.deis.logger.repository
  tag node.deis.logger.tag
  action node.deis.autoupgrade ? :pull : :pull_if_missing
  cmd_timeout node.deis.logger.image_timeout
  notifies :redeploy, "docker_container[#{node.deis.logger.container}]", :immediately
end

docker_container node.deis.logger.container do
  container_name node.deis.logger.container
  detach true
  env ["ETCD=#{node.deis.public_ip}:#{node.deis.etcd.port}",
       "HOST=#{node.deis.public_ip}",
       "PORT=#{node.deis.logger.port}"]
  image "#{node.deis.logger.repository}:#{node.deis.logger.tag}"
  volume VolumeHelper.logger(node)
  port "#{node.deis.logger.port}:#{node.deis.logger.port}"
end

ruby_block 'wait-for-logger' do
  block do
    EtcdHelper.wait_for_key(
      node.deis.public_ip,
      node.deis.etcd.port,
      '/deis/logs/host',
      60
    )
  end
end
