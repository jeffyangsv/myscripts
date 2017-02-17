#!/bin/bash
##################################################
#Name:        kvm_clone.sh
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

IMG_DIR=/data/kvm
BASEVM=muban
read -p "Enter VM number[01-99]: " VMNUM

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
cat /data/kvm/muban.xml  > /tmp/myvm.xml
sed -i "/<name>${BASEVM}/s/${BASEVM}/${NEWVM}/" /tmp/myvm.xml
sed -i "/uuid/s/<uuid>.*<\/uuid>/<uuid>$(uuidgen)<\/uuid>/" /tmp/myvm.xml
sed -i "/${BASEVM}\.img/s/${BASEVM}/${NEWVM}/" /tmp/myvm.xml
#sed -i "/<graphics/s/5900/590${VMNUM}/" /tmp/myvm.xml       #qemu运行时的端口
sed -i "/<driver name='qemu'/s/raw/qcow2/"  /tmp/myvm.xml   #qemu运行时磁盘类型是qcow2
sed -i "/mac /s/a1/${VMNUM}/" /tmp/myvm.xml
sed -i "/mac /s/a2/${VMNUM}/" /tmp/myvm.xml
sed -i "/mac /s/a3/${VMNUM}/" /tmp/myvm.xml
echo -en "Defining new virtual machine......\t\t"
virsh define /tmp/myvm.xml &> /dev/null
virsh start $NEWVM
virsh autostart $NEWVM
echo -e "\e[32;1m[OK]\e[0m"

