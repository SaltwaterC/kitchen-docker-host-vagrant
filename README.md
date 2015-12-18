## About

Docker host as Vagrant box created with [kitchen-docker](https://github.com/portertech/kitchen-docker) in mind. Provides a Docker host and Squid as caching proxy. It doesn't have anything [Test Kitchen](http://kitchen.ci) specific per-se, but it provides a consistent development environment.

## Dependencies

 * [VirtualBox](https://www.virtualbox.org)
 * [Vagrant](https://www.vagrantup.com)
 * [ChefDK](https://downloads.chef.io/chef-dk/)
 * [vagrant-berkshelf](https://github.com/berkshelf/vagrant-berkshelf)
 * [Docker](https://www.docker.com) client

The vagrant-berkshelf plugin may be easily installed with:

```bash
vagrant plugin install vagrant-berkshelf
```

## How to use

For starting the VM, simply issue a `vagrant up` command in the root directory of this project. If you want to use the bundled Rake tasks, you'll need to run `bundle install` first.

By default, it uses 4 virtual cores and 8192 GB of RAM. You may either edit the supplied Vagrantfile or export VB_CPUS and / or VB_MEM environment variables with the desired values.

The VM itself uses a host-only network adapter with the IP address 192.168.99.100. This makes it sort of a drop-in replacement for docker-machine. The Docker socket isn't TLS enabled though.

To tell the Docker client where to find the host, simply:

```bash
export DOCKER_HOST=tcp://192.168.99.100:2375
```

To check that the Docker connection is OK:

```bash
docker info
Containers: 0
Images: 0
Storage Driver: devicemapper
 Pool Name: docker-253:0-68062095-pool
 Pool Blocksize: 65.54 kB
 Backing Filesystem: xfs
 Data file: /dev/loop0
 Metadata file: /dev/loop1
 Data Space Used: 1.821 GB
 Data Space Total: 107.4 GB
 Data Space Available: 38.24 GB
 Metadata Space Used: 1.479 MB
 Metadata Space Total: 2.147 GB
 Metadata Space Available: 2.146 GB
 Udev Sync Supported: true
 Deferred Removal Enabled: false
 Data loop file: /var/lib/docker/devicemapper/devicemapper/data
 Metadata loop file: /var/lib/docker/devicemapper/devicemapper/metadata
 Library Version: 1.02.93-RHEL7 (2015-01-28)
Execution Driver: native-0.2
Logging Driver: json-file
Kernel Version: 3.10.0-229.el7.x86_64
Operating System: CentOS Linux 7 (Core)
CPUs: 2
Total Memory: 993.2 MiB
Name: kitchen-docker-host
ID: 77ZQ:24HX:YGI2:ETAX:GTED:ZEO3:35XE:XS7I:S3WN:6UTT:7ZLI:SAAS
```

To use it with Test Kitchen, you need to install the kitchen-docker gem and to specify docker as Kitchen driver.

To use the Squid caching proxy you need to tell Test Kitchen to use http_proxy.

```yml
driver:
  name: docker
  http_proxy: http://192.168.99.100:3128

provisioner:
  chef_omnibus_url: http://www.opscode.com/chef/install.sh
  client_rb:
    http_proxy: http://192.168.99.100:3128
```

The only thing that doesn't seem to belong here is chef_omnibus_url. However, the Omnibus installer defaults to HTTPS, unless the URL to install.sh uses HTTP. This allows Squid to cache the Chef package which is quite large at ~40 MB.

The whole configuration may be bit smarter as in [this example](https://gist.github.com/fnichol/7551540).

## Speed up the Kitchen file transfer

By default, Test Kitchen with the kitchen-docker driver, uses SCP as transport backend. SCP is painfully slow for most of the tasks regarding file transfer to a Kitchen container. This cancels any speed gains from using containers instead of virtual machines provisioned by Vagrant. The rsync transport saves the day.

```bash
gem install kitchen-transport-rsync # or add it to your Gemfile
```

You need to install rsync inside the Kitchen container. These .kitchen.yml bits show you how to do it for Red Hat and Debian based distributions without a custom Dockerfile:

```yml
driver:
  name: docker
  provision_command:
  - if [ -x /usr/bin/yum ]; then yum -y install rsync; fi; if [ -x /usr/bin/apt-get ]; then apt-get -y install rsync; fi

transport:
  name: rsync
```

While provision_command accepts an array, doing a one liner gets the job done in one stage instead of two, which makes the Kitchen provisioning to be bit faster. Also, the commands themselves need to be wrapped in if statements as a non-zero exit stops the provisioning (equivalent to a script running with set -e).

kitchen-transport-rsync works with Test Kitchen 1.4.2, probably 1.4.x.

## Better usage of Docker caching

Docker itself saves each stage (layer) which is built from the Dockerfile which is generated by kitchen-docker. Unfortunately, there's a major cache buster which is the SSH key pair. A simple solution is to use public_key and private_key configuration options for the docker driver. By using static keys, the generated Dockerfile has identical layers which roughly translates in a provisioning that takes little over one second instead of more than twenty seconds. The Docker image commits are fairly cheap, but they don't come for free.

Example:

```yml
driver:
  name: docker
  public_key: ../kitchen_id_rsa.pub
  private_key: ../kitchen_id_rsa
```

If the provisioning fails, it means that you're using a kitchen-docker version that [isn't patched to strip the whitespace](https://github.com/portertech/kitchen-docker/pull/167) from the public_key. You'll need to remove the newline at the end of the key.

Caching the Chef Omnibus installation also brings performance improvements as it removes one more redundant step.

Example:

```yml
driver:
  name: docker
  provision_command:
    - curl -L http://www.opscode.com/chef/install.sh -o /tmp/install.sh && bash /tmp/install.sh -v 12.5.1

provisioner:
  name: chef_zero
  require_chef_omnibus: true # just checks the presence of a Chef Omnibus installation instead of passing a Chef version
```

## Thick containers for Docker

Even though this isn't the usual use case, Docker is perfectly capable of running traditional containers (i.e. OpenVZ like). These thick containers behave more like a virtual machine, but they are very quick to provision unlike actual VM's.

Some of the goals for these Dockerfile templates:

 * Have an actual init system as PID 1.
 * The init should actually start services inside the container. Sometimes, this may be rather difficult with upstart / systemd.
 * Have a working SSH service.
 * The containers should respond to shutdown commands in a consistent way.
 * Have all the basic bits baked into the images (rsync, Chef Omnibus).

kitchen-docker supports custom Dockerfiles via the [dockerfile](https://github.com/portertech/kitchen-docker#dockerfile) driver configuration option.

This is the list of supported distributions with these Dockerfiles:

 * CentOS 6.7 (also useful for targeting Amazon Linux)
 * Ubuntu 15.04
 * Debian 8.2

For systemd to work, it requires at least CAP_SYS_ADMIN. For the shutdown support to work, I had to run the containers in privileged mode. There's too much work to figure out an exact list of capabilities and there's no guarantee as privileged provides more privileges than enabling all the supported capabilities.

The Dockerfiles are ERB templates which are rendered by kitchen-docker. There's a couple of variables:

 * public_key - kitchen-docker already has this defined, whether you're using the generated keys or you're using static keys
 * chef_version

chef_version by itself isn't defined in kitchen-docker, but the ERB context includes all the variables passed to the driver config, therefore you have a lot of flexibility.

Example:

```yml
driver:
  name: docker
  chef_version: 12.5.1

platforms:
- name: centos-6.7
  driver_config:
    dockerfile: "../centos-6.7"
```

For a development machine, I use Docker in a VM even for a host that supports it natively, therefore the SSH inside the container *is* a hard dependency. The reason for this statement is the fact that the volumes feature essentially provide [root access to the host](http://reventlov.com/advisories/using-the-docker-command-to-root-the-host) for all the users who have access to the Docker socket.

## Monkey-patching the docker driver

[This article](https://medium.com/brigade-engineering/reduce-chef-infrastructure-integration-test-times-by-75-with-test-kitchen-and-docker-bf638ab95a0a) explains the basics of speeding up kitchen-docker. Even though patching the driver isn't necessary, docker exec is much faster than SSH, and the containers are removed in a clean way. I think Docker got better regarding the resource leaks, but I wouldn't put that to the test.

```ruby
require 'kitchen/driver/docker'

module Kitchen
  module Driver
    class Docker < Kitchen::Driver::SSHBase
      # monkey-patch kitchen login to use docker exec instead of ssh
      def login_command(state)
        LoginCommand.new 'docker', ['exec', '-it', state[:container_id], 'su', '-', 'kitchen']
      end

      # monkey-patch kitchen destroy
      def rm_container(state)
        cont_id = state[:container_id]
        docker_command "exec #{cont_id} poweroff"
        docker_command "wait #{cont_id}"
        docker_command "rm #{cont_id}"
      end
    end
  end
end
```

It can be easily loaded with something like:

```yml
# <% load "#{File.dirname(__FILE__)}/../kitchen_docker.rb" %>
---
driver:
  name: docker
```

## How to turn your Test Kitchen into a fast-food joint

Having complex cookbooks with multiple code paths to test means you have to declare multiple test suites. Same applies if you target multiple platforms where you're looking for consistency. The issue is that by default Test Kitchen runs everything sequentially, therefore it means you don't get any benefit from a multi-core CPU.

Test Kitchen also supports a concurrent mode, but Unfortunately this isn't documented in a very visible way. Going at ludicrous speed is easy as the only thing you need to do is to pass the "-c" flag.

Example:

```bash
kitchen create -c
kitchen converge -c
kitchen verify -c
kitchen destroy -c
```

By default, the concurrency limit is at 9999 which is a reasonable value given the fact that it's unlikely to have so many cores. The concurrency flag accepts a numeric value to indicate the number of threads to run if the number of instances is too large for your CPU to handle.

The only drawback of the concurrent mode is the fact that the console output becomes virtually unreadable. However, the logs from .kitchen/logs are really valuable in this case and you may run a single suite at any point.

Example:

```bash
# run only the 'default' suite
kitchen converge default
kitchen verify default
```
