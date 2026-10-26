<#
    .DESCRIPTION
        This example shows how to create a cluster and to add two port rules
        for HTTP and HTTPS that only apply to the cluster IP address
        192.168.10.100. HTTPS uses single affinity with a timeout of 30 minutes.
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
        }

        NlbClusterPortRule Http {
            InterfaceName = 'NLB'
            IPAddress     = '192.168.10.100'
            StartPort     = 80
            EndPort       = 80
            Protocol      = 'Tcp'
            Mode          = 'Multiple'
            Affinity      = 'None'
            DependsOn     = '[NlbClusterDeployment]WebCluster'
        }

        NlbClusterPortRule Https {
            InterfaceName = 'NLB'
            IPAddress     = '192.168.10.100'
            StartPort     = 443
            EndPort       = 443
            Protocol      = 'Tcp'
            Mode          = 'Multiple'
            Affinity      = 'Single'
            Timeout       = 30
            DependsOn     = '[NlbClusterDeployment]WebCluster'
        }
    }
}
