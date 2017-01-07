#!/bin/bash

mysqlPassword=$1 

MOUNTPOINT="/datadrive"
RAIDCHUNKSIZE=512

RAIDDISK="/dev/md127"
RAIDPARTITION="/dev/md127p1"
BLACKLIST="/dev/sda|/dev/sdb"

check_os() {
    grep ubuntu /proc/version > /dev/null 2>&1
    isubuntu=${?}
    grep centos /proc/version > /dev/null 2>&1
    iscentos=${?}
}

scan_for_new_disks() {
    # Looks for unpartitioned disks
    declare -a RET
    DEVS=($(ls -1 /dev/sd*|egrep -v "${BLACKLIST}"|egrep -v "[0-9]$"))
    for DEV in "${DEVS[@]}";
    do
        # Check each device if there is a "1" partition.  If not,
        # "assume" it is not partitioned.
        if [ ! -b ${DEV}1 ];
        then
            RET+="${DEV} "
        fi
    done
    echo "${RET}"
}

get_disk_count() {
    DISKCOUNT=0
    for DISK in "${DISKS[@]}";
    do
        DISKCOUNT+=1
    done;
    echo "$DISKCOUNT"
}

create_raid0_ubuntu() {
    dpkg -s mdadm
    if [ ${?} -eq 1 ];
    then
        echo "installing mdadm"
        wget --no-cache http://mirrors.cat.pdx.edu/ubuntu/pool/main/m/mdadm/mdadm_3.2.5-5ubuntu4_amd64.deb
        dpkg -i mdadm_3.2.5-5ubuntu4_amd64.deb
    fi
    echo "Creating raid0"
    udevadm control --stop-exec-queue
    echo "yes" | mdadm --create "$RAIDDISK" --name=data --level=0 --chunk="$RAIDCHUNKSIZE" --raid-devices="$DISKCOUNT" "${DISKS[@]}"
    udevadm control --start-exec-queue
    mdadm --detail --verbose --scan > /etc/mdadm.conf
}

create_raid0_centos() {
    echo "Creating raid0"
    yes | mdadm --create "$RAIDDISK" --name=data --level=0 --chunk="$RAIDCHUNKSIZE" --raid-devices="$DISKCOUNT" "${DISKS[@]}"
    mdadm --detail --verbose --scan > /etc/mdadm.conf
}

do_partition() {
# This function creates one (1) primary partition on the
# disk, using all available space
    DISK=${1}
    echo "Partitioning disk $DISK"
    echo "n
p
1


w
" | fdisk "${DISK}"
#> /dev/null 2>&1

#
# Use the bash-specific $PIPESTATUS to ensure we get the correct exit code
# from fdisk and not from echo
if [ ${PIPESTATUS[1]} -ne 0 ];
then
    echo "An error occurred partitioning ${DISK}" >&2
    echo "I cannot continue" >&2
    exit 2
fi
}

add_to_fstab() {
    UUID=${1}
    MOUNTPOINT=${2}
    grep "${UUID}" /etc/fstab >/dev/null 2>&1
    if [ ${?} -eq 0 ];
    then
        echo "Not adding ${UUID} to fstab again (it's already there!)"
    else
        LINE="UUID=${UUID} ${MOUNTPOINT} ext4 defaults,noatime 0 0"
        echo -e "${LINE}" >> /etc/fstab
    fi
}

configure_disks() {
        ls "${MOUNTPOINT}"
        if [ ${?} -eq 0 ]
        then
                return
        fi
    DISKS=($(scan_for_new_disks))
    echo "Disks are ${DISKS[@]}"
    declare -i DISKCOUNT
    DISKCOUNT=$(get_disk_count)
    echo "Disk count is $DISKCOUNT"
    if [ $DISKCOUNT -gt 1 ];
    then
        if [ $iscentos -eq 0 ];
        then
            create_raid0_centos
        elif [ $isubuntu -eq 0 ];
        then
            create_raid0_ubuntu
        fi
        do_partition ${RAIDDISK}
        PARTITION="${RAIDPARTITION}"
    else
        DISK="${DISKS[0]}"
        do_partition ${DISK}
        PARTITION=$(fdisk -l ${DISK}|grep -A 1 Device|tail -n 1|awk '{print $1}')
    fi

    echo "Creating filesystem on ${PARTITION}."
    mkfs -t ext4 -E lazy_itable_init=1 ${PARTITION}
    mkdir "${MOUNTPOINT}"
    read UUID FS_TYPE < <(blkid -u filesystem ${PARTITION}|awk -F "[= ]" '{print $3" "$5}'|tr -d "\"")
    add_to_fstab "${UUID}" "${MOUNTPOINT}"
    echo "Mounting disk ${PARTITION} on ${MOUNTPOINT}"
    mount "${MOUNTPOINT}"
}



configure_mysql() {
    /etc/init.d/mysql status
    if [ ${?} -eq 0 ];
    then
       return
    fi

    mkdir "${MOUNTPOINT}/mysql"
    ln -s "${MOUNTPOINT}/mysql" /var/lib/mysql
    chmod o+x /var/lib/mysql
    groupadd mysql
    useradd -r -g mysql mysql
    chmod o+x "${MOUNTPOINT}/mysql"
    chown -R mysql:mysql "${MOUNTPOINT}/mysql"
    chmod -R 775 "${MOUNTPOINT}/mysql"
 # Download and Install the Latest Updates for the OS
apt-get update 

# Set the Server Timezone to CST
echo "America/Vancouver" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata

 

# Install essential packages
apt-get -y install zsh htop

# Install MySQL Server in a Non-Interactive mode. Default root password will be "root"
echo "mysql-server-5.6 mysql-server/root_password password root" | sudo debconf-set-selections
echo "mysql-server-5.6 mysql-server/root_password_again password root" | sudo debconf-set-selections
apt-get -y install mysql-server-5.6

 

#sed -i 's/127\.0\.0\.1/0\.0\.0\.0/g' /etc/mysql/my.cnf
#mysql -uroot -p -e 'USE mysql; UPDATE `user` SET `Host`="%" WHERE `User`="root" AND `Host`="localhost"; DELETE FROM `user` WHERE `Host` != "%" AND `User`="root"; FLUSH PRIVILEGES;'

#service mysql restart


    if [ $iscentos -eq 0 ];
    then
        install_mysql_centos
    elif [ $isubuntu -eq 0 ];
    then
echo installing #sudo apt-get update
 
   fi




#    create_mycnf
#    /etc/init.d/mysql restart
#    mysql_secret=$(awk '/password/{print $NF}' ${HOME}/.mysql_secret)
#    mysqladmin -u root --password=${mysql_secret} password ${ROOTPWD}
if [ $iscentos -eq 0 ];
then
echo mysql-------mysqlinstalled now
fi
}

check_os
if [ $iscentos -ne 0 ] && [ $isubuntu -ne 0 ];
then
    echo "unsupported operating system"
    exit 1
else
    configure_disks
    configure_mysql


        #yum -y install microsoft-hyper-v
#       echo "/sbin/reboot" | /usr/bin/at now + 3 min >/dev/null 2>&1
fi
