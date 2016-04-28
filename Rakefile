require 'os'

ENV['PATH'] = '/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin' unless OS.windows?

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
  rm_f Dir['vagrant-*.json']
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

desc 'Clears the Squid cache'
task :clear do
  system 'vagrant ssh -c "sudo service squid stop && sleep 5 && '\
  'sudo rm -rf /var/spool/squid && '\
  'sudo mkdir /var/spool/squid && '\
  'sudo chown squid:squid /var/spool/squid && '\
  'sudo squid -z && sleep 5 && sudo service squid start"'
end

task default: [:rubocop]
