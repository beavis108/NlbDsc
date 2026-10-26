<#
    .DESCRIPTION
        This example shows a complete two node NLB cluster for a web farm.
        The first node creates the cluster and configures the port rules, the
        second node waits for the cluster and joins it. The default port rule
        (0 - 65535) is changed to TCP 80 - 443 without client affinity.
#>

[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'The configuration data is passed to the configuration with -ConfigurationData.')]
param ()

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName         = '*'
            ClusterName      = 'web.contoso.com'
            ClusterPrimaryIP = '192.168.10.100'
            SubnetMask       = '255.255.255.0'
            InterfaceName    = 'NLB'
            FirstNodeName    = 'web01.contoso.com'
        },
        @{
            NodeName = 'web01.contoso.com'
            Role     = 'FirstNode'
        },
        @{
            NodeName = 'web02.contoso.com'
            Role     = 'AdditionalNode'
        }
    )
}

configuration Example
{
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'NlbDsc'

    node $AllNodes.Where{ $_.Role -eq 'FirstNode' }.NodeName {

        NlbClusterDeployment WebCluster {
            ClusterName      = $Node.ClusterName
            InterfaceName    = $Node.InterfaceName
            ClusterPrimaryIP = $Node.ClusterPrimaryIP
            SubnetMask       = $Node.SubnetMask
            OperationMode    = 'Multicast'
        }

        NlbClusterPortRule Web {
            InterfaceName = $Node.InterfaceName
            IPAddress     = 'All'
            StartPort     = 80
            EndPort       = 443
            Protocol      = 'Tcp'
            Mode          = 'Multiple'
            Affinity      = 'None'
            DependsOn     = '[NlbClusterDeployment]WebCluster'
        }
    }

    node $AllNodes.Where{ $_.Role -eq 'AdditionalNode' }.NodeName {

        WaitForAll WebCluster {
            ResourceName     = '[NlbClusterDeployment]WebCluster'
            NodeName         = $Node.FirstNodeName
            RetryIntervalSec = 30
            RetryCount       = 40
        }

        NlbClusterNode JoinWebCluster {
            NodeName          = $Node.NodeName
            NodeInterfaceName = $Node.InterfaceName
            HostName          = $Node.FirstNodeName
            InterfaceName     = $Node.InterfaceName
            DependsOn         = '[WaitForAll]WebCluster'
        }
    }
}
