#!/bin/sh
# This file contains customizations that can be applied during
# the install of ManageSoft for Managed Devices.

# Create a secure temporary directory
TMPDIR=/var/tmp/tempdir.$RANDOM.$RANDOM.$$
( umask 077 && mkdir $TMPDIR ) || {
	echo "ERROR: mgssetup.sh could not create a temporary directory." 1>&2
	exit 1
}

# ----------------------------------------------------------------------
cat << EOF > $TMPDIR/mgsft_rollout_response

# The ManageSoft domain name.  Refer to the ManageSoft
# documentation for further details.
MGSFT_DOMAIN_NAME=${DomainName}

# The alternate machine identification allows the specification of an
# alternate machine name if it is to be different to the current hostname
# (e.g. if registered differently in Active Directory) Not specifying
# this setting or a value of NONE disables this feature.
# MGSFT_MACHINE_ID=

# The policy path specifies the location of the policy to be applied to
# the managed device.  This is typically used when the policy is not
# attached to Active Directory domains.  For example, a path may be
# "Policies/Merged/MANAGESOFT_domain/Machine/device.npl".  Not specifying
# this setting or a value of NONE disables this feature.
MGSFT_POLICY_PATH=`echo ${BOOTSTRAPPEDPOLICY} | sed -e 's/^\$[(].*[)]\///'`

# The initial download location(s) for the installation.
# For example, http://myhost.mydomain.com/ManageSoftDL/
# Refer to the ManageSoft documentation for further details.
MGSFT_BOOTSTRAP_DOWNLOAD=${DeployServerURL}

# The initial ManageSoft reporting location(s) for the installation.
# For example, http://myhost.mydomain.com/ManageSoftRL/
# Refer to the ManageSoft documentation for further details.
MGSFT_BOOTSTRAP_UPLOAD=`echo ${DeployServerURL} | sed -e 's/ManageSoftDL/ManageSoftRL/g'`

# For subnets using IPv6, uncomment to cause the inventory agent
# to prefer IPv6 addresses when both formats are returned. 
# Fails over to IPv4 addresses when IPv6 is not available.
# The default behavior when this setting is not specified
# uses the IP version of the first address returned by the DNS and OS.
# PREFERIPVERSION=ipv6

# The initial proxy configuration.  Uncomment these to enable proxy configuration.
# Note that setting values of NONE disables this feature.
# MGSFT_HTTP_PROXY=http://webproxy.local:3128
# MGSFT_HTTPS_PROXY=https://webproxy.local:3129
# MGSFT_NO_PROXY=internal1.local,internal2.local

# Check the HTTPS server certificate's existence, name, validity period,
# and issuance by a trusted certificate authority (CA).  This is enabled
# by default and can be disabled with false.
# MGSFT_HTTPS_CHECKSERVERCERTIFICATE=true

# Check that the HTTPS server certificate has not been revoked. This is
# enabled by default and can be disabled with false.
# MGSFT_HTTPS_CHECKCERTIFICATEREVOCATION=true

# Prioritize the method of checking for revocation of the HTTPS server 
# certificate. You can reverse the values to swap the default order.
# MGSFT_HTTPS_PRIORITIZEREVOCATIONCHECKS=OCSP,CRL

# These settings control the caching of HTTPS server certificate checking.
# Default values are shown (these take effect when no settings are specified). 
# Lifetime is in seconds. There are parallel settings for using CRL or OCSP
# checking. See documentation for more information.
# MGSFT_HTTPS_SSLCRLCACHELIFETIME=0
# MGSFT_HTTPS_SSLOCSPCACHELIFETIME=0

# The run policy flag determines if policy will run after installation.
#    "1" or "Yes" will run policy after install
#    "0" or "No" will not run policy
MGSFT_RUNPOLICY=${INSTALLMACHINEPOLICY}
EOF

# Set owner to install or nobody or readable by all so pre 8.2.0 Solaris
# clients checkinstall script can read it.
if [ "`uname -s`" = "SunOS" ]
then
	chown install $TMPDIR/mgsft_rollout_response 2>/dev/null \
		|| chown nobody $TMPDIR/mgsft_rollout_response 2>/dev/null \
		|| chmod a+r $TMPDIR/mgsft_rollout_response
fi

# ----------------------------------------------------------------------
# Move from the secure directory to the known path
ret=0
( mv -f $TMPDIR/mgsft_rollout_response /var/tmp/mgsft_rollout_response ) || ret=1
rm -rf $TMPDIR

[ $ret -ne 0 ] && echo "ERROR: mgssetup.sh could not create answer files." 1>&2

exit $ret

