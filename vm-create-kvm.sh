export BASE_IMG=../base/bionic-server-cloudimg-amd64.img
export VM_NAME=$1
mkdir $VM_NAME
cd $VM_NAME
qemu-img create -f qcow2 -o backing_file=${BASE_IMG} disk1.qcow2
qemu-img resize disk1.qcow2 100G
cat >meta-data <<EOF
local-hostname: ${VM_NAME}
EOF
export PUB_KEY=$(cat ~/.ssh/id_rsa.pub)
cat >user-data <<EOF
#cloud-config
users:
  - name: ubuntu
    ssh_authorized_keys:
      - $PUB_KEY
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    groups: sudo
    shell: /bin/bash
runcmd:
  - echo "AllowUsers ubuntu" >> /etc/ssh/sshd_config
  - systemctl restart ssh
EOF
genisoimage  -output cidata.iso -volid cidata -joliet -rock user-data meta-data


virt-install --connect qemu:///system --virt-type kvm --name ${VM_NAME} --ram 4096 --vcpus=4 --os-type linux --os-variant ubuntu18.04 --disk path=./disk1.qcow2,format=qcow2 --disk path=./cidata.iso,device=cdrom --import --network network=default --noautoconsole
