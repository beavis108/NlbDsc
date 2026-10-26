# Welcome to the NlbDsc wiki

<sup>*NlbDsc v#.#.#*</sup>

Here you will find all the information you need to make use of the NlbDsc
DSC resources in the latest release. This includes details of the resources
that are available, current capabilities and known issues, and information
to help plan a DSC based implementation of Windows Network Load Balancing
(NLB) clusters.

Please leave comments, feature requests, and bug reports for this module in
the [issues section](https://github.development.tega.intranetbw.de/ChristophMeyer/NlbDsc/issues)
for this repository.

## Resources

| Resource | Description |
| --- | --- |
| [NlbClusterDeployment](NlbClusterDeployment) | Creates, changes (name, primary IP address, operation mode) or removes an NLB cluster and installs the required Windows features. |
| [NlbClusterNode](NlbClusterNode) | Adds a node to (or removes a node from) an NLB cluster and configures host priority, initial host state and retain suspended. |
| [NlbClusterNodeState](NlbClusterNodeState) | Starts, stops (with drain), suspends or resumes a single node. |
| [NlbClusterState](NlbClusterState) | Starts, stops (with drain), suspends or resumes all nodes of a cluster. |
| [NlbClusterPortRule](NlbClusterPortRule) | Adds, updates, enables, disables or removes a port rule of an NLB cluster. |
| [NlbClusterPortRuleNode](NlbClusterPortRuleNode) | Configures load weight, equal load, handling priority and the state of a port rule on a single node. |
| [NlbClusterVip](NlbClusterVip) | Adds or removes additional virtual IP addresses (IPv4/IPv6) of a cluster. |
| [NlbClusterNodeDip](NlbClusterNodeDip) | Adds or removes dedicated IP addresses (IPv4/IPv6) of a node. |

All 35 cmdlets of the PowerShell module `NetworkLoadBalancingClusters` are
covered - see [Cmdlet coverage](Cmdlet-Coverage) for which resource uses
which cmdlet.

## Deprecated resources

The documentation, examples, unit test, and integration tests have been removed
for these deprecated resources. These resources will be removed
in a future release.

*No deprecated resources*.

If you are upgrading from the module **xNLB**, read
[Migration from xNLB](Migration-from-xNLB).

## Getting started

To get started either:

- Install from the PowerShell Gallery using PowerShellGet by running the
  following command:

```powershell
Install-Module -Name NlbDsc -Repository PSGallery
```

- Download NlbDsc from the [PowerShell Gallery](https://www.powershellgallery.com/packages/NlbDsc/)
  and then unzip it to one of your PowerShell modules folders (such as
  `$env:ProgramFiles\WindowsPowerShell\Modules`).

- For offline or air-gapped environments, copy the folder `NlbDsc\<version>`
  to `$env:ProgramFiles\WindowsPowerShell\Modules` on the authoring machine
  and on every target node (or publish it on your pull server).

To confirm installation, run the below command and ensure you see the NlbDsc
DSC resources available:

```powershell
Get-DscResource -Module NlbDsc
```

## Prerequisites

### Operating system

The resources require Windows Server 2012 or later. Network Load Balancing is
not available on client operating systems.

The Windows features `NLB` and `RSAT-NLB` do **not** have to be installed in
advance. The resources [NlbClusterDeployment](NlbClusterDeployment) and
[NlbClusterNode](NlbClusterNode) install them when they are missing.

### Powershell

The minimum Windows Management Framework (PowerShell) version required is 5.0
or higher, which ships with Windows 10 or Windows Server 2016,
but can also be installed on Windows 7 SP1, Windows 8.1, Windows Server 2012,
and Windows Server 2012 R2.

## Further reading

- [Cmdlet coverage](Cmdlet-Coverage)
- [Troubleshooting](Troubleshooting)
- [Migration from xNLB](Migration-from-xNLB)

## Change log

A full list of changes in each version can be found in the [change log](https://github.development.tega.intranetbw.de/ChristophMeyer/NlbDsc/blob/main/CHANGELOG.md).
