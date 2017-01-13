# monkey-patch vagrant-berkshelf #305 https://github.com/berkshelf/vagrant-berkshelf/issues/305
module VagrantPlugins
  module Berkshelf
    module Action
      class Check < Base
        send(:remove_const, :BERKS_REQUIREMENT) if const_defined?(:BERKS_REQUIREMENT)
        BERKS_REQUIREMENT = ">= 4.0"
      end
    end
  end
end

Vagrant.require_version '>= 1.8.0'
Vagrant.configure(2) do |config|
  chef_version = '12.16.42'
  hostname = 'kitchen-docker-host'

  # workaround Vagrant #7610 https://github.com/mitchellh/vagrant/issues/7610
  config.ssh.insert_key = false if Vagrant::VERSION == '1.8.5'

  config.berkshelf.enabled = true

  config.vm.box = 'bento/centos-7.3'
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
