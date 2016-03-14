# kitchen-docker-host::default

package 'postfix' do
  action :remove
end

include_recipe 'yum-epel::default'
include_recipe 'yum::default'

yum_repository 'docker' do
  description 'Docker Project YUM repository'
  baseurl 'http://yum.dockerproject.org/repo/main/centos/7'
  gpgkey 'http://yum.dockerproject.org/gpg'
  action :create
end

pkg = %w(
  htop
  squid
  docker-engine
)
package pkg

execute 'systemctl daemon-reload' do
  action :nothing
end

cookbook_file '/lib/systemd/system/docker.service' do
  source 'lib.systemd.system.docker.service'
  owner 'root'
  group 'root'
  mode 0644
  notifies :run, 'execute[systemctl daemon-reload]', :immediately
  notifies :restart, 'service[docker]', :delayed
end

cookbook_file '/etc/squid/squid.conf' do
  source 'etc.squid.squid.conf'
  owner 'root'
  group 'root'
  mode 0644
  notifies :restart, 'service[squid]', :delayed
end

%w(
  docker
  squid
).each do |serv|
  service serv do
    action [:enable, :start]
  end
end

selinux_state 'SELinux Disabled' do
  action :disabled
end

cookbook_file '/etc/sysctl.d/10-bridge-nf-call.conf' do
  source 'etc.sysctl.d.10-bridge-nf-call.conf'
  owner 'root'
  group 'root'
  mode 0644
  notifies :run, 'execute[sysctl-p]', :immediately
end

execute 'sysctl-p' do
  command 'sysctl -p'
  action :nothing
end

execute 'reboot' do
  only_if 'test -d /sys/fs/selinux'
end
