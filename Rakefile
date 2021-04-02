# frozen_string_literal: true

require_relative 'cinc_version'

# workaround for https://github.com/test-kitchen/kitchen-vagrant/issues/69
# and https://github.com/test-kitchen/test-kitchen/issues/350
def kitchen_vagrant_exec(cmd)
  vdirs = Dir['.kitchen/**/Vagrantfile'].map { |dir| File.dirname dir }
  vdirs.each do |vd|
    Dir.chdir(vd) do
      sh "vagrant #{cmd}"
    end
  end
end

## Tasks ported from the previous vagrant-berkshelf implementation

desc 'kitchen destroy and cleanup'
task :clean do
  system 'kitchen destroy'
  rm_rf '.kitchen'
  rm_f %w[Berksfile.lock Gemfile.lock]
end

desc 'Clears the Squid cache'
task :clear do
  sh 'kitchen exec -c "sudo service squid stop && sleep 5 && '\
  'sudo rm -rf /var/spool/squid && '\
  'sudo mkdir /var/spool/squid && '\
  'sudo chown squid:squid /var/spool/squid && '\
  'sudo squid -z && sleep 5 && sudo service squid start"'
end

desc 'Halts the box'
task :halt do
  kitchen_vagrant_exec 'halt'
end

namespace 'install' do
  desc 'Installs OS X runtime dependencies; requires brew and caskroom'
  task :osx do
    sh 'brew cask install virtualbox'
    sh 'brew cask install vagrant'
    sh 'brew cask install chefdk'
  end
end

desc 'Alias of converge'
task provision: %i[converge]

desc 'Recreates the machine from scratch and drops to a shell'
task redo: %i[clean provision ssh]

desc 'Reloads the box'
task :reload do
  kitchen_vagrant_exec 'reload'
end

desc 'Login onto the box'
task :ssh do
  sh 'kitchen login'
end

desc 'Alias of converge'
task up: %i[converge]

## Test Kitchen specific

desc 'kitchen converge'
task :converge do
  kitchen_vagrant_exec 'up' unless Dir['.kitchen/**/Vagrantfile'].empty?
  sh 'kitchen converge'
end

desc 'kitchen verify'
task :verify do
  sh 'kitchen verify'
end

desc 'kitchen verify && cookstyle'
task test: %i[converge verify cookstyle]

desc 'Runs cookstyle'
task :cookstyle do
  sh 'cookstyle'
end

desc 'Runs static code analysis tools'
task lint: %i[cookstyle]
