#
# Cookbook Name:: copperegg
# Recipe:: default
#
# Copyright 2013 CopperEgg
#
# Redistribution Encouraged
#

tags = []
cetags = ''
tmpfqdn = ''
tag_list = ''

if platform?('redhat', 'centos', 'fedora', 'ubuntu', 'debian', 'amazon')

  include_recipe "copperegg::service"     # which temporarily refers to revealcloud service

  directory '/etc/copperegg' do
    owner 'root'
    group 'root'
    mode 0764
  end
 
  if  node.copperegg.attribute?('tags') 
    cetags = node.copperegg.tags
  end

  # If node.copperegg.tags_override exists regardless of value, then do _not_
  # include the chef_environment and chef roles in the tag list
  unless node.copperegg.attribute?('tags_override')

    # Take the tags specified at the node and add to them the chef_environment and the roles

    # Add the chef environment to the list
    if  node.copperegg.include_env_astag 
      tags.push(node.chef_environment)
    end

    # Add any chef roles to the list
    if node.copperegg.include_roles_astags 
      node.roles.each do |role|
        tags.push(role)
      end
    end

    if node.copperegg.include_chef_tags 
      # Add any chef tags to the list
      node.tags.each do |tag|
        tags.push(tag)
      end
    end
  end

  if node.copperegg.attribute?('use_fqdn') 
    if node['copperegg']['use_fqdn']
      Chef::Log.warn('Setting UUID to FQDN:\n')
      tmpfqdn = node['fqdn']
      node.set['copperegg']['node_fqdn'] = "#{node.fqdn}"
    end
  end

  # Create a comma seperated list of tags.
  tag_list = tags.uniq.join(',')
  tag_list = tag_list + ',' + cetags
  node.set['copperegg']['alltags'] = tag_list

  script 'revealcloud_install' do
    interpreter 'bash'
    cwd
    user 'root'
    code <<-EOH
        curl http://#{node['copperegg']['apikey']}:U@api.copperegg.com/chef.sh  > /tmp/revealcloud_installer.sh
        chmod +x /tmp/revealcloud_installer.sh
        export RC_TAG="#{tag_list}"
        export RC_LABEL="#{node[:copperegg][:label] || ''}"
        export RC_PROXY="#{node[:copperegg][:proxy] || ''}"
        export RC_OOM_PROTECT="#{node[:copperegg][:oom_protect] || ''}"
        export RC_UUID="#{tmpfqdn}"
        /tmp/revealcloud_installer.sh
    EOH
    action :nothing
  end

  template '/etc/copperegg/copperegg.conf' do
    owner 'root'
    group 'root'
    source 'copperegg.conf.erb'
    mode 0664
    action :create_if_missing
    notifies :run, resources(:script => 'revealcloud_install'), :delayed
    notifies :start, resources(:service => 'revealcloud'), :delayed
  end

end   # end of    if platform?('redhat', 'centos', 'fedora', 'ubuntu', 'debian')

if platform?('windows')
  windows_package 'RevealCloudSetup.msi' do
    source 'http://s3.amazonaws.com/cuegg_collectors/revealcloud/3.0.41.0/windows/RevealCloudSetup.msi'
    installer_type :msi
    action :install
    options "/qbr APIKEY=\"#{node['copperegg']['apikey']}\" TAGS=\"#{tag_list}\" LABEL=\"my winserver\""
  end
end  









