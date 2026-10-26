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
        Returns the current state of the virtual IP address.

    .PARAMETER InterfaceName
        Specifies the name of the network interface to which NLB is bound.

    .PARAMETER IPAddress
        Specifies the virtual IP address.

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
        $HostName
    )

    Write-Verbose -Message ($script:localizedData.GetCurrentState -f $IPAddress, $InterfaceName)

    $getTargetResourceResult = @{
        InterfaceName = $InterfaceName
        IPAddress     = $IPAddress
        SubnetMask    = $null
        HostName      = $HostName
        Ensure        = 'Absent'
        IsPrimary     = $false
    }

    if (-not (Test-NlbFeatureInstalled))
    {
        Write-Verbose -Message $script:localizedData.FeatureNotInstalled

        return $getTargetResourceResult
    }

    Import-NlbModule

    $nlbCluster = Get-NlbDscCluster -InterfaceName $InterfaceName -HostName $HostName

    if ($null -eq $nlbCluster)
    {
        Write-Verbose -Message ($script:localizedData.ClusterNotFound -f $InterfaceName)

        return $getTargetResourceResult
    }

    $vip = Find-NlbVip -Cluster $nlbCluster -IPAddress $IPAddress

    if ($null -eq $vip)
    {
        Write-Verbose -Message ($script:localizedData.VipNotFound -f $IPAddress)
    }
    else
    {
        $getTargetResourceResult.SubnetMask = [System.String] $vip.SubnetMask
        $getTargetResourceResult.Ensure = 'Present'
        $getTargetResourceResult.IsPrimary = (Test-NlbIPAddressEqual -ReferenceIPAddress $nlbCluster.IPAddress -DifferenceIPAddress $vip.IPAddress)

        Write-Verbose -Message ($script:localizedData.VipFound -f $IPAddress, $vip.SubnetMask, $getTargetResourceResult.IsPrimary)
    }

    return $getTargetResourceResult
}

<#
    .SYNOPSIS
        Adds or removes the virtual IP address.

    .PARAMETER InterfaceName
        Specifies the name of the network interface to which NLB is bound.

    .PARAMETER IPAddress
        Specifies the virtual IP address.

    .PARAMETER SubnetMask
        Specifies the subnet mask of the virtual IP address.

    .PARAMETER HostName
        Specifies the name of a cluster host used to manage the cluster.

    .PARAMETER Ensure
        Specifies if the virtual IP address should be present or absent.
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
        $SubnetMask,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    $nlbCluster = $null

    if (Test-NlbFeatureInstalled)
    {
        Import-NlbModule

        $nlbCluster = Get-NlbDscCluster -InterfaceName $InterfaceName -HostName $HostName
    }

    if ($null -eq $nlbCluster)
    {
        if ($Ensure -eq 'Absent')
        {
            return
        }

        New-InvalidOperationException -Message ($script:localizedData.ClusterRequired -f $InterfaceName)
    }

    $vip = Find-NlbVip -Cluster $nlbCluster -IPAddress $IPAddress
    $isPrimary = $null -ne $vip -and (Test-NlbIPAddressEqual -ReferenceIPAddress $nlbCluster.IPAddress -DifferenceIPAddress $vip.IPAddress)

    $removeVip = $false
    $addVip = $false

    if ($Ensure -eq 'Absent')
    {
        $removeVip = $null -ne $vip
    }
    elseif ($null -eq $vip)
    {
        $addVip = $true
    }
    elseif (-not [System.String]::IsNullOrWhiteSpace($SubnetMask) -and [System.String] $vip.SubnetMask -ne $SubnetMask)
    {
        $removeVip = $true
        $addVip = $true
    }

    if ($removeVip -and $isPrimary)
    {
        New-InvalidOperationException -Message ($script:localizedData.PrimaryVipChange -f $IPAddress)
    }

    try
    {
        if ($removeVip)
        {
            Write-Verbose -Message ($script:localizedData.RemovingVip -f $IPAddress)

            $vip | Remove-NlbClusterVip -Force -ErrorAction 'Stop'
        }

        if ($addVip)
        {
            Write-Verbose -Message ($script:localizedData.AddingVip -f $IPAddress, $SubnetMask)

            $addVipParameters = @{
                IP          = $IPAddress
                ErrorAction = 'Stop'
            }

            if (-not [System.String]::IsNullOrWhiteSpace($SubnetMask))
            {
                $addVipParameters['SubnetMask'] = $SubnetMask
            }

            $null = $nlbCluster | Add-NlbClusterVip @addVipParameters
        }
    }
    catch
    {
        New-InvalidOperationException -Message ($script:localizedData.ChangeVipFailed -f $IPAddress) -ErrorRecord $_
    }
}

<#
    .SYNOPSIS
        Tests whether the virtual IP address is in the desired state.

    .PARAMETER InterfaceName
        Specifies the name of the network interface to which NLB is bound.

    .PARAMETER IPAddress
        Specifies the virtual IP address.

    .PARAMETER SubnetMask
        Specifies the subnet mask of the virtual IP address.

    .PARAMETER HostName
        Specifies the name of a cluster host used to manage the cluster.

    .PARAMETER Ensure
        Specifies if the virtual IP address should be present or absent.
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

    $currentState = Get-TargetResource -InterfaceName $InterfaceName -IPAddress $IPAddress -HostName $HostName

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

<#
    .SYNOPSIS
        Returns the virtual IP address object of the cluster, or $null.

    .PARAMETER Cluster
        The cluster object.

    .PARAMETER IPAddress
        The virtual IP address.
#>
function Find-NlbVip
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
        $IPAddress
    )

    return $Cluster | Get-NlbClusterVip -ErrorAction 'Stop' | Where-Object -FilterScript {
        Test-NlbIPAddressEqual -ReferenceIPAddress $_.IPAddress -DifferenceIPAddress $IPAddress
    } | Select-Object -First 1
}

Export-ModuleMember -Function *-TargetResource
