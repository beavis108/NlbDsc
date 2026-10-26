# Description

This resource is used to configure the node specific settings of a port rule
of a Network Load Balancing (NLB) cluster:

- `LoadWeight` or `EqualLoad` for port rules with the filtering mode
  `Multiple` (`Set-NlbClusterPortRuleNodeWeight`).
- `HandlingPriority` for port rules with the filtering mode `Single`
  (`Set-NlbClusterPortRuleNodeHandlingPriority`).
- `State` to enable or disable the port rule on this node only
  (`Enable-NlbClusterPortRule`, `Disable-NlbClusterPortRule` with optional
  `Drain`).

Only the properties that are specified are evaluated. Properties that do not
apply to the filtering mode of the port rule are ignored with a verbose
message, so a configuration does not drift when the filtering mode is changed.

The load weight is relative: the share of traffic of a node is its load weight
divided by the sum of the load weights of all nodes. A load weight of `0`
prevents the node from handling traffic for the port rule.

## Requirements

- Target machine must be running Windows Server 2012 or later.
- The port rule must already exist, e.g. created with the resource
  [NlbClusterPortRule](NlbClusterPortRule).
- The node must already be a member of the cluster.

## Known issues

- The handling priority of each node must be unique per port rule.
