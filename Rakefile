require_relative 'chef_version'

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
  system 'bundle exec kitchen destroy'
  rm_rf '.kitchen'
  rm_f %w(Berksfile.lock Gemfile.lock)
end

desc 'Clears the Squid cache'
task :clear do
  sh 'bundle exec kitchen exec -c "sudo service squid stop && sleep 5 && '\
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
    Rake::Task[:setup].invoke
  end
end

desc 'Alias of converge'
task provision: [:converge]

desc 'Recreates the machine from scratch and drops to a shell'
task redo: [:clean, :provision, :ssh]

desc 'Reloads the box'
task :reload do
  kitchen_vagrant_exec 'reload'
end

begin
  # Rubocop stuff
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
rescue LoadError
  STDERR.puts 'Rubocop, or one of its dependencies, is not available.'
end

desc 'Install dependencies'
task :setup do
  sh 'bundle install'
end

desc 'Login onto the box'
task :ssh do
  sh 'bundle exec kitchen login'
end

desc 'Alias of converge'
task up: [:converge]

## Test Kitchen specific

desc 'kitchen converge'
task converge: [:setup] do
  kitchen_vagrant_exec 'up' unless Dir['.kitchen/**/Vagrantfile'].empty?
  sh 'bundle exec kitchen converge'
end

desc 'kitchen verify'
task verify: [:setup] do
  sh 'bundle exec kitchen verify'
end

desc 'kitchen verify && rubocop && foodcritic'
task test: [:converge, :verify, :rubocop, :foodcritic]

desc 'Runs foodcritic'
task :foodcritic do
  sh "bundle exec foodcritic --chef-version #{CHEF_VERSION} --progress --epic-fail any ."
end
