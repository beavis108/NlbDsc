<#
    .DESCRIPTION
        This example shows how to distribute the traffic of the port rule for
        ports 80 - 443 unevenly: web01 gets 70 percent, web02 30 percent.
#>

configuration Example
{
    Import-DscResource -ModuleName 'NlbDsc'

    node localhost {

        NlbClusterPortRuleNode Web01Weight {
            NodeName      = 'web01.contoso.com'
            InterfaceName = 'NLB'
            IPAddress     = 'All'
            StartPort     = 80
            LoadWeight    = 70
        }

        NlbClusterPortRuleNode Web02Weight {
            NodeName      = 'web02.contoso.com'
            InterfaceName = 'NLB'
            IPAddress     = 'All'
            StartPort     = 80
            LoadWeight    = 30
        }
    }
}
