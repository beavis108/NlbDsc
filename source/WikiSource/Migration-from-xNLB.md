# Migration from xNLB

NlbDsc 1.0.0 is the successor of the module **xNLB** 1.0.0.0. The module was
renamed, all resources were renamed and the schemas were corrected. A
configuration written for xNLB therefore has to be adjusted once.

## Why the update is recommended

- **The resources failed on nodes without the NLB feature.** xNLB imported the
  PowerShell module `NetworkLoadBalancingClusters` when the resource module was
  loaded. On a node where the Windows feature had not been installed yet, every
  resource failed - even when a `WindowsFeature` resource installed the feature
  earlier in the same configuration. NlbDsc imports the module on demand and
  installs the features `NLB` and `RSAT-NLB` itself.
- **`xNLBAddAdditionalNode` returned an inverted test result** and tried to add
  an existing node again on every consistency check.
- **`xNLBClusterConfiguration` overwrote all port rules** of the cluster, not
  only the declared one.
- **Errors were swallowed.** A failing `Set-TargetResource` was reported as
  successful because errors were only written with `Write-Host`.

## Module

| xNLB | NlbDsc |
| --- | --- |
| `Import-DscResource -ModuleName 'xNLB'` | `Import-DscResource -ModuleName 'NlbDsc'` |

Both modules can be installed side by side, but a configuration should only use
one of them for the same cluster.

## Resources

### xNLBClusterDeployment → NlbClusterDeployment

| xNLB property | NlbDsc property | Change |
| --- | --- | --- |
| `ClusterName` (Key) | `ClusterName` (Key) | - |
| `InterfaceName` (Key) | `InterfaceName` (Required) | No longer a key. |
| `ClusterPrimaryIP` (Key) | `ClusterPrimaryIP` (Required) | No longer a key. |
| `SubnetMask` (Key) | `SubnetMask` (Required) | No longer a key. |
| `HostName` (Key) | `HostName` (Write) | Optional, defaults to the local node. |
| `OperationMode` (Key) | `OperationMode` (Write) | Optional, defaults to `Unicast`, validated. |
| - | `Ensure` (Write) | New. |
| - | `FeatureInstalled` (Read) | New. |

### xNLBClusterConfiguration → NlbClusterPortRule

| xNLB property | NlbDsc property | Change |
| --- | --- | --- |
| `InterfaceName` (Key) | `InterfaceName` (Key) | - |
| `IP` (Key) | `IPAddress` (Key) | Renamed. Use `All` for all cluster IP addresses. |
| `StartPort` (Write, String) | `StartPort` (Key, UInt16) | Now part of the key, numeric. |
| `EndPort` (Write, String) | `EndPort` (Required, UInt16) | Now required, numeric. |
| `Protocol` (Key) | `Protocol` (Write) | Optional, defaults to `Both`, validated. |
| `Mode` (Key) | `Mode` (Write) | Optional, defaults to `Multiple`, validated. |
| `Affinity` (Key) | `Affinity` (Write) | Optional, **default changed from `None` to `Single`** (NLB default), validated. |
| `Timeout` (Write, String) | `Timeout` (Write, UInt32) | Numeric, 0 - 240. |
| `HostName` (Key) | `HostName` (Write) | Optional, defaults to the local node. |
| - | `Ensure` (Write) | New. |

### xNLBAddAdditionalNode → NlbClusterNode

| xNLB property | NlbDsc property | Change |
| --- | --- | --- |
| `NewNodeName` (Key) | `NodeName` (Key) | Renamed. |
| `NewNodeInterface` (Key) | `NodeInterfaceName` (Required) | Renamed. |
| `InterfaceName` (Key) | `InterfaceName` (Required) | No longer a key. |
| `HostName` (Key) | `HostName` (Write) | Optional, defaults to the local node. |
| - | `Ensure` (Write) | New. |
| - | `State` (Read) | New. |

## Example

### Before (xNLB)

```powershell
configuration WebCluster
{
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'xNLB'

    node 'web01' {
        WindowsFeature NLB {
            Name                 = 'NLB'
            IncludeAllSubFeature = $true
        }

        xNLBClusterDeployment Cluster {
            HostName         = 'web01.contoso.com'
            InterfaceName    = 'NLB'
            ClusterName      = 'web.contoso.com'
            ClusterPrimaryIP = '192.168.10.100'
            SubnetMask       = '255.255.255.0'
            OperationMode    = 'Unicast'
            DependsOn        = '[WindowsFeature]NLB'
        }

        xNLBClusterConfiguration PortRule {
            HostName      = 'web01.contoso.com'
            InterfaceName = 'NLB'
            IP            = '192.168.10.100'
            Affinity      = 'None'
            Mode          = 'Multiple'
            Protocol      = 'Tcp'
            StartPort     = '80'
            EndPort       = '443'
            DependsOn     = '[xNLBClusterDeployment]Cluster'
        }
    }
}
```

### After (NlbDsc)

```powershell
configuration WebCluster
{
    Import-DscResource -ModuleName 'NlbDsc'

    node 'web01' {
        NlbClusterDeployment Cluster {
            ClusterName      = 'web.contoso.com'
            InterfaceName    = 'NLB'
            ClusterPrimaryIP = '192.168.10.100'
            SubnetMask       = '255.255.255.0'
            OperationMode    = 'Unicast'
        }

        NlbClusterPortRule PortRule {
            InterfaceName = 'NLB'
            IPAddress     = '192.168.10.100'
            StartPort     = 80
            EndPort       = 443
            Protocol      = 'Tcp'
            Mode          = 'Multiple'
            Affinity      = 'None'
            DependsOn     = '[NlbClusterDeployment]Cluster'
        }
    }
}
```

The `WindowsFeature` resource is no longer needed. It does no harm to keep it,
but make sure it installs `RSAT-NLB` as well (`IncludeAllSubFeature` does not
install the management tools - use a second `WindowsFeature` resource for
`RSAT-NLB` or remove the resource).
