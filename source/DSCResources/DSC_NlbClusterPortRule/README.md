# Description

This resource is used to add, update or remove a port rule of a Network Load
Balancing (NLB) cluster.

A port rule is identified by the interface the cluster is bound to, the cluster
IP address (`IPAddress`) and the port given in `StartPort`. The resource looks
for an existing rule with the same IP address whose port range contains
`StartPort`. If such a rule exists it is updated in place, otherwise a new rule
is added. This allows to change the default port rule (`0` - `65535`) that NLB
creates together with a new cluster.

Use `IPAddress = 'All'` for a port rule that applies to all cluster IP addresses
(this is also how the default port rule is configured).

`State` enables or disables the port rule on all cluster nodes
(`Enable-NlbClusterPortRule -ClusterWide` / `Disable-NlbClusterPortRule
-ClusterWide`). It is only evaluated when it is specified, so it does not
conflict with node specific states set by
[NlbClusterPortRuleNode](NlbClusterPortRuleNode). With `Drain = $true`
existing connections are drained (at most `DrainTimeout` minutes) before the
rule is disabled.

Node specific settings of a port rule (load weight, handling priority, state
on a single node) are managed with the resource
[NlbClusterPortRuleNode](NlbClusterPortRuleNode).

`Affinity` and `Timeout` are only applied and evaluated when `Mode` is
`Multiple`, because NLB ignores them for the other filtering modes.

## Requirements

- Target machine must be running Windows Server 2012 or later.
- The NLB cluster must already exist, e.g. created with the resource
  [NlbClusterDeployment](NlbClusterDeployment). Use `DependsOn` to make sure
  the cluster is created first.

## Known issues

- With `Ensure = 'Absent'` the rule that covers `StartPort` is removed, even
  if its port range is larger than the range given in the configuration.
