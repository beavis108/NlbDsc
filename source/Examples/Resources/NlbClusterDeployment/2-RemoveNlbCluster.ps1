<#
    .DESCRIPTION
        This example shows how to remove the NLB cluster that is bound to the
        interface 'NLB' of the local node.
#>

configuration Example
{
    Import-DscResource -ModuleName 'NlbDsc'

    node localhost {

        NlbClusterDeployment WebCluster {
            ClusterName      = 'web.contoso.com'
            InterfaceName    = 'NLB'
            ClusterPrimaryIP = '192.168.10.100'
            SubnetMask       = '255.255.255.0'
            Ensure           = 'Absent'
        }
    }
}
