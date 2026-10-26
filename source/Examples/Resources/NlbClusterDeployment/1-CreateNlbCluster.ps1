<#
    .DESCRIPTION
        This example shows how to create a new NLB cluster in unicast mode on the
        local node. The Windows features NLB and RSAT-NLB are installed
        automatically when they are missing.
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
            OperationMode    = 'Unicast'
            Ensure           = 'Present'
        }
    }
}
