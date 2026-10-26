# Cmdlet coverage

NlbDsc covers all 35 cmdlets of the PowerShell module
[NetworkLoadBalancingClusters](https://learn.microsoft.com/en-us/powershell/module/networkloadbalancingclusters/).
The table shows which resource uses which cmdlet.

| Cmdlet | Resource | Used for |
| --- | --- | --- |
| `Get-NlbCluster` | All resources (via `Get-NlbDscCluster`) | Read |
| `New-NlbCluster` | NlbClusterDeployment | Create the cluster (incl. `-DedicatedIP`, `-DedicatedIPSubnetMask`, `-Force` through `OverrideDhcp`) |
| `Set-NlbCluster` | NlbClusterDeployment | Change `-Name`, `-OperationMode` and `-ClusterPrimaryIP` |
| `Remove-NlbCluster` | NlbClusterDeployment | `Ensure = 'Absent'` |
| `Start-NlbCluster` | NlbClusterState | `State = 'Started'` |
| `Stop-NlbCluster` | NlbClusterState | `State = 'Stopped'` (with `-Drain`/`-Timeout`) |
| `Suspend-NlbCluster` | NlbClusterState | `State = 'Suspended'` |
| `Resume-NlbCluster` | NlbClusterState | Before `Started`/`Stopped` when nodes are suspended |
| `Get-NlbClusterDriverInfo` | NlbClusterDeployment | Read property `ClusterMacAddress` (local node only) |
| `Get-NlbClusterNodeNetworkInterface` | NlbClusterDeployment | Verify the interface (exists, DHCP) before the cluster is created |
| `New-NlbClusterIpv6Address` | - | Not used, see below |
| `Get-NlbClusterVip` | NlbClusterVip, NlbClusterDeployment | Read |
| `Add-NlbClusterVip` | NlbClusterVip, NlbClusterDeployment | Add a virtual IP address; new primary IP address with a new subnet mask |
| `Set-NlbClusterVip` | NlbClusterDeployment | Replace the primary IP address in place (same subnet mask) |
| `Remove-NlbClusterVip` | NlbClusterVip, NlbClusterDeployment | Remove a virtual IP address; previous primary IP address |
| `Get-NlbClusterNode` | NlbClusterNode, NlbClusterNodeState, NlbClusterState, NlbClusterNodeDip, NlbClusterPortRuleNode, NlbClusterDeployment | Read |
| `Add-NlbClusterNode` | NlbClusterNode | Add a node (`-Force`) |
| `Set-NlbClusterNode` | NlbClusterNode | `HostPriority`, `InitialHostState`, `RetainSuspended` |
| `Remove-NlbClusterNode` | NlbClusterNode | `Ensure = 'Absent'` |
| `Start-NlbClusterNode` | NlbClusterNodeState | `State = 'Started'` |
| `Stop-NlbClusterNode` | NlbClusterNodeState | `State = 'Stopped'` (with `-Drain`/`-Timeout`) |
| `Suspend-NlbClusterNode` | NlbClusterNodeState | `State = 'Suspended'` |
| `Resume-NlbClusterNode` | NlbClusterNodeState | Before `Started`/`Stopped` when the node is suspended |
| `Get-NlbClusterNodeDip` | NlbClusterNodeDip | Read |
| `Add-NlbClusterNodeDip` | NlbClusterNodeDip | Add a dedicated IP address |
| `Set-NlbClusterNodeDip` | - | Not used, see below |
| `Remove-NlbClusterNodeDip` | NlbClusterNodeDip | Remove a dedicated IP address |
| `Get-NlbClusterPortRule` | NlbClusterPortRule, NlbClusterPortRuleNode | Read (cluster-wide and node specific) |
| `Add-NlbClusterPortRule` | NlbClusterPortRule | Add a port rule |
| `Set-NlbClusterPortRule` | NlbClusterPortRule | Change port range, protocol, mode, affinity, timeout |
| `Remove-NlbClusterPortRule` | NlbClusterPortRule | `Ensure = 'Absent'` |
| `Enable-NlbClusterPortRule` | NlbClusterPortRule, NlbClusterPortRuleNode | `State = 'Enabled'` (`-ClusterWide` or one node) |
| `Disable-NlbClusterPortRule` | NlbClusterPortRule, NlbClusterPortRuleNode | `State = 'Disabled'` (`-ClusterWide` or one node, `-Drain`/`-Timeout`) |
| `Set-NlbClusterPortRuleNodeWeight` | NlbClusterPortRuleNode | `LoadWeight`, `EqualLoad` |
| `Set-NlbClusterPortRuleNodeHandlingPriority` | NlbClusterPortRuleNode | `HandlingPriority` |

## Cmdlets that are deliberately not used

### New-NlbClusterIpv6Address

The cmdlet generates a *new* IPv6 address every time it is called. Using it in
a DSC resource would make the configuration non-idempotent - every consistency
check would see a different desired address. Generate the address once
interactively and put it into the configuration:

```powershell
New-NlbClusterIpv6Address -InterfaceName 'NLB' -Global
```

Then use the address with [NlbClusterVip](NlbClusterVip) or
[NlbClusterNodeDip](NlbClusterNodeDip).

### Set-NlbClusterNodeDip

The cmdlet replaces one dedicated IP address by another one. In a declarative
configuration this is expressed by two resources: the old address with
`Ensure = 'Absent'` and the new address with `Ensure = 'Present'`. The
cmdlet can not change the subnet mask, so NlbClusterNodeDip removes and adds
the address when the subnet mask differs.

## Not used parameters

- `Set-NlbClusterNode -Reload` reloads the driver settings of the local node.
  This is an action, not a state, and is not needed by the resources.
- `Get-NlbClusterDriverInfo -Filter`, `-ConvergenceHistory`,
  `-ExtendedAffinityList`, `-ExtendedAffinityExceptionList` and
  `-OpenConnections` are diagnostic queries without a desired state. Run them
  interactively when troubleshooting (see [Troubleshooting](Troubleshooting)).

## Remote execution

All resources accept `HostName`. The NLB cmdlets then manage the cluster
through the given host (WMI/DCOM). Only `Get-NlbClusterDriverInfo` is limited
to the local node, therefore `ClusterMacAddress` of NlbClusterDeployment is
only returned when `HostName` is empty or the local node.
