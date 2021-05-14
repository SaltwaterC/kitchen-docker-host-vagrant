# frozen_string_literal: true

name 'kitchen-docker-host'
maintainer 'Stefan Rusu'
maintainer_email 'saltwaterc@gmail.com'
license 'MIT'
description 'Installs/Configures kitchen-docker-host'
version '0.4.1'
source_url 'https://git.io/vrMEH'
issues_url 'https://git.io/vrMEj'
chef_version '>= 16'
support 'oracle'

depends 'docker', '~> 7.7.0'
depends 'selinux', '~> 3.1.1'
