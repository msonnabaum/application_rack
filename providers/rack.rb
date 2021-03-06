#
# Author:: Mark Sonnabaum <mark.sonnabaum@acquia.com>
# Cookbook Name:: application_rack
# Provider:: rack
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

action :before_compile do

  if new_resource.bundler.nil?
    new_resource.bundler new_resource.gems.any? { |gem, ver| gem == 'bundler' }
  end

  unless new_resource.migration_command
    command = "rake db:migrate"
    command = "#{bundle_command} exec #{command}" if new_resource.bundler
    new_resource.migration_command command
  end

  new_resource.environment.update({
    "RACK_ENV" => new_resource.environment_name,
    "PATH" => [Gem.default_bindir, ENV['PATH']].join(':')
  })

end

action :before_deploy do

  new_resource.environment['RACK_ENV'] = new_resource.environment_name

  install_gems

end

action :before_migrate do

  if new_resource.bundler
    Chef::Log.info "Running bundle install"
    directory "#{new_resource.path}/shared/vendor_bundle" do
      owner new_resource.owner
      group new_resource.group
      mode '0755'
    end
    directory "#{new_resource.release_path}/vendor" do
      owner new_resource.owner
      group new_resource.group
      mode '0755'
    end
    link "#{new_resource.release_path}/vendor/bundle" do
      to "#{new_resource.path}/shared/vendor_bundle"
    end
    common_groups = %w{development test cucumber staging production}
    common_groups += new_resource.bundler_without_groups
    common_groups -= [new_resource.environment_name]
    common_groups = common_groups.join(' ')
    bundler_deployment = new_resource.bundler_deployment
    if bundler_deployment.nil?
      # Check for a Gemfile.lock
      bundler_deployment = ::File.exists?(::File.join(new_resource.release_path, "Gemfile.lock"))
    end
    execute "#{bundle_command} install --path=vendor/bundle #{bundler_deployment ? "--deployment " : ""}--without #{common_groups}" do
      cwd new_resource.release_path
      user new_resource.owner
      environment new_resource.environment
    end
  end

  gem_names = new_resource.gems.map { |gem, ver| gem }
  if new_resource.migration_command.include?('rake') && !gem_names.include?('rake')
    gem_package "rake" do
      action :install
    end
  end

end

action :before_symlink do
end

action :before_restart do
end

action :after_restart do
end

protected

def bundle_command
  new_resource.bundle_command
end

def install_gems
  new_resource.gems.each do |gem, opt|
    if opt.is_a?(Hash)
      ver = opt['version']
      src = opt['source']
      gem_bin = opt['gem_binary']
    elsif opt.is_a?(String)
      ver = opt
    end

    gem_package gem do
      action :install
      source src if src
      version ver if ver && ver.length > 0
      gem_binary gem_bin if gem_bin
    end
  end
end
