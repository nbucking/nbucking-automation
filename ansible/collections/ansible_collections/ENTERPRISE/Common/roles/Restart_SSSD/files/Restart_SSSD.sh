#!/usr/bin/bash

####################################################################################
# Created on Aug 17, 2030 by Chris Foy
# Version b1
# This script is related to Task 132981: Create a script to reset the AD computer
#
# This script is used to Reset the AD computer account password using the msktutil command.
# account password.
#
# Return status codes
# 0  Successfully updated the AD computer account password
# 1  Unable to restart SSSD
# 2  mkstutil update failed
# 3  Could not find the mstkutil command

# This script will only run on el8 hosts
# Exit if not an el8 OS
#################################################################################
if uname -r | grep -q el7
then
  echo "This script will only run on el8 hosts"
  exit 1
fi

# This script requires msktutil so see if it is installed and executable
#################################################################################
if [[ ! -x /usr/sbin/msktutil  ]]
then
  echo "Could not find the mstkutil command. Is it installed?"
  exit 3
fi

thisHOST=$(hostname)
thisDOMAIN=$(dnsdomainname)
thisREALM=$(dnsdomainname | tr [:lower:] [:upper:])

# Remove this number of days old keytab entries from the krb5 keytab.
DAYSOLD=15

# Check if the SSSD service running and set ADC to the active AD Domain Controller.
# Fail if unable to do so.
#################################################################################
if systemctl --quiet is-active sssd
then
  ADC=$(sssctl domain-status -a ${thisDOMAIN} | grep 'AD Domain Controller' | awk -F: 'gsub(/ /,"",$2){print $2}')
else
  # SSSD is not running so try and restart it
  if systemctl restart sssd
  then
    # Give sssd time to startup
    sleep 2
    ADC=$(sssctl domain-status -a ${thisDOMAIN} | grep 'AD Domain Controller' | awk -F: 'gsub(/ /,"",$2){print $2}')
  else
    echo "Unable to restart SSSD"
    exit 1
  fi
fi

# Use msktutil to update the AD computer account password and create new TGT keys in the krb5 keytab
#################################################################################
if msktutil --update --verbose --hostname ${thisHOST} -n --keytab /etc/krb5.keytab --realm ${thisREALM} --server ${ADC}
then
  # Cleanup DEPRECATED:arcfour-hmac enctypes
  msktutil cleanup --remove-enctype arcfour-hmac --hostname ${thisHOST} --server ${ADC}
  # Removes entries older than $DAYSOLD days from the krb5 keytab
  msktutil cleanup --remove-old ${DAYSOLD} --hostname ${thisHOST} --server ${ADC}
else
  echo "msktutil update failed. Unable to update the AD computer account password on ${thisHOST}"
  exit 2
fi

# Run faillock just in case
#################################################################################
faillock --reset

# Restart SSSD
#################################################################################
# Give AD time to replicate the password change
sleep 3
if systemctl restart sssd
then
  echo "Successfully updated the AD computer account password on ${thisHOST}"
else
  echo "Unable to restart SSSD after updating the AD computer account password on ${thisHOST}"
  exit 1
fi

# EOF
