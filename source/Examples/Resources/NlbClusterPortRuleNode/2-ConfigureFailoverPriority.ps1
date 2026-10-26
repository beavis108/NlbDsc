<#
    .DESCRIPTION
        This example shows an active/passive configuration for a port rule with
        the filtering mode Single: web01 handles all traffic for port 1433
        (handling priority 1), web02 takes over when web01 fails.
#>

configuration Example
{
    Import-DscResource -ModuleName 'NlbDsc'

    node localhost {

        NlbClusterPortRule Sql {
            InterfaceName = 'NLB'
            IPAddress     = '192.168.10.100'
            StartPort     = 1433
            EndPort       = 1433
            Protocol      = 'Tcp'
            Mode          = 'Single'
        }

        NlbClusterPortRuleNode SqlPrimary {
            NodeName         = 'web01.contoso.com'
            InterfaceName    = 'NLB'
            IPAddress        = '192.168.10.100'
            StartPort        = 1433
            HandlingPriority = 1
            DependsOn        = '[NlbClusterPortRule]Sql'
        }

        NlbClusterPortRuleNode SqlSecondary {
            NodeName         = 'web02.contoso.com'
            InterfaceName    = 'NLB'
            IPAddress        = '192.168.10.100'
            StartPort        = 1433
            HandlingPriority = 2
            DependsOn        = '[NlbClusterPortRule]Sql'
        }
    }
}
