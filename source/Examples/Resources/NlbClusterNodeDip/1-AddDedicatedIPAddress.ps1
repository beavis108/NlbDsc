<#
    .DESCRIPTION
        This example shows how to add a dedicated IP address to the local
        cluster node.
#>

configuration Example
{
    Import-DscResource -ModuleName 'NlbDsc'

    node localhost {

        NlbClusterNodeDip ManagementAddress {
            InterfaceName = 'NLB'
            IPAddress     = '192.168.10.21'
            SubnetMask    = '255.255.255.0'
        }
    }
}
