# allow test-kitchen busser to continue working as if this is Chef
# Cinc Workstation may be a bit inconsitent depending on which client is used
# on the box and kitchen driver
link '/opt/chef' do
  to '/opt/cinc'
  not_if { ::File.exist? '/opt/chef' }
end
