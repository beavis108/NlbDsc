<#
    .SYNOPSIS
        Returns the cluster node object of a node, or $null.

    .DESCRIPTION
        Enumerates the nodes of the cluster with Get-NlbClusterNode and returns
        the node whose host name part matches the host name part of NodeName,
        so 'web02' and 'web02.contoso.com' are treated as the same node.

    .PARAMETER Cluster
        The cluster object returned by Get-NlbDscCluster.

    .PARAMETER NodeName
        The name of the node.

    .OUTPUTS
        Microsoft.NetworkLoadBalancingClusters.PowerShell.Node

    .EXAMPLE
        Find-NlbClusterNode -Cluster $cluster -NodeName 'web02.contoso.com'
#>
function Find-NlbClusterNode
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $Cluster,

        [Parameter(Mandatory = $true)]
        [System.String]
        $NodeName
    )

    $shortNodeName = Get-NlbShortName -Name $NodeName

    return $Cluster | Get-NlbClusterNode -ErrorAction 'Stop' | Where-Object -FilterScript {
        (Get-NlbShortName -Name ([System.String] $_.Name)) -eq $shortNodeName
    } | Select-Object -First 1
}
