Vagrant.configure('2') do |config|
  # workaround Vagrant #7610 https://github.com/mitchellh/vagrant/issues/7610
  config.ssh.insert_key = false if Vagrant::VERSION == '1.8.5'
end
