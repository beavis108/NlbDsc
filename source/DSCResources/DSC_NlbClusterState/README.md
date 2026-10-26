# Description

This resource is used to start, stop or suspend **all** nodes of a Network
Load Balancing (NLB) cluster at once (`Start-NlbCluster`, `Stop-NlbCluster`,
`Suspend-NlbCluster`, `Resume-NlbCluster`).

The resource is in the desired state when every node of the cluster has the
desired host state. Suspended nodes are resumed (`Resume-NlbCluster`) before
the cluster is started or stopped. A node that is `Draining` is treated as
`Stopped`.

This is typically used for maintenance windows, for example to suspend the
cluster while it is reconfigured.

## Requirements

- Target machine must be running Windows Server 2012 or later.
- The NLB cluster must already exist.

## Known issues

- Do not combine this resource with [NlbClusterNodeState](NlbClusterNodeState)
  for the same cluster. Both would manage the state of the same nodes.
- `DrainTimeout` is specified in **minutes** (as for `Stop-NlbCluster`).
