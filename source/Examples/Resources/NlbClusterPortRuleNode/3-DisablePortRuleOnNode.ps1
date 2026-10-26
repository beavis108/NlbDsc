<#
    .DESCRIPTION
        This example shows how to disable the port rule for port 80 on a single
        node only. Existing connections are drained for at most 5 minutes.
#>

configuration Example
{
    Import-DscResource -ModuleName 'NlbDsc'

    node localhost {

        NlbClusterPortRuleNode Web02NoHttp {
            NodeName      = 'web02.contoso.com'
            InterfaceName = 'NLB'
            IPAddress     = 'All'
            StartPort     = 80
            State         = 'Disabled'
            Drain         = $true
            DrainTimeout  = 5
        }
    }
}
