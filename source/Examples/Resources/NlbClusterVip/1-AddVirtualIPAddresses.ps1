<#
    .DESCRIPTION
        This example shows how to add an additional IPv4 and an IPv6 virtual
        IP address to the NLB cluster and how to remove an old one.
#>

configuration Example
{
    Import-DscResource -ModuleName 'NlbDsc'

    node localhost {

        NlbClusterVip ApiIPv4 {
            InterfaceName = 'NLB'
            IPAddress     = '192.168.10.101'
            SubnetMask    = '255.255.255.0'
        }

        NlbClusterVip ApiIPv6 {
            InterfaceName = 'NLB'
            IPAddress     = '2001:db8:10::101'
        }

        NlbClusterVip OldAddress {
            InterfaceName = 'NLB'
            IPAddress     = '192.168.10.150'
            Ensure        = 'Absent'
        }
    }
}
