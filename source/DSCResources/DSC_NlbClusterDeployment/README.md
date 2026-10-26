# Description

This resource is used to create, change or remove a Network Load Balancing
(NLB) cluster on the first cluster host.

When `Ensure` is `Present` and the Windows features `NLB` and `RSAT-NLB` are
not installed on the node, the resource installs them before the cluster is
created. A separate `WindowsFeature` resource is therefore not required. If the
feature installation requires a restart, the resource signals a restart to the
Local Configuration Manager (LCM) and creates the cluster in the next run.

Before the cluster is created, the network interface is verified with
`Get-NlbClusterNodeNetworkInterface`. Creating a cluster on an interface that
uses DHCP fails unless `OverrideDhcp` is `$true`.

The name, the operation mode and the primary IP address of an existing cluster
are changed when they differ from the configuration (`Set-NlbCluster`). A new
primary IP address replaces the current primary virtual IP address
(`Set-NlbClusterVip`) when the subnet mask stays the same, otherwise the new
address is added as virtual IP address, made the primary IP address and the
previous primary IP address is removed.

`DedicatedIP` and `DedicatedIPSubnetMask` are only used when the cluster is
created. To manage dedicated IP addresses afterwards use the resource
[NlbClusterNodeDip](NlbClusterNodeDip). Additional virtual IP addresses are
managed with the resource [NlbClusterVip](NlbClusterVip).

## Requirements

- Target machine must be running Windows Server 2012 or later.
- The network interface given in `InterfaceName` must exist and should have a
  static IP address.
- When `OperationMode` is `Unicast` the node should have a second network
  interface for management traffic, because in unicast mode the hosts in the
  cluster can not communicate with each other through the cluster interface.

## Known issues

- Changing `ClusterPrimaryIP` or `OperationMode` of a cluster in production
  interrupts the client connections while the cluster converges again.
- The subnet mask of the current primary IP address can not be changed in
  place. Use a different primary IP address or recreate the cluster.
