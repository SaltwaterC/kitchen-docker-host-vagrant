# find gem in ChefDK
def find_gem_version(gem_name)
  Gem::Specification.find_all_by_name(gem_name).each do |spec|
    return spec.version if spec.full_gem_path.include? '/opt/chefdk'
  end
end

# pin these dependencies against ChefDK
GEMS = %w(
  berkshelf
  test-kitchen
  kitchen-vagrant
  foodcritic
  rubocop
  artifactory
  hashie
  json
  minitar
  molinillo
  nokogiri
  gherkin
  net-ssh
  addressable
  parser
  chef-config
  mixlib-archive
  cucumber-core
  mixlib-install
  net-ssh-gateway
).freeze

source 'https://rubygems.org'

GEMS.each do |g|
  v = find_gem_version g
  gem g, "= #{v}"
end
