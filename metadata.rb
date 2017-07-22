name 'kitchen-docker-host'
maintainer 'Stefan Rusu'
maintainer_email 'saltwaterc@gmail.com'
license 'MIT'
description 'Installs/Configures kitchen-docker-host'
long_description 'Installs/Configures kitchen-docker-host'
version '0.3.0'
source_url 'https://git.io/vrMEH'
issues_url 'https://git.io/vrMEj'
chef_version '>= 12'
supports 'centos'

depends 'docker', '= 2.15.6'
depends 'sysctl', '= 0.9.0'
depends 'yum-epel', '= 2.1.1'
