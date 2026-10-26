# Description

This resource is used to start, stop or suspend a single node of a Network
Load Balancing (NLB) cluster (`Start-NlbClusterNode`, `Stop-NlbClusterNode`,
`Suspend-NlbClusterNode`, `Resume-NlbClusterNode`).

| Desired state | Current state | Action |
| --- | --- | --- |
| `Started` | `Stopped` | `Start-NlbClusterNode` |
| `Started` | `Suspended` | `Resume-NlbClusterNode`, then `Start-NlbClusterNode` |
| `Stopped` | `Started` | `Stop-NlbClusterNode` (with `-Drain` when `Drain` is `$true`) |
| `Stopped` | `Suspended` | `Resume-NlbClusterNode` (a resumed node is stopped) |
| `Suspended` | `Started` or `Stopped` | `Suspend-NlbClusterNode` |

A node that is `Draining` is treated as `Stopped`, so a running drain operation
is not interrupted. NLB reports a running node as `Converged` or `Converging`;
both are treated as `Started`.

Use `InitialHostState` of the resource [NlbClusterNode](NlbClusterNode) to
define the state of the node after a restart.

## Requirements

- Target machine must be running Windows Server 2012 or later.
- The node must already be a member of the cluster, e.g. added with the
  resource [NlbClusterNode](NlbClusterNode).

## Known issues

- Do not combine this resource with [NlbClusterState](NlbClusterState) for the
  same cluster. Both would manage the state of the same node.
- `DrainTimeout` is specified in **seconds** (as for `Stop-NlbClusterNode`),
  while `DrainTimeout` of NlbClusterState and NlbClusterPortRule is specified
  in minutes.
