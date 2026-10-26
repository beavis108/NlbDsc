# Description

This resource is used to add or remove an additional virtual IP address (VIP)
of a Network Load Balancing (NLB) cluster (`Add-NlbClusterVip`,
`Remove-NlbClusterVip`). IPv4 and IPv6 addresses are supported.

The primary IP address of the cluster is managed by the resource
[NlbClusterDeployment](NlbClusterDeployment). It can not be removed or
changed with this resource.

When `SubnetMask` is specified and differs from the subnet mask of an
existing virtual IP address, the address is removed and added again with the
new subnet mask, because `Set-NlbClusterVip` can only change the address
itself.

## Requirements

- Target machine must be running Windows Server 2012 or later.
- The NLB cluster must already exist.

## Known issues

- To replace a virtual IP address by another one, declare the old address
  with `Ensure = 'Absent'` and the new address with `Ensure = 'Present'`.
