#
# Cookbook Name:: my_cookbook
# Recipe:: default
#
# Copyright 2014, GSLab Pvt. Ltd.
#
# All rights reserved - Do Not Redistribute
#

# Temproary step to remove pre installed java
#package 'java-1.5.0-gcj' do
#  action :remove
#end

#node.override['java']['jdk_version'] = '7'
include_recipe 'java'
# Sets java tools as the default alternatives to use as the java Cookbook doesn't set them for Centos
#java_alternatives "set java alternatives" do
#  java_location node['java']['java_home']
#  bin_cmds node['java']['jdk']['6']['bin_cmds']
#  priority 1062
#  action :set
#end

# make symlinks to java and keytool.

#%w[java keytool].each do |cmd|
#  execute "create symlinks" do
#    user "root"
#    cwd "/usr/bin"
#    command "update-alternatives --install /usr/bin/java java /usr/lib/jvm/java-1.6.0/bin/java 1062"
#    command "ln -s #{node['java']['java_home']}/bin/#{cmd}"
#  end
#end

# Enabling the default site
node.override['apache']['default_site_enabled'] = true
include_recipe "apache2"
include_recipe "apache2::mod_rewrite"

# Default mod_jk recipe with apache2 Cookbook doesn't work so we need to download the connector compile it for our system.

# Download the mod_jk connector. we used remote_file resource as it is idempotent i.e. will not download the file if it is already present.
remote_file "#{Chef::Config[:file_cache_path]}/tomcat-connectors-1.2.39-src.tar.gz" do
  source "http://www.apache.org/dist/tomcat/tomcat-connectors/jk/tomcat-connectors-1.2.39-src.tar.gz"
  owner node['current_user']
end

# Extract the mod_jk connector files.
execute "extract connector" do
  command "tar -xvzf #{Chef::Config[:file_cache_path]}/tomcat-connectors-1.2.39-src.tar.gz -C #{Chef::Config[:file_cache_path]}/"
  not_if  "test -f #{node['apache']['libexecdir']}/mod_jk.so"
end

package "httpd-devel"

# Compile mod_jk connector.
execute "install mod_jk" do
  user "root"
  cwd "#{Chef::Config[:file_cache_path]}/tomcat-connectors-1.2.39-src/native"
  command './configure --with-apxs=/usr/sbin/apxs --enable-api-compatibility && make && make install'
  not_if  "test -f #{node['apache']['libexecdir']}/mod_jk.so"
end

# Template to load mod_jk connector.
template "#{node['apache']['dir']}/mods-available/jk.load" do
  source 'mods/jk.load.erb'
  owner  'root'
  group  node['apache']['root_group']
  mode   '0644'
end

# Template for worker properties file needed for mod_jk configuration.
template "#{node['apache']['dir']}/conf/workers.properties" do
  source 'workers.properties.erb'
  owner  'root'
  group  node['apache']['root_group']
  mode   '0644'
end

# Apache2 Cookbook: "apache_module" -> Enable or disable an Apache module in #{node['apache']['dir']}/mods-available by
# calling a2enmod or a2dismod to manage the symbolic link in #{node['apache']['dir']}/mods-enabled.
# Enables jk module and sets up the configuration template in templates/default/mods/jk.conf.erb
apache_module 'jk' do
  conf true
end


# By default when tomcat package is installed by "yum" on centos it installs java-1.5.0 package in dependencies and points 'java' and 'keytool'
# commands to the older versions installed with java-1.5.0 even though we have installed java-1.6.0. This causes the tomcat install to fail
# while running keytool command. So we have set the keytool to that of java-1.6.0. Later we have used update-alternatives system to point java
# tand java tools to those installed with java-1.6.0 (with higher priority)
node.override["tomcat"]["keytool"]="#{node['java']['java_home']}/bin/keytool"
include_recipe "tomcat"
java_alternatives "set java alternatives" do
  java_location node['java']['java_home']
  bin_cmds node['java']['jdk']['6']['bin_cmds']
  priority 1063
  action :set
end

include_recipe "mysql::server"
