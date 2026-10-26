<#
    .DESCRIPTION
        This example shows how to make sure all nodes of the NLB cluster are
        started. Suspended nodes are resumed first.
#>

configuration Example
{
    Import-DscResource -ModuleName 'NlbDsc'

    node localhost {

        NlbClusterState Running {
            InterfaceName = 'NLB'
            State         = 'Started'
        }
    }
}
