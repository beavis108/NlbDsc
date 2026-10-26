# Description

This resource is used to add or remove a dedicated IP address (DIP) of a node
of a Network Load Balancing (NLB) cluster (`Add-NlbClusterNodeDip`,
`Remove-NlbClusterNodeDip`). IPv4 and IPv6 addresses are supported.

NLB never load balances traffic for a dedicated IP address - it is used to
reach a specific node.

When `SubnetMask` is specified and differs from the subnet mask of an
existing dedicated IP address, the address is removed and added again with
the new subnet mask, because `Set-NlbClusterNodeDip` can only change the
address itself.

## Requirements

- Target machine must be running Windows Server 2012 or later.
- The node must already be a member of the cluster.

## Known issues

- To replace a dedicated IP address by another one, declare the old address
  with `Ensure = 'Absent'` and the new address with `Ensure = 'Present'`.
