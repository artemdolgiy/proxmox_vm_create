#!/bin/bash

# завершить выполнение, если некоторая команда, которая не является частью какого-либо теста (например, if [ ... ] или конструктора &&), возвращает ненулевой код
set -e

# проверка запуска скрипта с параметром
if [ -n "$1" ]; then
    vm_passwd="$1"
else
	echo "Необходимо указать желаемый пароль для шаблона первым аргументом"
	exit 1
fi

# задаём необходимые переменные
cloudimg=focal-server-cloudimg-amd64.img
img_url=https://cloud-images.ubuntu.com/focal/current

# параметры вм
vm_id=200
vm_name="ubuntu-2004-cloudinit-template"
vm_memory=2048
vm_cores=2
vm_user="cooluser"

# данные proxmox
px_storage=local-lvm
px_bridge=vmbr1

# проверить наличие образа, если его нет - скачать образ ubuntu server 20.04 с поддержкой cloud-init
if [ ! -f "$cloudimg" ]; then
    echo "Файл $cloudimg не существует"
    echo Скачиваю образ Ubuntu Server 20.04 с поддержкой cloud-init
    wget $img_url/$cloudimg
fi

echo Создаю ВМ
qm create $vm_id --name $vm_name --memory $vm_memory --cores $vm_cores --net0 virtio,bridge=$px_bridge
qm importdisk $vm_id $cloudimg $px_storage
qm set $vm_id --scsihw virtio-scsi-pci --scsi0 $px_storage:vm-$vm_id-disk-0
qm set $vm_id --boot c --bootdisk scsi0
qm set $vm_id --ide2 $px_storage:cloudinit
qm set $vm_id --serial0 socket --vga serial0
qm set $vm_id --cipassword=$vm_passwd --ciuser=$vm_user
qm set $vm_id --agent 1

echo Конвертирую ВМ в шаблон
qm template $vm_id

echo Удаляю ранее скачанный образ
rm focal-server-cloudimg-amd64.img

echo Готово
exit 0
