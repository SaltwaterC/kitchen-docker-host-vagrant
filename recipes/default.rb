# kitchen-docker-host::default

package 'postfix' do
  action :remove
end

include_recipe 'sysctl::default'
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

%w(
  net.ipv4.ip_forward
  net.ipv6.conf.all.forwarding
  net.bridge.bridge-nf-call-iptables
  net.bridge.bridge-nf-call-ip6tables
).each do |param|
  sysctl_param param do
    value 1
  end
end
