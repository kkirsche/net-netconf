$LOAD_PATH.unshift 'lib'
require 'rake'
require 'net/netconf/version'

Gem::Specification.new do |s|
  s.name = 'net-netconf'
  s.version = Netconf::VERSION
  s.summary = "Updated NetConf client"
  s.description = "Updated and maintained fork of the Juniper Ruby NetConf client. This is used to manage Junos OS devices."
  s.homepage = 'https://github.com/kkirsche/net-netconf'
  s.authors = ["Kevin Kirsche", "Jeremy Schulman", "Ankit Jain"]
  s.email = 'kev.kirsche@gmail.com'
  s.files = FileList['lib/net/**/*.rb', 'examples/**/*.rb']
  s.license = 'BSD-2-Clause'
  s.add_dependency('nokogiri', '~> 1.6')
  s.add_dependency('net-ssh', '>= 2.9', '< 3.3')
  s.add_dependency('net-scp', '~> 1.2')
end
