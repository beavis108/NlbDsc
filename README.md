# NlbDsc

This module contains DSC resources for the deployment and configuration of
Microsoft Windows Network Load Balancing (NLB) clusters.

## Code of Conduct

This project has adopted this [Code of Conduct](CODE_OF_CONDUCT.md).

## Releases

For each merge to the branch `main` a preview release will be
deployed to [PowerShell Gallery](https://www.powershellgallery.com/).
Periodically a release version tag will be pushed which will deploy a
full release to [PowerShell Gallery](https://www.powershellgallery.com/).

## Resources

| Resource | Description |
| --- | --- |
| **NlbClusterDeployment** | Creates, changes or removes an NLB cluster. Installs the Windows features `NLB` and `RSAT-NLB` when they are missing. |
| **NlbClusterNode** | Adds a node to (or removes a node from) an NLB cluster; host priority, initial host state, retain suspended. |
| **NlbClusterNodeState** | Starts, stops (with drain), suspends or resumes a single node. |
| **NlbClusterState** | Starts, stops (with drain), suspends or resumes all nodes of a cluster. |
| **NlbClusterPortRule** | Adds, updates, enables, disables or removes a port rule. |
| **NlbClusterPortRuleNode** | Load weight, equal load, handling priority and state of a port rule on a single node. |
| **NlbClusterVip** | Additional virtual IP addresses (IPv4/IPv6) of a cluster. |
| **NlbClusterNodeDip** | Dedicated IP addresses (IPv4/IPv6) of a node. |

All 35 cmdlets of the PowerShell module `NetworkLoadBalancingClusters` are
covered. The wiki page
[Cmdlet coverage](https://github.development.tega.intranetbw.de/ChristophMeyer/NlbDsc/wiki/Cmdlet-Coverage)
shows which resource uses which cmdlet.

The resources require Windows Server 2012 or later and Windows Management
Framework (PowerShell) 5.0 or later.

> [!NOTE]
> The Windows features for Network Load Balancing do not have to be
> installed in advance. `NlbClusterDeployment` and `NlbClusterNode` install
> `NLB` and `RSAT-NLB` themselves and request a restart from the LCM if needed.

## Installation

```powershell
Install-Module -Name NlbDsc -Repository PSGallery
```

For offline or air-gapped environments copy the folder `NlbDsc\<version>` to
`$env:ProgramFiles\WindowsPowerShell\Modules` on the authoring machine and on
every target node (or publish it on your pull server).

```powershell
Get-DscResource -Module NlbDsc
```

## Quick start

```powershell
configuration WebCluster
{
    Import-DscResource -ModuleName 'NlbDsc'

    node 'web01.contoso.com' {
        NlbClusterDeployment Cluster {
            ClusterName      = 'web.contoso.com'
            InterfaceName    = 'NLB'
            ClusterPrimaryIP = '192.168.10.100'
            SubnetMask       = '255.255.255.0'
            OperationMode    = 'Multicast'
        }

        NlbClusterPortRule Web {
            InterfaceName = 'NLB'
            IPAddress     = 'All'
            StartPort     = 80
            EndPort       = 443
            Protocol      = 'Tcp'
            Affinity      = 'None'
            DependsOn     = '[NlbClusterDeployment]Cluster'
        }
    }

    node 'web02.contoso.com' {
        NlbClusterNode Join {
            NodeName          = 'web02.contoso.com'
            NodeInterfaceName = 'NLB'
            HostName          = 'web01.contoso.com'
            InterfaceName     = 'NLB'
        }
    }
}
```

## Upgrading from xNLB

NlbDsc replaces the module `xNLB`. The resources were renamed and their
schemas corrected, so existing configurations have to be adjusted once. See
[Migration from xNLB](https://github.development.tega.intranetbw.de/ChristophMeyer/NlbDsc/wiki/Migration-from-xNLB)
in the wiki for a property-by-property mapping.

## Contributing

Please check out common DSC Community [contributing guidelines](https://dsccommunity.org/guidelines/contributing).

To build the module and run the tests locally:

```powershell
./build.ps1 -ResolveDependency -Tasks build, test
```

## Change log

A full list of changes in each version can be found in the [change log](CHANGELOG.md).

## Documentation

The documentation can be found in the [NlbDsc Wiki](https://github.development.tega.intranetbw.de/ChristophMeyer/NlbDsc/wiki).
The DSC resource schema files are used to automatically update the
documentation on each PR merge.

### Examples

You can review the [Examples](/source/Examples) directory in the NlbDsc module
for some general use scenarios for all of the resources that are in the module.

The resource examples are also available in the [NlbDsc Wiki](https://github.development.tega.intranetbw.de/ChristophMeyer/NlbDsc/wiki).
