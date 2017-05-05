#!/bin/bash
##################################################
#Name:        kvm_vm7.sh
#Version:     v1.0
#Create_Date：2016-4-10
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "批量克隆虚拟机脚本"
##################################################


# exit code: 
#    65 -> user input nothing
#    66 -> user input is not a number
#    67 -> user input out of range
#    68 -> vm disk image exists

#IMG_DIR=/var/lib/libvirt/images
IMG_DIR=/var/www/html/kvm-model
BASEVM=rhel7-model.img
ROOM=0$(hostname | cut -b 5)
IP=$(hostname | cut -b 8-9)
read -p "Enter VM number: " VMNUM

if [ -z "${VMNUM}" ]; then
    echo "You must input a number."
    exit 65
elif [ $(echo ${VMNUM}*1 | bc) = 0 ]; then
    echo "You must input a number."
    exit 66
elif [ ${VMNUM} -lt 1 -o ${VMNUM} -gt 99 ]; then
    echo "Input out of range"
    exit 67
fi

NEWVM=${BASEVM}_node${VMNUM}

if [ -e $IMG_DIR/${NEWVM}.img ]; then
    echo "File exists."
    exit 68
fi

echo -en "Creating Virtual Machine disk image......\t"
qemu-img create -f qcow2 -b $IMG_DIR/${BASEVM}.img $IMG_DIR/${NEWVM}.img &> /dev/null
echo -e "\e[32;1m[OK]\e[0m"

#virsh dumpxml ${BASEVM} > /tmp/myvm.xml
#cat /var/lib/libvirt/images/rhel6.xml > /tmp/myvm.xml
cat /var/www/html/kvm-model/rhel7.xml  > /tmp/myvm.xml
sed -i "/<name>${BASEVM}/s/${BASEVM}/${NEWVM}/" /tmp/myvm.xml
sed -i "/uuid/s/<uuid>.*<\/uuid>/<uuid>$(uuidgen)<\/uuid>/" /tmp/myvm.xml
sed -i "/${BASEVM}\.img/s/${BASEVM}/${NEWVM}/" /tmp/myvm.xml

sed -i "/mac /s/a1/${ROOM}/" /tmp/myvm.xml
sed -i "/mac /s/a2/${IP}/" /tmp/myvm.xml
sed -i "/mac /s/a3/0${VMNUM}/" /tmp/myvm.xml

sed -i "/mac /s/b1/${ROOM}/" /tmp/myvm.xml
sed -i "/mac /s/b2/${IP}/" /tmp/myvm.xml
sed -i "/mac /s/b3/0${VMNUM}/" /tmp/myvm.xml

sed -i "/mac /s/c1/${ROOM}/" /tmp/myvm.xml
sed -i "/mac /s/c2/${IP}/" /tmp/myvm.xml
sed -i "/mac /s/c3/0${VMNUM}/" /tmp/myvm.xml

sed -i "/mac /s/d1/${ROOM}/" /tmp/myvm.xml
sed -i "/mac /s/d2/${IP}/" /tmp/myvm.xml
sed -i "/mac /s/d3/0${VMNUM}/" /tmp/myvm.xml

echo -en "Defining new virtual machine......\t\t"
virsh define /tmp/myvm.xml &> /dev/null
echo -e "\e[32;1m[OK]\e[0m"
