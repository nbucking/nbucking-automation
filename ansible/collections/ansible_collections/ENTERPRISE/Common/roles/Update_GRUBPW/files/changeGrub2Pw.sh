#!/usr/bin/bash

# Parts of this script was taken from /sbin/grub2-setpassword
# PACKAGE_VERSION= 2.02~beta2
# PACKAGE_NAME= GRUB

# autodidadtic learning
# PicoCTF.com

# Are we using UEFI or BIOS
if [ -d /sys/firmware/efi/efivars/ ]
then
  grubdir=`echo "/boot/efi/EFI/redhat/" | sed 's,//*,/,g'`
  BOOT_MODE=UEFI
else
  grubdir=`echo "/boot/grub2" | sed 's,//*,/,g'`
  BOOT_MODE=BIOS
fi

NOW=$(date '+%Y%m%d.%S')
OUTPUT_PATH="${grubdir}"
NEWPW='pIQGnukae>8^3r4'
bindir="/usr/bin"
grub_mkpasswd="${bindir}/grub2-mkpasswd-pbkdf2"

# Pipe the password, $P0, twice to the grub2-mkpasswd-pbkdf2 command
getpass() {
  local P0
  P0="$1"

  ( echo ${P0} ; echo ${P0} ) | \
    LC_ALL=C ${grub_mkpasswd} | \
    grep -v '[eE]nter password:' | \
    sed -e "s/PBKDF2 hash of your password is //"
}

update_40_custom() {
  export g2pw="$1"

  mv /etc/grub.d/40_custom /etc/grub.d/40_custom.${NOW}
  chmod 400 /etc/grub.d/40_custom.${NOW}
  echo "#!/bin/sh
exec tail -n +3 $0
# This file provides an easy way to add custom menu entries.  Simply type the
# menu entries you want to add after this comment.  Be careful not to change
# the 'exec tail' line above.
# BEGIN MANAGED BY ANSIBLE-HARDENING
set superusers=\"root\"
password_pbkdf2 root $g2pw
# END MANAGED BY ANSIBLE-HARDENING" > /etc/grub.d/40_custom

  # We must chmod the backup to prevent grub2-mkconfig from includeing it in the grub.cfg
  echo "Restore /etc/grub.d/40_custom SELinux context"
  restorecon -F /etc/grub.d/40_custom
}

#update_40_custom() {
#  export g2pw="$1"
#
#  if grep -q password_pbkdf2 /etc/grub.d/40_custom
#  then
#    # Use perl to replace the curent pw in the 40_custom script
#    perl -i.${NOW} -pe 's/password_pbkdf2 root (.*?)$/password_pbkdf2 root $ENV{g2pw}/;' /etc/grub.d/40_custom
#  else
#    cp -p /etc/grub.d/40_custom /etc/grub.d/40_custom.${NOW}
#    echo "# BEGIN MANAGED BY ANSIBLE-HARDENING
#set superusers=\"root\"
#password_pbkdf2 root $g2pw
## END MANAGED BY ANSIBLE-HARDENING" >> /etc/grub.d/40_custom
#  fi
#
#  # We must rename the backup to prevent grub2-mkconfig from includeing it in the grub.cfg
#  chmod 400 /etc/grub.d/40_custom.${NOW}
#  echo "Restore /etc/grub.d/40_custom SELinux context"
#  restorecon -F /etc/grub.d/40_custom
#}

update_user_cfg() {
  local g2pw
  local opath
  g2pw="$1" && shift
  opath="$1" && shift

  # on the ESP, these will fail to set the permissions, but it's okay because
  # the directory is protected.
  install --preserve-context -S ".${NOW}" -m 0600 /dev/null "${opath}/user.cfg" 2> /dev/null
  chmod 0600 ${opath}/user.cfg 2> /dev/null
  echo "GRUB2_PASSWORD=${grub2pw}" > ${opath}/user.cfg
}

# main
#################################################

echo "Boot mode is $BOOT_MODE"
echo "Creating new password hash"
grub2pw=$(getpass "${NEWPW}")

echo "Updating 40_custom script"
update_40_custom "${grub2pw}"

echo "Updateing user.cfg"
update_user_cfg "${grub2pw}" "${OUTPUT_PATH}"

echo "Backup grub.cfg"
cp -p ${OUTPUT_PATH}/grub.cfg ${OUTPUT_PATH}/grub.cfg.${NOW}

echo "Restore ${OUTPUT_PATH}/\* SELinux context"
restorecon -F ${OUTPUT_PATH}/*

echo "Running grub2-mkconfig -o ${OUTPUT_PATH}/grub.cfg"
grub2-mkconfig -o ${OUTPUT_PATH}/grub.cfg

# EOF
