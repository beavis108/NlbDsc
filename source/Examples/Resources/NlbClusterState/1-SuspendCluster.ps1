<#
    .DESCRIPTION
        This example shows how to suspend all nodes of the NLB cluster, for
        example during a maintenance window.
#>

configuration Example
{
    Import-DscResource -ModuleName 'NlbDsc'

    node localhost {

        NlbClusterState Maintenance {
            InterfaceName = 'NLB'
            State         = 'Suspended'
        }
    }
}
