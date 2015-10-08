ENV['PATH'] = '/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin'

desc 'Runs "rubocop"'
task :rubocop do
  system 'rubocop'
end

desc 'Runs "vagrant up"'
task :up do
  system 'vagrant up'
end

desc 'Runs "vagrant halt"'
task :halt do
  system 'vagrant halt'
end

desc 'Runs "vagrant destroy"'
task :clean do
  system 'vagrant destroy -f'
  rm_rf '.vagrant'
end

desc 'Runs "vagrant ssh"'
task :ssh do
  system 'vagrant ssh'
end

desc 'Recreates the machine from scratch and drops to a shell'
task redo: [:clean, :up, :ssh]

desc 'Runs "vagrant reload"'
task :reload do
  system 'rm .vagrant/machines/default/virtualbox/synced_folders'
  system 'vagrant reload --provision'
end

desc 'Runs "vagrant provision"'
task :provision do
  system 'vagrant provision'
end

desc 'Purges the Vagrant box'
task :purge do
  system 'vagrant ssh -c "sudo purge"'
end

desc 'Packages the Vagrant box'
task :package do
  system 'vagrant package --output kitchen-docker-host-0.1.1.box'
end

task default: [:rubocop]

desc 'Does a Kitchen Docker Host Vagrant box release'
task release: [:up, :purge, :package]
