# Description

This cookbook provides an LWRP for rack based applications. It is mostly just a subset of the rails LWRP from [application_ruby](https://github.com/opscode-cookbooks/application_ruby), with the rails-specific bits removed.

# Resources/Providers

rack

## Attribute Parameters

- gems: an Array of gems to install. Also supports an array of hashes to pass additional parameters.
- bundler: if true, `bundler` will always be used; if false it will never be. Defaults to true if `gems` includes bundler
- bundle_command: The command to execute when calling bundler commands.  Useful for specifing alternate commands such as RVM wrappers.  Defaults to `bundle`.
- bundler_deployment: if true, Bundler will be run with the `--deployment` options. Defaults to true if a `Gemfile.lock` is present
- bundler\_without\_groups: an Array of additional Bundler groups to skip


# Usage

Basic usage with bundler.

    application "my-app" do
      path "..."
      repository "..."
      revision "..."

      rack do
        gems ['bundler']
      end
    end

You can specify custom bundler and gem commands if needed. This example uses the jruby cookbook to specify these paths.

    application "my-app" do
      path "..."
      repository "..."
      revision "..."

      rack do
        gems [['bundler', {'gem_binary' => "#{node[:jruby][:install_path]}/bin/gem"}]]
        bundle_command "#{node[:jruby][:install_path]}/bin/bundle"
      end
    end
