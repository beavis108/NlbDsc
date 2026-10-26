# Description

This resource is used to add a node to (or remove a node from) an existing
Network Load Balancing (NLB) cluster.

The resource can be used in two ways:

- **On the joining node (recommended).** Set `NodeName` to the local node and
  `HostName` to an existing cluster host. When the Windows features `NLB` and
  `RSAT-NLB` are missing on the joining node, the resource installs them before
  the node is added to the cluster.
- **On an existing cluster host.** Leave `HostName` empty and set `NodeName` to
  the remote node. The Windows feature `NLB` must then already be installed on
  the remote node.

`HostPriority`, `InitialHostState` and `RetainSuspended` are applied with
`Set-NlbClusterNode`. They are only evaluated when they are specified. The
host priority must be unique in the cluster - a node with a conflicting
priority is not accepted by the cluster. To start, stop or suspend a node use
the resource [NlbClusterNodeState](NlbClusterNodeState).

Node names are compared by their host name part, so `web02` and
`web02.contoso.com` are treated as the same node.

## Requirements

- Target machine must be running Windows Server 2012 or later.
- The NLB cluster must already exist, e.g. created with the resource
  [NlbClusterDeployment](NlbClusterDeployment).
- The account the LCM runs as (by default the computer account) must be a
  local administrator on all cluster hosts that are managed remotely.
