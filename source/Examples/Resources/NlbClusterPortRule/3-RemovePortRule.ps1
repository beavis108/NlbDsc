<#
    .DESCRIPTION
        This example shows how to remove the port rule that covers port 8080
        for the cluster IP address 192.168.10.100.
#>

configuration Example
{
    Import-DscResource -ModuleName 'NlbDsc'

    node localhost {

        NlbClusterPortRule RemoveAlternativeHttp {
            InterfaceName = 'NLB'
            IPAddress     = '192.168.10.100'
            StartPort     = 8080
            EndPort       = 8080
            Ensure        = 'Absent'
        }
    }
}
