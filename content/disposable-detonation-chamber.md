+++
date = '2025-03-10T17:45:11+01:00'
draft = true
title = 'Malware Detonation Chamber on Vagrant'
+++

If you follow me on the socials, you know that I often perform lots of static malware-analysis and reverse-engineering. But ever so often, I do dynamic analysis for the more profilic threats. My last one was to dynamically analyse the, then newly leaked LockBit 4 builder and ransomware including PowerShell Stager. 

To do these types of analysis in a safe and isolated manner without compromising my own host machine and network, I came up with a neat little idea. I built a modular detonation chamber and analysis lab on **Vagrant**. I chose vagrant because it is quite handy to spin up virtualmachines and do VM automation at scale. Since I have used vagrant already quite some times, I did the same for this use case. 

Below you find my current **Vagrantfile** which holds the configurations for the detonation chamber and the analysis machine. The chamber is just a FlareVM on Windows 10 and the analysis machine is a RemNUX machine. The malware sample can be detonated in the chamber. Any processes, regkeys, scripts or traffic gets logged and ingested into the base tools of FlareVM which we can later use for forensics and post-analysis. Outgoing and incoming traffic can also be sniffed on the RemNUX machine which is directly connected (in an isolated manner) to the detonation chamber using port-mirroring. Both images are pulled directly from the vagrant hub which contains thousands of different vm images. After that, Vagrant configures the VMs according to the Vagrantfile. As you can see, I applied some configs to the detonation chamber to disable clipboard, draganddrop as well as guest to host communication. These changes are necessary to prevent so-called VM-escape techniques where malware escape the analysis env and populate into the host machine.


```ruby
Vagrant.configure("2") do |config|
  
  config.vm.define "flarevm" do |flare|
    flare.vm.box = "rootware/flareVm"
    flare.vm.network "private_network", type: "dhcp"
    flare.vm.provider "virtualbox" do |vb|
      vb.memory = "4096"
      vb.cpus = 2
      vb.customize ["modifyvm", :id, "--nicpromisc2", "deny"]
      vb.customize ["modifyvm", :id, "--clipboard", "disabled"]
      vb.customize ["modifyvm", :id, "--draganddrop", "disabled"]
      vb.customize ["modifyvm", :id, "--usb", "off"]
    end
  end

  config.vm.define "remnux" do |remnux|
    remnux.vm.box = "remnux/remnux"
    remnux.vm.network "private_network", type: "dhcp"
    remnux.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 1
    end
  end
end
```

You can spin up the environment in a flicker using these two commands.

```bash
vagrant up flarevm
vagrant up remnux
```

To access the machines, you can leverage the builtin RDP and SSH functions of vagrant like so.

```bash
vagrant ssh remnux
vagrant rdp flarevm
```