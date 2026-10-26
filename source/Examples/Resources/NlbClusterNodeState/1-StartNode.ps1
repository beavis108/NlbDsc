<#
    .DESCRIPTION
        This example shows how to make sure the local node takes part in load
        balancing. A suspended node is resumed and started.
#>

configuration Example
{
    Import-DscResource -ModuleName 'NlbDsc'

    node localhost {

        NlbClusterNodeState Web01 {
            NodeName      = 'web01.contoso.com'
            InterfaceName = 'NLB'
            State         = 'Started'
        }
    }
}
