require "pathname"

require "vagrant-disksize/plugin"

module VagrantPlugins
  module Disksize
    lib_path = Pathname.new(File.expand_path("../vagrant-disksize", __FILE__))
    autoload :Action, lib_path.join("action")
    autoload :Errors, lib_path.join("errors")

    # This returns the path to the source of this plugin.
    #
    # @return [Pathname]
    def self.source_root
      @source_root ||= Pathname.new(File.expand_path("../lib", __FILE__))
    end
  end
end