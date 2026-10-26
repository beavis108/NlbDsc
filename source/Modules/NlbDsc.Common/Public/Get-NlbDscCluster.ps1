<#
    .SYNOPSIS
        Returns the NLB cluster that is bound to an interface, or $null.

    .DESCRIPTION
        Wraps Get-NlbCluster so the DSC resources can query a cluster without
        having to handle the different failure modes of the cmdlet (no cluster
        bound to the interface, NLB not bound at all, host not reachable).
        The function returns $null in all of these cases and writes the reason
        to the verbose stream.

        Import-NlbModule must have been called before this function is used.

    .PARAMETER InterfaceName
        The name of the network interface the cluster is bound to.

    .PARAMETER HostName
        The name of the cluster host to query. If not specified, the local
        node is queried.

    .OUTPUTS
        Microsoft.NetworkLoadBalancingClusters.PowerShell.Cluster

    .EXAMPLE
        Get-NlbDscCluster -InterfaceName 'Ethernet'

        Returns the cluster bound to the interface 'Ethernet' on the local node.
#>
function Get-NlbDscCluster
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InterfaceName,

        [Parameter()]
        [System.String]
        $HostName
    )

    $getNlbClusterParameters = @{
        InterfaceName = $InterfaceName
        ErrorAction   = 'Stop'
    }

    if (-not [System.String]::IsNullOrWhiteSpace($HostName))
    {
        $getNlbClusterParameters['HostName'] = $HostName
    }

    try
    {
        $nlbCluster = Get-NlbCluster @getNlbClusterParameters | Select-Object -First 1
    }
    catch
    {
        Write-Verbose -Message ($script:localizedData.ClusterQueryFailed -f $InterfaceName, $HostName, $_.Exception.Message)

        $nlbCluster = $null
    }

    if ($null -eq $nlbCluster)
    {
        Write-Verbose -Message ($script:localizedData.ClusterNotFound -f $InterfaceName, $HostName)
    }

    return $nlbCluster
}
