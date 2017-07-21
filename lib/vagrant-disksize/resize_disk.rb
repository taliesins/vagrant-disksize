module VagrantPlugins
  module Disksize
    class Action
      class ResizeDisk
        def initialize(app, env)
          @app = app
        end

        def call(env)
          machine = env[:machine]
          config = machine.config.disksize
          
          if config && config.size              
            provider = machine.provider.to_s

            if provider =~ /VirtualBox/
              #Run disk_resize cap for provider
              require_relative 'providers/#{provider.downcase}/resize_disk'

              VagrantPlugins::VirtualBox::Cap::ResizeDisk.resize_disk(machine)
            else 
              env[:ui].error "The vagrant-disksize plugin does not support #{provider} at present. Disk size will not be changed."
            end
          end
     
          # Allow middleware chain to continue so VM is booted
          @app.call(env)
        end
      end
    end
  end
end