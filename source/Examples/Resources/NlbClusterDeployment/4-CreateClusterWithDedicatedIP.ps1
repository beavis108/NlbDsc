<#
    .DESCRIPTION
        This example shows how to create an NLB cluster in IGMP multicast mode
        with an explicit dedicated IP address for the first node. The interface
        uses DHCP, so OverrideDhcp allows NLB to replace the DHCP setting.
#>

configuration Example
{
    Import-DscResource -ModuleName 'NlbDsc'

    node localhost {

        NlbClusterDeployment AppCluster {
            ClusterName           = 'app.contoso.com'
            InterfaceName         = 'NLB'
            ClusterPrimaryIP      = '192.168.20.100'
            SubnetMask            = '255.255.255.0'
            OperationMode         = 'IgmpMulticast'
            DedicatedIP           = '192.168.20.11'
            DedicatedIPSubnetMask = '255.255.255.0'
            OverrideDhcp          = $true
        }
    }
}
