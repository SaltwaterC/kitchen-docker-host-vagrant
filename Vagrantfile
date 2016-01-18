Vagrant.configure(2) do |config|
  config.berkshelf.enabled = true

  config.vm.box = 'opscode-centos-7.1'
  config.vm.box_url = 'https://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_centos-7.1_chef-provisionerless.box'
  config.vm.hostname = 'kitchen-docker-host'

  config.vm.provider 'virtualbox' do |vb|
    vb.name = 'kitchen-docker-host'
    vb.cpus = ENV['VB_CPUS'] || 4
    vb.memory = ENV['VB_MEM'] || 8192
    vb.customize ['modifyvm', :id, '--nictype1', 'virtio']
    vb.customize ['modifyvm', :id, '--nictype2', 'virtio']
  end

  config.vm.network 'private_network', ip: '192.168.99.100'

  config.vm.provision 'chef_zero' do |chef|
    chef.version = '12.6.0'
    chef.add_recipe 'kitchen-docker-host'
    chef.nodes_path = '.'
  end
end
