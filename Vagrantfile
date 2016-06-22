Vagrant.require_version '>= 1.8.0'
Vagrant.configure(2) do |config|
  chef_version = '12.11.18'
  hostname = 'kitchen-docker-host'

  config.berkshelf.enabled = true

  config.vm.box = 'centos/7'
  config.vm.hostname = hostname

  config.vm.provider 'virtualbox' do |vb|
    vb.name = hostname
    vb.cpus = ENV['VB_CPUS'] || 4
    vb.memory = ENV['VB_MEM'] || 8192
    vb.customize ['modifyvm', :id, '--nictype1', 'virtio']
    vb.customize ['modifyvm', :id, '--nictype2', 'virtio']
  end

  config.vm.network 'private_network', ip: '192.168.99.100'

  config.vm.provision 'shell', inline: "curl -L https://www.chef.io/chef/install.sh | sudo bash -s -- -v #{chef_version}"

  config.vm.provision 'chef_zero' do |chef|
    chef.version = chef_version
    chef.add_recipe 'kitchen-docker-host'
    chef.nodes_path = '.'
  end
end
