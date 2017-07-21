module VagrantPlugins
  module VirtualBox
    module Cap
      class ResizeDisk
        def self.resize_disk(machine)
            ensure_disk_resizable(machine.id, machine.provider.driver)
            change_disk_size(machine.id, machine.provider.driver, machine.ui, machine.config.disksize.size)
        end
        private        

        def self.ensure_disk_resizable(machine_id, driver)
          disks = identify_disks(machine_id, driver)
          # TODO Shouldn't assume that the first disk is the one we want to resize
          unless disk_resizeable? disks.first
            old_disk = disks.first
            new_disk = generate_resizable_disk(old_disk)
            unless File.exist? new_disk[:file]
              clone_as_vdi(driver, old_disk, new_disk)
              attach_disk(machine_id, driver, new_disk)
              File.delete(old_disk[:file])
            end
          end
        end

        def self.change_disk_size(machine_id, driver, ui, req_size)
          disks = identify_disks(machine_id, driver)
          target = disks.first    # TODO Shouldn't assume that the first disk is the one we want to resize

          old_size = get_disk_size(driver, target)
          if old_size < req_size
            grow_vdi(driver, target, req_size)
            new_size = get_disk_size(driver, target)
            ui.success "Resized disk: old #{old_size} MB, req #{req_size} MB, new #{new_size} MB"
            ui.success "You may need to resize the filesystem from within the guest."
          elsif old_size > req_size
            ui.error "Disk cannot be decreased in size. #{req_size} MB requested but disk is already #{old_size} MB."
          end
        end

        def self.clone_as_vdi(driver, src, dst)
          driver.execute('clonemedium', src[:file], dst[:file], '--format', 'VDI')
        end

        def self.grow_vdi(driver, disk, size)
          driver.execute('modifymedium', disk[:file], '--resize', size.to_s)
        end

        def self.attach_disk(machine_id, driver, disk)
          parts = disk[:name].split('-')
          controller = parts[0]
          port = parts[1]
          device = parts[2]
          driver.execute('storageattach', machine_id, '--storagectl', controller, '--port', port, '--device', device, '--type', 'hdd',  '--medium', disk[:file])
        end

        def self.get_disk_size(driver, disk)
          size = nil
          driver.execute('showmediuminfo', disk[:file]).each_line do |line|
            if line =~ /Capacity:\s+([0-9]+)\s+MB/
              size = $1.to_i
            end
          end
          size
        end

        def self.identify_disks(machine_id, driver)
          vminfo = get_vminfo(machine_id, driver)
          disks = []
          disk_keys = vminfo.keys.select { |k| k =~ /-ImageUUID-/ }
          disk_keys.each do |key|
            uuid = vminfo[key]
            disk_name = key.gsub(/-ImageUUID-/,'-')
            disk_file = vminfo[disk_name]
            disks << {
              uuid: uuid,
              name: disk_name,
              file: disk_file
            }
          end
          disks
        end

        def self.get_vminfo(machine_id, driver)
          vminfo = {}
          driver.execute('showvminfo', machine_id, '--machinereadable', retryable: true).split("\n").each do |line|
            parts = line.partition('=')
            key = unquoted(parts.first)
            value = unquoted(parts.last)
            vminfo[key] = value
          end
          vminfo
        end

        def self.generate_resizable_disk(disk)
          src = disk[:file]
          src_extn = File.extname(src)
          src_path = File.dirname(src)
          src_base = File.basename(src, src_extn)
          dst = File.join(src_path, src_base) + '.vdi'
          disk.merge({ uuid: "(undefined)", file: dst })
        end

        def self.disk_resizeable?(disk)
          disk[:file].end_with? '.vdi'
        end

        def self.unquoted(s)
          s.gsub(/\A"(.*)"\Z/,'\1')
        end        
      end
    end
  end
end
