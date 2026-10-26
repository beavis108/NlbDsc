# Change log for NlbDsc

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.1] - 2026-10-23

### Changed

- Project, license, issue and wiki links point to the repository on the
  internal GitHub Enterprise server
  (`https://github.development.tega.intranetbw.de/ChristophMeyer/NlbDsc`).
- README: Removed the badges of Azure DevOps, Codecov and the PowerShell
  Gallery, which can not be reached from the internal network.

### Fixed

- Build: Added the placeholder `source/NlbDsc.psm1`. ModuleBuilder copies the
  root module from the source folder; without it no `NlbDsc.psm1` was built
  and `./build.ps1 -Tasks build` failed with
  `Cannot find path '...\NlbDsc.psm1'`.
- Test: The code coverage of the unit tests (83.7 %) was below the threshold
  of 85 % in `build.yaml`, so `./build.ps1 -Tasks test` failed. Added unit
  tests for `Get-TargetResource` of NlbClusterNodeDip, NlbClusterNodeState and
  NlbClusterPortRuleNode, `Test-TargetResource` of NlbClusterNodeDip and
  further `Set-TargetResource` cases (coverage now 92.4 %).
- NlbClusterPortRule, NlbClusterPortRuleNode: Replaced the alias
  `New-InvalidArgumentException` with `New-ArgumentException`
  (required HQRM rule `PSAvoidUsingCmdletAliases`).
- NlbClusterNodeDip, NlbClusterVip: Hashtable formatted according to the DSC
  Community style guideline (HQRM rule `Measure-Hashtable`).
- NlbClusterNode, NlbDsc.Common (`ConvertFrom-NlbPortRule`): Replaced
  one-line `if`/`else` expressions with statement blocks (analyzer rules
  `PSPlaceOpenBrace` and `PSPlaceCloseBrace` of the repository settings).
- Documentation: The read-only array properties `Nodes` (NlbClusterDeployment)
  and `NodeStates` (NlbClusterState) are now listed in the wiki and in the
  conceptual help, tables in the conceptual help are rendered as text tables.
- Example `3-TwoNodeWebCluster.ps1`: Suppressed the HQRM rule
  `PSUseDeclaredVarsMoreThanAssignments` for `$ConfigurationData`, which is
  passed to the configuration with `-ConfigurationData`.

## [1.1.0] - 2026-10-22

### Added

- All 35 cmdlets of the module `NetworkLoadBalancingClusters` are now covered
  by the resources (see the wiki page *Cmdlet coverage*).
- New resources:
  - `NlbClusterVip` - additional virtual IP addresses (IPv4/IPv6) of a cluster
    (`Get-`/`Add-`/`Remove-NlbClusterVip`).
  - `NlbClusterNodeDip` - dedicated IP addresses of a node
    (`Get-`/`Add-`/`Remove-NlbClusterNodeDip`).
  - `NlbClusterNodeState` - start, stop (with drain), suspend and resume a
    single node (`Start-`/`Stop-`/`Suspend-`/`Resume-NlbClusterNode`).
  - `NlbClusterState` - start, stop (with drain), suspend and resume all nodes
    (`Start-`/`Stop-`/`Suspend-`/`Resume-NlbCluster`).
  - `NlbClusterPortRuleNode` - node specific port rule settings: load weight,
    equal load, handling priority and per node enable/disable with drain
    (`Set-NlbClusterPortRuleNodeWeight`,
    `Set-NlbClusterPortRuleNodeHandlingPriority`,
    `Enable-`/`Disable-NlbClusterPortRule`).
- NlbClusterDeployment
  - Added `DedicatedIP`, `DedicatedIPSubnetMask` and `OverrideDhcp`
    (`New-NlbCluster -DedicatedIP -DedicatedIPSubnetMask -Force`).
  - The interface is verified with `Get-NlbClusterNodeNetworkInterface`
    before the cluster is created (missing interface, DHCP).
  - The cluster name and the primary IP address of an existing cluster are
    now changed (`Set-NlbCluster -Name -ClusterPrimaryIP`,
    `Set-NlbClusterVip`, `Add-`/`Remove-NlbClusterVip`) instead of throwing.
  - Added the read properties `Nodes` and `ClusterMacAddress`
    (`Get-NlbClusterDriverInfo`).
- NlbClusterNode
  - Added `HostPriority`, `InitialHostState` and `RetainSuspended`
    (`Set-NlbClusterNode`).
- NlbClusterPortRule
  - Added `State`, `Drain` and `DrainTimeout` to enable or disable a port rule
    on all nodes (`Enable-`/`Disable-NlbClusterPortRule -ClusterWide`).
- NlbDsc.Common
  - Added `Get-NlbObjectPropertyValue`, `ConvertFrom-NlbPortRule`,
    `ConvertTo-NlbCmdletIPAddress`, `ConvertTo-NlbNodeState`,
    `Find-NlbClusterNode`, `Find-NlbClusterPortRule`, `Get-NlbShortName` and
    `Test-NlbIPAddressEqual`.

### Fixed

- NlbClusterPortRule: Port rule objects expose the properties
  `VirtualIPAddress`, `FilteringMode` and `PortState` (the table view shows
  them as `IPAddress`, `Mode` and `State`). The resource now reads both
  naming variants, so the filtering mode is no longer reported empty.
- NlbClusterNode: The node interface is read from the property
  `InterfaceName`.
- NlbClusterNode: `Add-NlbClusterNode` is called with `-Force` so the LCM is
  never blocked by a confirmation prompt.
- NlbClusterPortRule: `Set-NlbClusterPortRule` is only called when a setting
  actually differs.
- IPv6 addresses are compared by value instead of by their text.

## [1.0.0] - 2026-10-22

### Added

- Module renamed from `xNLB` to `NlbDsc` and restructured to follow the
  DSC Community module layout (Sampler build, `source` folder, nested
  `NlbDsc.Common` module, `DscResource.Common` 0.24.5, unit tests,
  examples, conceptual help and wiki).
- NlbDsc.Common
  - Added `Test-NlbFeatureInstalled`, `Install-NlbFeature`, `Import-NlbModule`,
    `Get-NlbDscCluster`, `ConvertTo-NlbDscValue` and
    `ConvertTo-NlbPortRuleIPAddress`.
- NlbClusterDeployment
  - Added the property `Ensure` so a cluster can also be removed.
  - Added the read property `FeatureInstalled`.
  - The operation mode of an existing cluster is now corrected.
- NlbClusterPortRule
  - Added the property `Ensure` so a port rule can also be removed.
  - Added the property `HostName`.
- NlbClusterNode
  - Added the property `Ensure` so a node can also be removed.
  - Added the read property `State`.
  - The resource can now run on the joining node (set `HostName` to an
    existing cluster host).

### Changed

- BREAKING CHANGE: Resources renamed and prefix changed from `MSFT_` to `DSC_`:
  - `xNLBClusterDeployment` → `NlbClusterDeployment`.
  - `xNLBClusterConfiguration` → `NlbClusterPortRule` (the resource only
    ever managed port rules).
  - `xNLBAddAdditionalNode` → `NlbClusterNode`.
- BREAKING CHANGE: Schema keys corrected. Previously every property was a key
  property, which allowed the same cluster or rule to be declared multiple
  times with conflicting values.
  - NlbClusterDeployment: Key `ClusterName`; `InterfaceName`,
    `ClusterPrimaryIP` and `SubnetMask` are required; `HostName` and
    `OperationMode` are optional.
  - NlbClusterPortRule: Keys `InterfaceName`, `IPAddress`, `StartPort`;
    `EndPort` is required; `IP` was renamed to `IPAddress`; ports and timeout
    are now numeric (`UInt16`/`UInt32`) instead of strings.
  - NlbClusterNode: Key `NodeName` (was `NewNodeName`); `NewNodeInterface`
    was renamed to `NodeInterfaceName`; `HostName` is optional.
- BREAKING CHANGE: NlbClusterPortRule - the default value of `Affinity` is
  now `Single`, the same default NLB uses.
- All values with a fixed set of values (`OperationMode`, `Protocol`,
  `Mode`, `Affinity`, `Ensure`) are now validated through a `ValueMap`.
- All verbose and error messages are localized.
- Errors are no longer written with `Write-Host` and swallowed - a failing
  `Set-TargetResource` now fails the configuration as expected.

### Fixed

- All resources failed when the Windows feature for Network Load Balancing
  was not installed yet, because the module `NetworkLoadBalancingClusters`
  was imported when the resource module was loaded. The module is now
  imported on demand (globally, so it also works inside `wmiprvse.exe`)
  after the features `NLB` and `RSAT-NLB` have been verified.
  NlbClusterDeployment and NlbClusterNode install the features
  automatically and request a restart if needed.
  `Get-TargetResource` and `Test-TargetResource` no longer throw on a node
  without NLB - the resource is reported as not in the desired state.
- The variable `$localhost` was used but never defined.
- NlbClusterPortRule
  - The port rule was parsed by splitting its string representation, which
    broke for different formats. The properties of the port rule object are
    now used.
  - `Set-TargetResource` updated _all_ port rules of the cluster instead of
    the declared one.
  - `Affinity` and `Timeout` were sent to NLB even for the modes `Single`
    and `Disabled`, where NLB does not support them, and were compared in
    `Test-TargetResource` causing a permanent drift.
  - `Test-TargetResource` compared values case-sensitively against values
    NLB returns in different casing.
- NlbClusterNode
  - `Test-TargetResource` returned the inverted result (`$false` when the
    node was already a member of the cluster), which made the LCM try to add
    the node again on every consistency check.
  - Fully qualified and short node names are now matched.
- NlbClusterDeployment
  - `Set-TargetResource` always called `New-NlbCluster`, also when the
    cluster already existed.
- Module manifest: typo in the description, wildcard exports and missing
  metadata fixed.
