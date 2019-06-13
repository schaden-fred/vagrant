Vagrant.configure('2')  do |config|
  
  # Add additional hard disks for functional testing
  config.vm.provider 'virtualbox' do |v|

    # Enable shared clipboard
    v.customize ['modifyvm', :id, '--clipboard', 'bidirectional']    

    # Attach SATA controller for ease of setup
    v.customize ['storagectl', :id,
                 '--name', 'SATAController',
                 '--add', 'sata',
                 '--controller', 'IntelAhci',
                 '--portcount', 4
                ]

    # Create and attach disks to SATA controller.  Add aditional lines to add more disks.
    file_to_disk = [
      'tmp/disk1.vdi'
      #,
      #'tmp/disk2.vdi',
      #'tmp/disk3.vdi'
    ]

    file_to_disk.each_with_index do |disk_file, i|
      # Delete the disk if it already exists
      if  File.exist?(disk_file)
        v.customize ['closemedium', 'disk', disk_file, '--delete']
      end

      # Create a fresh disk.  This line defines the size of each disk.
      v.customize ['createhd', '--filename', disk_file, '--size', 1 * 1024]

      # Attach the disk
      v.customize ['storageattach', :id,
                   '--storagectl', 'SATAController',
                   '--port', i,
                   '--device', 0,
                   '--type', 'hdd',
                   '--medium', disk_file
                  ]
    end
  end

  # Assign first empty drive as G, our default data drive.  Format with NTFS.
  config.trigger.after :up do |data_drive|
    data_drive.warn = "Initializing second drive as G:"
    data_drive.run_remote = {inline: "Get-Disk | Where-Object PartitionStyle -Eq \"RAW\" | Sort-Object -Property Number | Select-Object -First 1 | Initialize-Disk -PassThru | New-Partition -DriveLetter G -UseMaximumSize | Format-Volume"}
  end

  # If there are any other drives created, assutn their letters automatically.
  config.trigger.after :up do |partition_format|
    partition_format.warn = "Initializing remaining drives with any available letter."
    partition_format.run_remote = {inline: "Get-Disk | Where-Object PartitionStyle -Eq \"RAW\" | Initialize-Disk -PassThru | New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume"}
  end

end

