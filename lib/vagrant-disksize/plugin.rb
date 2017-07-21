require "vagrant"

module VagrantPlugins
  module Disksize
    class Plugin < Vagrant.plugin("2")
      name "vagrant-disksize"
      description <<-DESC
      Provides the ability to resize VirtualBox disks at creation time,
      so they don't need to be the same size as the default for the box.
      Filesystems are not resized by this code.
      DESC

      action_hook(:disksize, :machine_action_up) do |hook|
        require_relative 'actions'

        # TODO Ensure we are using the VirtualBox provider
        hook.before(VagrantPlugins::ProviderVirtualBox::Action::Boot, Action::ResizeDisk)
      end

      config(:disksize) do
        require_relative 'config'
        Config
      end
    end
  end
end