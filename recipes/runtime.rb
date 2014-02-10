include_recipe 'rsyslog::client'
include_recipe 'deis::docker'

directory node.deis.runtime.dir do
  user node.deis.username
  group node.deis.group
  mode 0700
end

directory node.deis.runtime.slug_dir do
  user node.deis.username
  group node.deis.group
  mode 0700
end

git node.deis.runtime.runner_dir do
  user node.deis.username
  group node.deis.group
  repository node.deis.runtime.repository
  revision node.deis.runtime.revision
  action :sync
end

bash 'create-slugrunner-image' do
  cwd node.deis.runtime.runner_dir
  code 'docker build -t deis/slugrunner .'
  not_if 'docker images | grep deis/slugrunner'
end

# TODO: add back when https://github.com/dotcloud/docker/issues/643 is fixed
# bash 'clear-docker-containers' do
#  code 'docker rm `docker ps -a -q`'
#  action :nothing
#  subscribes :run, 'bash[create-slugrunner-image]', :immediately
# end

package 'curl'

formations = data_bag('deis-formations')

services = []
active_slug_paths = []
formations.each do |f|

  formation = data_bag_item('deis-formations', f)

  # skip this node if it's not part of this formation
  next unless formation['nodes'].keys.include(node.name)
  # skip this node if it's not part of the runtime
  next unless formation['nodes'][node.name]['runtime'] == true

  formation['apps'].each_pair do |app_id, app|

    # skip this app if there's an empty release or build
    next if app['release'] == {}
    next if app['release']['build'] == {}

    version = app['release']['version']
    build = app['release']['build']
    config = app['release']['config']

    # if build is specified, use special heroku-style runtime

    if build.key? 'url'

      slug_url = build['url']

      # download the slug to a tempdir
      slug_root = node.deis.runtime.slug_dir
      slug_path = "#{slug_root}/#{app_id}-v#{version}.tar.gz"
      slug_dir = "#{slug_root}/#{app_id}-v#{version}"

      bash "download-slug-#{app_id}-#{version}" do
        cwd slug_root
        code <<-EOF
          rm -rf #{slug_dir}
          mkdir -p #{slug_dir}
          cd #{slug_dir}
          curl -s #{slug_url} > #{slug_path}
          tar xfz #{slug_path}
          rm #{slug_path}
          EOF
        not_if "test -d #{slug_dir}"
      end

      # will prevent deleted these in the SLUG_DIR step
      active_slug_paths.push("#{app_id}-v#{version}")

    end

    # iterate over this application's process formation by
    # Procfile-defined type

    app['containers'].each_pair do |c_type, c_formation|

      c_formation.each_pair do |c_num, node_port|

        nodename, port = node_port.split(':')

        next if nodename != node.name

#         # determine build command, if one exists
#         if build != {}
#           command = build['procfile'][c_type]
#         else
#           command = nil # assume command baked into docker image
#         end
        name = "#{app_id}.#{c_type}.#{c_num}"
        # define the container
        container name do
          app_name app_id
          c_type c_type
          c_num c_num
          env config
          port port
          image 'deis/slugrunner'
          slug_dir slug_dir
        end
        services.push("deis-#{name}")
      end
    end
  end # formations['apps'].each
end # formations.each

# remove old slug dirs
slug_root = node.deis.runtime.slug_dir
if Dir.exists?(slug_root)
  Dir.entries(slug_root).each do |f|
    next if f == '.'
    next if f == '..'

    slug_dir = "#{slug_root}/#{f}"

    directory slug_dir do
      action :delete
      recursive true
      not_if { active_slug_paths.include? f }
    end
  end
end

#
# # purge old container services
#
targets = []
Dir.glob("/etc/init/deis-*").each do |path|
  svc = File.basename(path, '.conf')
  next if svc.start_with? 'deis-server'
  next if svc.start_with? 'deis-worker'
  next if services.include? svc
  s = service svc do
    provider Chef::Provider::Service::Upstart
    action :nothing
  end
  f = file path do
    action :nothing
  end
  targets.push([s, f])
end

unless targets.empty?
  Thread.abort_on_exception = true
  ruby_block "stop-services-in-parallel" do
    block do
      threads = []
      targets.each do |s, f|
        threads << Thread.new do |t|
          s.run_action(:stop)
          f.run_action(:delete)
        end
      end
      threads.each { |t| t.join }
    end
  end
end
