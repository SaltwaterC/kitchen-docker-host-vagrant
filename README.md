## [DEPRECATED] About

I can finally deprecate this as Docker finally released Docker Desktop for Linux. Also, Podman became more useful as well, making Docker a bit _redundant_.

Docker host as Vagrant box created with [kitchen-docker](https://github.com/portertech/kitchen-docker) in mind. Provides a Docker host and Squid as caching proxy. It doesn't have anything [Test Kitchen](http://kitchen.ci) specific per-se, but it provides a consistent development environment. This document also contains a list of speed hacks to make Test Kitchen a lot more faster compared to its defaults.

The machine is also implemented using Test Kitchen using the kitchen-vagrant driver. It used to be implemented with Vagrant and vagrant-berkshelf, however, vagrant-berkshelf has the bad habit of breaking quite often.

All the required gems are supplied by CINC Workstation (i.e a free distribution of Chef Workstation without the corporate nonsense).

## Dependencies

 * [CINC Workstation](https://cinc.osuosl.org/files/unstable/cinc-workstation/) 21.3.346
 * [VirtualBox](https://www.virtualbox.org) 6.1+
 * [Vagrant](https://www.vagrantup.com) 2.2.15+
 * [Docker](https://www.docker.com) 20.10+

## How to use

For starting the VM, simply issue a `rake up` command in the root directory of this project.

By default, it uses 2 virtual cores and 4096 GB of RAM and zram support. Export VB_CPUS and / or VB_MEM environment variables with the desired values to customize.

To customised the sync folders, create a volumes.yml file containing an array of paths. For example:

```yaml
# volumes.yml
- /foo/bar
- /baz/qux
```

The paths on the host are mounted as sync folders in the VM on a 1:1 mapping (i.e the same paths are kept inside the VM). This allows using the Docker volumes feature as if the service is running locally, for as long as the path is declared in volumes.yml.

The VM itself uses a host-only network adapter with the IP address 192.168.99.100. This makes it sort of a drop-in replacement for docker-machine. The Docker socket isn't TLS enabled though.

To tell the Docker client where to find the host, simply:

```bash
export DOCKER_HOST=tcp://192.168.99.100:2375
```

To check whether the Docker connection is OK:

```bash
Client:
 Context:    default
 Debug Mode: false
 Plugins:
  app: Docker App (Docker Inc., v0.9.1-beta3)
  buildx: Build with BuildKit (Docker Inc., v0.5.1-docker)

Server:
 Containers: 0
  Running: 0
  Paused: 0
  Stopped: 0
 Images: 0
 Server Version: 20.10.5
 Storage Driver: devicemapper
  Pool Name: docker-252:0-134938214-pool
  Pool Blocksize: 65.54kB
  Base Device Size: 21.47GB
  Backing Filesystem: xfs
  Udev Sync Supported: true
  Data file: /dev/loop0
  Metadata file: /dev/loop1
  Data loop file: /var/lib/docker/devicemapper/devicemapper/data
  Metadata loop file: /var/lib/docker/devicemapper/devicemapper/metadata
  Data Space Used: 11.73MB
  Data Space Total: 107.4GB
  Data Space Available: 71.63GB
  Metadata Space Used: 17.36MB
  Metadata Space Total: 2.147GB
  Metadata Space Available: 2.13GB
  Thin Pool Minimum Free Space: 10.74GB
  Deferred Removal Enabled: true
  Deferred Deletion Enabled: true
  Deferred Deleted Device Count: 0
  Library Version: 1.02.171-RHEL8 (2020-05-28)
 Logging Driver: json-file
 Cgroup Driver: cgroupfs
 Cgroup Version: 1
 Plugins:
  Volume: local
  Network: bridge host ipvlan macvlan null overlay
  Log: awslogs fluentd gcplogs gelf journald json-file local logentries splunk syslog
 Swarm: inactive
 Runtimes: io.containerd.runc.v2 io.containerd.runtime.v1.linux runc
 Default Runtime: runc
 Init Binary: docker-init
 containerd version: 05f951a3781f4f2c1911b05e61c160e9c30eaa8e
 runc version: 12644e614e25b05da6fd08a38ffa0cfe1903fdec
 init version: de40ad0
 Security Options:
  seccomp
   Profile: default
 Kernel Version: 5.4.17-2036.104.5.el8uek.x86_64
 Operating System: Oracle Linux Server 8.3
 OSType: linux
 Architecture: x86_64
 CPUs: 2
 Total Memory: 3.561GiB
 Name: kdh-generic-oracle8.vagrantup.com
 ID: NZHB:L2GI:ZOFQ:L7A4:G5BF:X4PJ:ADTJ:VHRW:SD4D:US6T:UVXK:LDY6
 Docker Root Dir: /var/lib/docker
 Debug Mode: false
 Registry: https://index.docker.io/v1/
 Labels:
 Experimental: false
 Insecure Registries:
  127.0.0.0/8
 Live Restore Enabled: false
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
    - curl -L http://www.opscode.com/chef/install.sh -o /tmp/install.sh && bash /tmp/install.sh -v 13.2.20

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

 * CentOS 6.8
 * CentOS 7.2 (may be used for targeting Amazon Linux)
 * Ubuntu 15.10
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
  chef_version: 13.2.20

platforms:
- name: centos-6.8
  driver_config:
    dockerfile: "../centos-6.8"
```

For a development machine, I use Docker in a VM even for a host that supports it natively, therefore the SSH inside the container *is* a hard dependency. The reason for this statement is the fact that the volumes feature essentially provide [root access to the host](https://www.saltwaterc.eu/having-docker-socket-access-is-probably-not-a-great-idea.html) for all the users who have access to the Docker socket.

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

## Caching commonly used chef_gem resources

If you have a commonly used gem installed by the chef_gem resource, it pays off to leverage the Dockerfiles to have that gem preinstalled in a Docker image. For example, interfacing with AWS may require aws-sdk-core to be available in your Chef cookbooks.

Adding something like this RUN command to your Dockerfile's speeds up the kitchen converge:

```
RUN /opt/chef/embedded/bin/gem install --no-user-install --install-dir \
  /opt/chef/embedded/lib/ruby/gems/2.1.0 aws-sdk-core
```

If you need a specific gem version, it may be specified like `aws-sdk-core:2.2.34`.

Another advantage of baking Ruby gems into Docker images is the fact that it removes the need to download stuff from rubygems.org which is useful when the service is experiencing hiccups.

## Preinstalling busser, busser-serverspec, and serverspec

Using Test Kitchen verifier with a busser is a repetitive and time wasting activity. It also depends on rubygems.org. In this example I'm using the serverspec busser, but it should be applicable for the rest as well.

Drop another layer using a RUN command like this:

```
# setup busser/serverspec to speed up kitchen verify
RUN su - kitchen -c 'BUSSER_ROOT="/tmp/verifier"; export BUSSER_ROOT; \
  GEM_HOME="/tmp/verifier/gems"; export GEM_HOME; \
  GEM_PATH="/tmp/verifier/gems"; export GEM_PATH; \
  GEM_CACHE="/tmp/verifier/gems/cache"; export GEM_CACHE; \
  /opt/chef/embedded/bin/gem install --no-rdoc --no-ri \
  --no-format-executable -n /tmp/verifier/bin --no-user-install \
  busser busser-serverspec serverspec'
```

This should setup all the required Ruby gems to have them ready for a `kitchen verify`.
