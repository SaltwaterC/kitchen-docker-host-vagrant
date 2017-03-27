require_relative 'chef_version'

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
  STDERR.puts 'https://github.com/test-kitchen/test-kitchen/issues/350'
  exit 1
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
  STDERR.puts 'https://github.com/test-kitchen/kitchen-vagrant/issues/69'
  STDERR.puts 'https://github.com/test-kitchen/test-kitchen/issues/350'
  exit 1
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
