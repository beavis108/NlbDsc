<#
    .DESCRIPTION
        This example shows how to take a node out of load balancing for
        maintenance. Existing connections are drained for at most 300 seconds
        before the node is stopped.
#>

configuration Example
{
    Import-DscResource -ModuleName 'NlbDsc'

    node localhost {

        NlbClusterNodeState Web02Maintenance {
            NodeName      = 'web02.contoso.com'
            InterfaceName = 'NLB'
            State         = 'Stopped'
            Drain         = $true
            DrainTimeout  = 300
        }
    }
}
