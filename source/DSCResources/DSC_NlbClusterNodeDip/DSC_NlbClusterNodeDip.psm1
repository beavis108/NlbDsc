$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the Common Modules
Import-Module -Name (Join-Path -Path $modulePath -ChildPath 'NlbDsc.Common')
Import-Module -Name (Join-Path -Path $modulePath -ChildPath 'DscResource.Common')

if (-not (Test-NlbDscOsRequirement))
{
    throw 'The minimum OS requirement was not met.'
}

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    NOTE: The module 'NetworkLoadBalancingClusters' must NOT be imported here,
    see Import-NlbModule in NlbDsc.Common.
#>

<#
    .SYNOPSIS
        Returns the cluster node object, or $null.

    .PARAMETER InterfaceName
        The name of the network interface to which NLB is bound.

    .PARAMETER NodeName
        The name of the node. Defaults to the local node.

    .PARAMETER HostName
        The name of a cluster host used to manage the cluster.
#>
function Get-NlbDscDipNode
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InterfaceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $NodeName,

        [Parameter()]
        [System.String]
        $HostName
    )

    if (-not (Test-NlbFeatureInstalled))
    {
        Write-Verbose -Message $script:localizedData.FeatureNotInstalled

        return $null
    }

    Import-NlbModule

    $nlbCluster = Get-NlbDscCluster -InterfaceName $InterfaceName -HostName $HostName

    if ($null -eq $nlbCluster)
    {
        Write-Verbose -Message ($script:localizedData.ClusterNotFound -f $InterfaceName)

        return $null
    }

    $nlbClusterNode = Find-NlbClusterNode -Cluster $nlbCluster -NodeName $NodeName

    if ($null -eq $nlbClusterNode)
    {
        Write-Verbose -Message ($script:localizedData.NodeNotFound -f $NodeName)
    }

    return $nlbClusterNode
}

<#
    .SYNOPSIS
        Returns the dedicated IP address object of the node, or $null.

    .PARAMETER Node
        The node object.

    .PARAMETER IPAddress
        The dedicated IP address.
#>
function Find-NlbNodeDip
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $Node,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IPAddress
    )

    return $Node | Get-NlbClusterNodeDip -ErrorAction 'Stop' | Where-Object -FilterScript {
        Test-NlbIPAddressEqual -ReferenceIPAddress $_.IPAddress -DifferenceIPAddress $IPAddress
    } | Select-Object -First 1
}

<#
    .SYNOPSIS
        Returns the current state of the dedicated IP address.

    .PARAMETER InterfaceName
        Specifies the name of the network interface to which NLB is bound.

    .PARAMETER IPAddress
        Specifies the dedicated IP address.

    .PARAMETER NodeName
        Specifies the name of the node. Defaults to the local node.

    .PARAMETER HostName
        Specifies the name of a cluster host used to manage the cluster.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InterfaceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IPAddress,

        [Parameter()]
        [System.String]
        $NodeName,

        [Parameter()]
        [System.String]
        $HostName
    )

    if ([System.String]::IsNullOrWhiteSpace($NodeName))
    {
        $NodeName = Get-ComputerName
    }

    Write-Verbose -Message ($script:localizedData.GetCurrentState -f $IPAddress, $NodeName)

    $getTargetResourceResult = @{
        InterfaceName = $InterfaceName
        IPAddress     = $IPAddress
        NodeName      = $NodeName
        SubnetMask    = $null
        HostName      = $HostName
        Ensure        = 'Absent'
    }

    $nlbClusterNode = Get-NlbDscDipNode -InterfaceName $InterfaceName -NodeName $NodeName -HostName $HostName

    if ($null -eq $nlbClusterNode)
    {
        return $getTargetResourceResult
    }

    $dip = Find-NlbNodeDip -Node $nlbClusterNode -IPAddress $IPAddress

    if ($null -eq $dip)
    {
        Write-Verbose -Message ($script:localizedData.DipNotFound -f $IPAddress, $NodeName)
    }
    else
    {
        $getTargetResourceResult.SubnetMask = [System.String] $dip.SubnetMask
        $getTargetResourceResult.Ensure = 'Present'

        Write-Verbose -Message ($script:localizedData.DipFound -f $IPAddress, $dip.SubnetMask, $NodeName)
    }

    return $getTargetResourceResult
}

<#
    .SYNOPSIS
        Adds or removes the dedicated IP address.

    .PARAMETER InterfaceName
        Specifies the name of the network interface to which NLB is bound.

    .PARAMETER IPAddress
        Specifies the dedicated IP address.

    .PARAMETER NodeName
        Specifies the name of the node. Defaults to the local node.

    .PARAMETER SubnetMask
        Specifies the subnet mask of the dedicated IP address.

    .PARAMETER HostName
        Specifies the name of a cluster host used to manage the cluster.

    .PARAMETER Ensure
        Specifies if the dedicated IP address should be present or absent.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InterfaceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IPAddress,

        [Parameter()]
        [System.String]
        $NodeName,

        [Parameter()]
        [System.String]
        $SubnetMask,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    if ([System.String]::IsNullOrWhiteSpace($NodeName))
    {
        $NodeName = Get-ComputerName
    }

    $nlbClusterNode = Get-NlbDscDipNode -InterfaceName $InterfaceName -NodeName $NodeName -HostName $HostName

    if ($null -eq $nlbClusterNode)
    {
        if ($Ensure -eq 'Absent')
        {
            return
        }

        New-InvalidOperationException -Message ($script:localizedData.NodeRequired -f $NodeName, $InterfaceName)
    }

    $dip = Find-NlbNodeDip -Node $nlbClusterNode -IPAddress $IPAddress

    $removeDip = $false
    $addDip = $false

    if ($Ensure -eq 'Absent')
    {
        $removeDip = $null -ne $dip
    }
    elseif ($null -eq $dip)
    {
        $addDip = $true
    }
    elseif (-not [System.String]::IsNullOrWhiteSpace($SubnetMask) -and [System.String] $dip.SubnetMask -ne $SubnetMask)
    {
        $removeDip = $true
        $addDip = $true
    }

    try
    {
        if ($removeDip)
        {
            Write-Verbose -Message ($script:localizedData.RemovingDip -f $IPAddress, $NodeName)

            $dip | Remove-NlbClusterNodeDip -Force -ErrorAction 'Stop'
        }

        if ($addDip)
        {
            Write-Verbose -Message ($script:localizedData.AddingDip -f $IPAddress, $SubnetMask, $NodeName)

            $addDipParameters = @{
                IP          = $IPAddress
                ErrorAction = 'Stop'
            }

            if (-not [System.String]::IsNullOrWhiteSpace($SubnetMask))
            {
                $addDipParameters['SubnetMask'] = $SubnetMask
            }

            $null = $nlbClusterNode | Add-NlbClusterNodeDip @addDipParameters
        }
    }
    catch
    {
        New-InvalidOperationException -Message ($script:localizedData.ChangeDipFailed -f $IPAddress, $NodeName) -ErrorRecord $_
    }
}

<#
    .SYNOPSIS
        Tests whether the dedicated IP address is in the desired state.

    .PARAMETER InterfaceName
        Specifies the name of the network interface to which NLB is bound.

    .PARAMETER IPAddress
        Specifies the dedicated IP address.

    .PARAMETER NodeName
        Specifies the name of the node. Defaults to the local node.

    .PARAMETER SubnetMask
        Specifies the subnet mask of the dedicated IP address.

    .PARAMETER HostName
        Specifies the name of a cluster host used to manage the cluster.

    .PARAMETER Ensure
        Specifies if the dedicated IP address should be present or absent.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InterfaceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IPAddress,

        [Parameter()]
        [System.String]
        $NodeName,

        [Parameter()]
        [System.String]
        $SubnetMask,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    Write-Verbose -Message ($script:localizedData.TestDesiredState -f $IPAddress)

    $currentState = Get-TargetResource -InterfaceName $InterfaceName -IPAddress $IPAddress -NodeName $NodeName -HostName $HostName

    $inDesiredState = $true

    if ($currentState.Ensure -ne $Ensure)
    {
        Write-Verbose -Message ($script:localizedData.EnsureMismatch -f $IPAddress, $Ensure, $currentState.Ensure)

        $inDesiredState = $false
    }
    elseif ($Ensure -eq 'Present' -and -not [System.String]::IsNullOrWhiteSpace($SubnetMask))
    {
        $desiredValues = @{
            SubnetMask = $SubnetMask
        }

        $inDesiredState = Test-DscParameterState `
            -CurrentValues $currentState `
            -DesiredValues $desiredValues `
            -Properties 'SubnetMask' `
            -TurnOffTypeChecking `
            -Verbose:$VerbosePreference
    }

    if ($inDesiredState)
    {
        Write-Verbose -Message ($script:localizedData.InDesiredState -f $IPAddress)
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.NotInDesiredState -f $IPAddress)
    }

    return $inDesiredState
}

Export-ModuleMember -Function *-TargetResource
