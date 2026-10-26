# Troubleshooting

## Get verbose output

All resources write detailed verbose messages. Every message has an ID (for
example `NLBCD0010`) that makes it easy to search for it in the source code.

```powershell
Start-DscConfiguration -Path .\WebCluster -Wait -Verbose -Force
```

To test a resource without a configuration, use `Invoke-DscResource`:

```powershell
Invoke-DscResource -Name NlbClusterDeployment -ModuleName NlbDsc -Method Test -Verbose -Property @{
    ClusterName      = 'web.contoso.com'
    InterfaceName    = 'NLB'
    ClusterPrimaryIP = '192.168.10.100'
    SubnetMask       = '255.255.255.0'
}
```

## The NLB feature is not installed

`Get-TargetResource` and `Test-TargetResource` never fail because of a missing
feature - the resource is reported as not in the desired state. The features
`NLB` and `RSAT-NLB` are installed by `Set-TargetResource` of
[NlbClusterDeployment](NlbClusterDeployment) and [NlbClusterNode](NlbClusterNode).
[NlbClusterPortRule](NlbClusterPortRule) does not install features, because a
port rule requires an existing cluster.

If the installation requires a restart, the resource requests it from the LCM.
Make sure the LCM is allowed to restart the node (`RebootNodeIfNeeded = $true`),
otherwise run the configuration again after a manual restart.

Check the features manually:

```powershell
Get-WindowsFeature -Name NLB, RSAT-NLB
```

## The term 'Get-NlbCluster' is not recognized

The PowerShell module `NetworkLoadBalancingClusters` is part of the feature
`RSAT-NLB`. If only `NLB` was installed (for example by an older configuration
with `WindowsFeature`), install the management tools:

```powershell
Install-WindowsFeature -Name RSAT-NLB
```

## The node loses network connectivity after the cluster was created

In `Unicast` mode NLB replaces the MAC address of the cluster interface with
the cluster MAC address. The connection drops briefly while this happens, and
afterwards the hosts of the same cluster can no longer communicate with each
other through that interface (for example remote management of one cluster
host from another one). Use a dedicated second network interface for
management and cluster-internal traffic (recommended) or use
`OperationMode = 'Multicast'`.

## Adding a node fails

- When the resource [NlbClusterNode](NlbClusterNode) runs on an existing
  cluster host and adds a *remote* node, the feature `NLB` must already be
  installed on that remote node. Prefer running the resource on the joining
  node itself with `HostName` set to an existing cluster host - then the
  feature is installed automatically.
- The LCM runs as `SYSTEM`, so the **computer account** of the node needs
  administrative permissions on every cluster host it manages remotely.
- The remote host must be reachable through WMI/DCOM (Windows Firewall rule
  group *Windows Management Instrumentation (WMI)*).

## Changing the cluster name or IP address

[NlbClusterDeployment](NlbClusterDeployment) changes the name
(`Set-NlbCluster -Name`) and the primary IP address of an existing cluster.
Both changes make all nodes converge again and interrupt client connections
briefly - plan them for a maintenance window.

Only the subnet mask of the *current* primary IP address can not be changed in
place (error `NLBCD0014`). Use a different primary IP address with the new
subnet mask, or recreate the cluster.

## A node or the whole cluster stays stopped

NLB reports the states `Converged`, `Converging`, `Draining`, `Stopped` and
`Suspended`. A suspended node ignores all start and stop commands until it is
resumed. [NlbClusterNodeState](NlbClusterNodeState) and
[NlbClusterState](NlbClusterState) resume suspended nodes automatically when
`Started` or `Stopped` is requested.

Check the `InitialHostState` (and `RetainSuspended`) of the node with
[NlbClusterNode](NlbClusterNode) if a node does not start after a restart.

Do not manage the same node with both NlbClusterNodeState and
NlbClusterState - the two resources would undo each other's changes.

## Different units for drain timeouts

The NLB cmdlets use different units, and the resources follow them:

| Resource | Cmdlet | Unit of `DrainTimeout` |
| --- | --- | --- |
| NlbClusterNodeState | `Stop-NlbClusterNode -Timeout` | seconds |
| NlbClusterState | `Stop-NlbCluster -Timeout` | minutes |
| NlbClusterPortRule | `Disable-NlbClusterPortRule -Timeout` | minutes |
| NlbClusterPortRuleNode | `Disable-NlbClusterPortRule -Timeout` | minutes |
