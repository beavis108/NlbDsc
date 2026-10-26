<#
    .DESCRIPTION
        This example shows how to change the default port rule that NLB creates
        together with a new cluster (all cluster IP addresses, ports 0 - 65535)
        to TCP only without client affinity.
#>

configuration Example
{
    Import-DscResource -ModuleName 'NlbDsc'

    node localhost {

        NlbClusterPortRule DefaultPortRule {
            InterfaceName = 'NLB'
            IPAddress     = 'All'
            StartPort     = 0
            EndPort       = 65535
            Protocol      = 'Tcp'
            Mode          = 'Multiple'
            Affinity      = 'None'
        }
    }
}
