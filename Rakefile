require 'os'

ENV['PATH'] = '/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin' unless OS.windows?

namespace 'install' do
  desc 'Installs OS X runtime dependencies; requires brew and caskroom'
  task :osx do
    sh 'brew cask install virtualbox'
    sh 'brew cask install vagrant'
    sh 'brew cask install chefdk'
    Rake::Task[:setup].invoke
  end
end

desc 'Installs Vagrant dependencies'
task :setup do
  sh 'vagrant plugin install vagrant-berkshelf'
  sh 'vagrant plugin install vagrant-vbguest'
end

desc 'Runs "vagrant up"'
task :up do
  sh 'vagrant up'
end

desc 'Runs "vagrant halt"'
task :halt do
  sh 'vagrant halt'
end

desc 'Runs "vagrant destroy"'
task :clean do
  sh 'vagrant destroy -f'
  rm_rf '.vagrant'
  rm_f Dir['vagrant-*.json']
  rm_f 'kitchen-docker-host.json'
end

desc 'Runs "vagrant ssh"'
task :ssh do
  system 'vagrant ssh'
end

desc 'Recreates the machine from scratch and drops to a shell'
task redo: [:clean, :up, :ssh]

desc 'Runs "vagrant reload"'
task :reload do
  sh 'rm .vagrant/machines/default/virtualbox/synced_folders'
  sh 'vagrant reload --provision'
end

desc 'Runs "vagrant provision"'
task :provision do
  sh 'vagrant provision'
end

desc 'Clears the Squid cache'
task :clear do
  sh 'vagrant ssh -c "sudo service squid stop && sleep 5 && '\
  'sudo rm -rf /var/spool/squid && '\
  'sudo mkdir /var/spool/squid && '\
  'sudo chown squid:squid /var/spool/squid && '\
  'sudo squid -z && sleep 5 && sudo service squid start"'
end

begin
  # Rubocop stuff
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
rescue LoadError
  STDERR.puts 'Rubocop, or one of its dependencies, is not available.'
end

task default: [:rubocop]
