# kitchen-docker-host::default

package 'postfix' do
  action :remove
end

include_recipe 'yum-epel::default'

pkg = %w(
  htop
  squid
)
package pkg

docker_service 'default' do
  host %w(tcp://0.0.0.0:2375)
  bip '172.17.42.1/16'
  action [:create, :start]
end

cookbook_file '/etc/squid/squid.conf' do
  source 'etc.squid.squid.conf'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[squid]', :delayed
end

service 'squid' do
  action [:enable, :start]
end

selinux_state 'SELinux Disabled' do
  action :disabled
end

cookbook_file '/etc/sysctl.d/10-bridge-nf-call.conf' do
  source 'etc.sysctl.d.10-bridge-nf-call.conf'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :run, 'execute[sysctl-p]', :immediately
end

execute 'sysctl-p' do
  command 'sysctl -p'
  action :nothing
end

execute 'reboot' do
  only_if 'test -d /sys/fs/selinux'
end
