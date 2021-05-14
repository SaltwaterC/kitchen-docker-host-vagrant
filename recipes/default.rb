# frozen_string_literal: true

# kitchen-docker-host::default

package 'postfix' do
  action :remove
end

package 'oracle-epel-release-el8'

package %w[htop squid bc]

docker_service 'default' do
  host %w[tcp://0.0.0.0:2375]
  bip '172.17.42.1/16'
  storage_driver 'devicemapper'
  storage_opts %w[dm.basesize=20G]
  action %i[create start]
end

cookbook_file '/etc/squid/squid.conf' do
  source 'etc/squid/squid.conf'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[squid]', :delayed
end

service 'squid' do
  action %i[enable start]
end

%w[
  net.ipv4.ip_forward
  net.ipv6.conf.all.forwarding
  net.bridge.bridge-nf-call-iptables
  net.bridge.bridge-nf-call-ip6tables
].each do |param|
  sysctl param do
    value 1
    notifies :restart, 'service[docker]', :delayed
  end
end

%w[init-zram-swapping end-zram-swapping].each do |zram_script|
  cookbook_file "/usr/bin/#{zram_script}" do
    source "usr/bin/#{zram_script}"
    owner 'root'
    group 'root'
    mode '0755'
    notifies :restart, 'systemd_unit[zram-config.service]', :delayed
  end
end

systemd_unit 'zram-config.service' do
  content(
    {
      'Unit' => {
        'Description' => 'Initializes',
      },
      'Service' => {
        'ExecStart' => '/usr/bin/init-zram-swapping',
        'ExecStop' => '/usr/bin/end-zram-swapping',
        'Type' => 'oneshot',
        'RemainAfterExit' => 'true',
      },
      'Install' => {
        'WantedBy' => 'multi-user.target',
      },
    }
  )
  action %i[create enable start]
end

service 'firewalld' do
  action %i[stop disable]
  notifies :restart, 'service[docker]', :delayed
end

service 'docker' do
  action %i[enable start]
end

include_recipe 'selinux::disabled'
