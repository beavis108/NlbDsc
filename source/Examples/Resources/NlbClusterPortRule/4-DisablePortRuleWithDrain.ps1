<#
    .DESCRIPTION
        This example shows how to disable the port rule for port 8080 on all
        cluster nodes. Existing connections are drained for at most 10 minutes
        before the rule is disabled.
#>

configuration Example
{
    Import-DscResource -ModuleName 'NlbDsc'

    node localhost {

        NlbClusterPortRule AlternativeHttp {
            InterfaceName = 'NLB'
            IPAddress     = '192.168.10.100'
            StartPort     = 8080
            EndPort       = 8080
            Protocol      = 'Tcp'
            State         = 'Disabled'
            Drain         = $true
            DrainTimeout  = 10
        }
    }
}
