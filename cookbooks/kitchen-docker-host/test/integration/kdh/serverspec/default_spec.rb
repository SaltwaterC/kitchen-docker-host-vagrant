require_relative 'spec_helper'

describe 'kitchen-docker-host::default' do
  %w(
    docker-engine
    squid
  ).each do |pkg|
    describe package(pkg) do
      it { is_expected.to be_installed }
    end
  end

  describe file('/lib/systemd/system/docker.service') do
    it { is_expected.to be_file }
    it { is_expected.to be_owned_by 'root' }
    it { is_expected.to be_grouped_into 'root' }
    it { is_expected.to be_mode '644' }
    it { is_expected.to contain 'ExecStart=/usr/bin/docker daemon --host=tcp://0.0.0.0:2375 --bip=172.17.42.1/16 --storage-opt dm.basesize=20G' }
  end

  describe file('/etc/squid/squid.conf') do
    it { is_expected.to be_file }
    it { is_expected.to be_owned_by 'root' }
    it { is_expected.to be_grouped_into 'root' }
    it { is_expected.to be_mode '644' }
    it { is_expected.to contain 'maximum_object_size 1024 MB' }
    it { is_expected.to contain 'cache_dir ufs /var/spool/squid 4096 16 256' }
    it { is_expected.to contain 'http_access allow all' }
    it { is_expected.to contain 'http_port 3128' }
  end

  %w(
    docker
    squid
  ).each do |srv|
    describe service(srv) do
      it { is_expected.to be_enabled }
      it { is_expected.to be_running }
    end
  end
end
