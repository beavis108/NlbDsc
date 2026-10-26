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
    NOTE: The module 'NetworkLoadBalancingClusters' must NOT be imported here.
    It only exists after the Windows features 'NLB' and 'RSAT-NLB' have been
    installed. It is imported on demand by Import-NlbModule after the features
    have been verified (or installed).
#>

$script:operationModeValues = @('Unicast', 'Multicast', 'IgmpMulticast')

<#
    .SYNOPSIS
        Returns the current state of the NLB cluster.

    .PARAMETER ClusterName
        Specifies the name of the NLB cluster.

    .PARAMETER InterfaceName
        Specifies the name of the network interface to which NLB is bound.

    .PARAMETER ClusterPrimaryIP
        Specifies the primary IP address of the NLB cluster.

    .PARAMETER SubnetMask
        Specifies the subnet mask of the primary IP address.

    .PARAMETER HostName
        Specifies the name of the cluster host. Defaults to the local node.
#>
function Get-TargetResource
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'ClusterPrimaryIP', Justification = 'Required parameter of the DSC schema. The current value is returned from the cluster.')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'SubnetMask', Justification = 'Required parameter of the DSC schema. The current value is returned from the cluster.')]
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ClusterName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InterfaceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ClusterPrimaryIP,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SubnetMask,

        [Parameter()]
        [System.String]
        $HostName
    )

    Write-Verbose -Message ($script:localizedData.GetCurrentState -f $ClusterName, $InterfaceName)

    $getTargetResourceResult = @{
        ClusterName           = $ClusterName
        InterfaceName         = $InterfaceName
        ClusterPrimaryIP      = $null
        SubnetMask            = $null
        HostName              = $HostName
        OperationMode         = $null
        DedicatedIP           = $null
        DedicatedIPSubnetMask = $null
        OverrideDhcp          = $null
        Ensure                = 'Absent'
        FeatureInstalled      = $false
        Nodes                 = [System.String[]] @()
        ClusterMacAddress     = $null
    }

    if (-not (Test-NlbFeatureInstalled))
    {
        Write-Verbose -Message ($script:localizedData.FeatureNotInstalled -f $ClusterName)

        return $getTargetResourceResult
    }

    $getTargetResourceResult.FeatureInstalled = $true

    Import-NlbModule

    $nlbCluster = Get-NlbDscCluster -InterfaceName $InterfaceName -HostName $HostName

    if ($null -ne $nlbCluster)
    {
        $operationMode = ConvertTo-NlbDscValue -Value $nlbCluster.Mode -AllowedValues $script:operationModeValues

        Write-Verbose -Message (
            $script:localizedData.ClusterFound -f $nlbCluster.Name, $nlbCluster.IPAddress, $nlbCluster.SubnetMask, $operationMode
        )

        $getTargetResourceResult.ClusterName = [System.String] $nlbCluster.Name
        $getTargetResourceResult.ClusterPrimaryIP = [System.String] $nlbCluster.IPAddress
        $getTargetResourceResult.SubnetMask = [System.String] $nlbCluster.SubnetMask
        $getTargetResourceResult.OperationMode = $operationMode
        $getTargetResourceResult.Ensure = 'Present'
        $getTargetResourceResult.Nodes = [System.String[]] @(
            $nlbCluster | Get-NlbClusterNode -ErrorAction 'SilentlyContinue' | ForEach-Object -Process { [System.String] $_.Name }
        )

        # The driver information is only available for the local node.
        if ([System.String]::IsNullOrWhiteSpace($HostName) -or (Get-NlbShortName -Name $HostName) -eq (Get-NlbShortName -Name (Get-ComputerName)))
        {
            $driverInfo = Get-NlbClusterDriverInfo -InterfaceName $InterfaceName -ErrorAction 'SilentlyContinue' | Select-Object -First 1

            $getTargetResourceResult.ClusterMacAddress = [System.String] (Get-NlbObjectPropertyValue -InputObject $driverInfo -Name 'ClusterMacAddress')
        }
    }

    return $getTargetResourceResult
}

<#
    .SYNOPSIS
        Creates, changes or removes the NLB cluster.

    .PARAMETER ClusterName
        Specifies the name of the NLB cluster.

    .PARAMETER InterfaceName
        Specifies the name of the network interface to which NLB is bound.

    .PARAMETER ClusterPrimaryIP
        Specifies the primary IP address of the NLB cluster.

    .PARAMETER SubnetMask
        Specifies the subnet mask of the primary IP address.

    .PARAMETER HostName
        Specifies the name of the cluster host. Defaults to the local node.

    .PARAMETER OperationMode
        Specifies the operation mode of the NLB cluster. Defaults to 'Unicast'.

    .PARAMETER DedicatedIP
        Specifies the dedicated IP address of the first node (only on creation).

    .PARAMETER DedicatedIPSubnetMask
        Specifies the subnet mask of the dedicated IP address (only on creation).

    .PARAMETER OverrideDhcp
        Specifies if the cluster may be created on an interface that uses DHCP.

    .PARAMETER Ensure
        Specifies if the NLB cluster should be present or absent. Defaults to 'Present'.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ClusterName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InterfaceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ClusterPrimaryIP,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SubnetMask,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [ValidateSet('Unicast', 'Multicast', 'IgmpMulticast')]
        [System.String]
        $OperationMode = 'Unicast',

        [Parameter()]
        [System.String]
        $DedicatedIP,

        [Parameter()]
        [System.String]
        $DedicatedIPSubnetMask,

        [Parameter()]
        [System.Boolean]
        $OverrideDhcp = $false,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    Write-Verbose -Message ($script:localizedData.SetDesiredState -f $ClusterName)

    $hostParameters = @{}

    if (-not [System.String]::IsNullOrWhiteSpace($HostName))
    {
        $hostParameters['HostName'] = $HostName
    }

    if ($Ensure -eq 'Absent')
    {
        if (-not (Test-NlbFeatureInstalled))
        {
            return
        }

        Import-NlbModule

        $nlbCluster = Get-NlbDscCluster -InterfaceName $InterfaceName -HostName $HostName

        if ($null -ne $nlbCluster)
        {
            Write-Verbose -Message ($script:localizedData.RemovingCluster -f $nlbCluster.Name, $InterfaceName)

            try
            {
                $nlbCluster | Remove-NlbCluster -Force -ErrorAction 'Stop'
            }
            catch
            {
                New-InvalidOperationException -Message ($script:localizedData.RemoveClusterFailed -f $ClusterName) -ErrorRecord $_
            }
        }

        return
    }

    # Make sure the NLB feature exists before any NLB cmdlet is used (fix for the former xNLB bug).
    if (-not (Test-NlbFeatureInstalled))
    {
        $restartRequired = Install-NlbFeature

        if ($restartRequired)
        {
            Write-Verbose -Message ($script:localizedData.RestartRequiredAfterFeatureInstall -f $ClusterName)

            return
        }
    }

    Import-NlbModule

    $nlbCluster = Get-NlbDscCluster -InterfaceName $InterfaceName -HostName $HostName

    if ($null -eq $nlbCluster)
    {
        Assert-NlbNetworkInterface -InterfaceName $InterfaceName -HostName $HostName -OverrideDhcp $OverrideDhcp

        Write-Verbose -Message (
            $script:localizedData.CreatingCluster -f $ClusterName, $ClusterPrimaryIP, $InterfaceName, $OperationMode
        )

        $newNlbClusterParameters = @{
            InterfaceName    = $InterfaceName
            ClusterName      = $ClusterName
            ClusterPrimaryIP = $ClusterPrimaryIP
            SubnetMask       = $SubnetMask
            OperationMode    = $OperationMode
            ErrorAction      = 'Stop'
        } + $hostParameters

        if (-not [System.String]::IsNullOrWhiteSpace($DedicatedIP))
        {
            $newNlbClusterParameters['DedicatedIP'] = $DedicatedIP
        }

        if (-not [System.String]::IsNullOrWhiteSpace($DedicatedIPSubnetMask))
        {
            $newNlbClusterParameters['DedicatedIPSubnetMask'] = $DedicatedIPSubnetMask
        }

        if ($OverrideDhcp)
        {
            $newNlbClusterParameters['Force'] = $true
        }

        try
        {
            $null = New-NlbCluster @newNlbClusterParameters
        }
        catch
        {
            New-InvalidOperationException -Message ($script:localizedData.CreateClusterFailed -f $ClusterName) -ErrorRecord $_
        }

        return
    }

    # Primary IP address and subnet mask.
    $currentPrimaryIP = [System.String] $nlbCluster.IPAddress
    $currentSubnetMask = [System.String] $nlbCluster.SubnetMask

    if (Test-NlbIPAddressEqual -ReferenceIPAddress $currentPrimaryIP -DifferenceIPAddress $ClusterPrimaryIP)
    {
        if ($currentSubnetMask -ne $SubnetMask)
        {
            New-InvalidOperationException -Message (
                $script:localizedData.SubnetMaskMismatch -f $ClusterPrimaryIP, $currentSubnetMask, $SubnetMask
            )
        }
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.MovingPrimaryIP -f $nlbCluster.Name, $currentPrimaryIP, $ClusterPrimaryIP)

        try
        {
            $existingVip = $nlbCluster | Get-NlbClusterVip -ErrorAction 'Stop' | Where-Object -FilterScript {
                Test-NlbIPAddressEqual -ReferenceIPAddress $_.IPAddress -DifferenceIPAddress $ClusterPrimaryIP
            } | Select-Object -First 1

            if ($null -ne $existingVip)
            {
                if ([System.String] $existingVip.SubnetMask -ne $SubnetMask)
                {
                    New-InvalidOperationException -Message (
                        $script:localizedData.SubnetMaskMismatch -f $ClusterPrimaryIP, $existingVip.SubnetMask, $SubnetMask
                    )
                }

                $null = $nlbCluster | Set-NlbCluster -ClusterPrimaryIP $ClusterPrimaryIP -ErrorAction 'Stop'
            }
            elseif ($currentSubnetMask -eq $SubnetMask)
            {
                # Replace the current primary virtual IP address in place.
                $null = $nlbCluster | Get-NlbClusterVip -IP $currentPrimaryIP -ErrorAction 'Stop' |
                    Set-NlbClusterVip -NewIP $ClusterPrimaryIP -ErrorAction 'Stop'
            }
            else
            {
                $null = $nlbCluster | Add-NlbClusterVip -IP $ClusterPrimaryIP -SubnetMask $SubnetMask -ErrorAction 'Stop'
                $null = $nlbCluster | Set-NlbCluster -ClusterPrimaryIP $ClusterPrimaryIP -ErrorAction 'Stop'
                $nlbCluster | Get-NlbClusterVip -IP $currentPrimaryIP -ErrorAction 'Stop' |
                    Remove-NlbClusterVip -Force -ErrorAction 'Stop'
            }
        }
        catch
        {
            New-InvalidOperationException -Message ($script:localizedData.ChangePrimaryIPFailed -f $ClusterName, $ClusterPrimaryIP) -ErrorRecord $_
        }

        $nlbCluster = Get-NlbDscCluster -InterfaceName $InterfaceName -HostName $HostName
    }

    # Cluster name and operation mode.
    $setNlbClusterParameters = @{}

    if ([System.String] $nlbCluster.Name -ne $ClusterName)
    {
        $setNlbClusterParameters['Name'] = $ClusterName
    }

    if ((ConvertTo-NlbDscValue -Value $nlbCluster.Mode -AllowedValues $script:operationModeValues) -ne $OperationMode)
    {
        $setNlbClusterParameters['OperationMode'] = $OperationMode
    }

    if ($setNlbClusterParameters.Count -gt 0)
    {
        Write-Verbose -Message (
            $script:localizedData.ChangingCluster -f $nlbCluster.Name, $ClusterName, $OperationMode
        )

        try
        {
            $null = $nlbCluster | Set-NlbCluster @setNlbClusterParameters -ErrorAction 'Stop'
        }
        catch
        {
            New-InvalidOperationException -Message ($script:localizedData.ChangeClusterFailed -f $ClusterName) -ErrorRecord $_
        }
    }
}

<#
    .SYNOPSIS
        Tests whether the NLB cluster is in the desired state.

    .PARAMETER ClusterName
        Specifies the name of the NLB cluster.

    .PARAMETER InterfaceName
        Specifies the name of the network interface to which NLB is bound.

    .PARAMETER ClusterPrimaryIP
        Specifies the primary IP address of the NLB cluster.

    .PARAMETER SubnetMask
        Specifies the subnet mask of the primary IP address.

    .PARAMETER HostName
        Specifies the name of the cluster host. Defaults to the local node.

    .PARAMETER OperationMode
        Specifies the operation mode of the NLB cluster. Defaults to 'Unicast'.

    .PARAMETER DedicatedIP
        Specifies the dedicated IP address of the first node (only on creation).

    .PARAMETER DedicatedIPSubnetMask
        Specifies the subnet mask of the dedicated IP address (only on creation).

    .PARAMETER OverrideDhcp
        Specifies if the cluster may be created on an interface that uses DHCP.

    .PARAMETER Ensure
        Specifies if the NLB cluster should be present or absent. Defaults to 'Present'.
#>
function Test-TargetResource
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'DedicatedIP', Justification = 'Only used when the cluster is created.')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'DedicatedIPSubnetMask', Justification = 'Only used when the cluster is created.')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'OverrideDhcp', Justification = 'Only used when the cluster is created.')]
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ClusterName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InterfaceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ClusterPrimaryIP,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SubnetMask,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [ValidateSet('Unicast', 'Multicast', 'IgmpMulticast')]
        [System.String]
        $OperationMode = 'Unicast',

        [Parameter()]
        [System.String]
        $DedicatedIP,

        [Parameter()]
        [System.String]
        $DedicatedIPSubnetMask,

        [Parameter()]
        [System.Boolean]
        $OverrideDhcp = $false,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    Write-Verbose -Message ($script:localizedData.TestDesiredState -f $ClusterName)

    $getTargetResourceParameters = @{
        ClusterName      = $ClusterName
        InterfaceName    = $InterfaceName
        ClusterPrimaryIP = $ClusterPrimaryIP
        SubnetMask       = $SubnetMask
        HostName         = $HostName
    }

    $currentState = Get-TargetResource @getTargetResourceParameters

    $inDesiredState = $true

    if ($currentState.Ensure -ne $Ensure)
    {
        Write-Verbose -Message ($script:localizedData.EnsureMismatch -f $ClusterName, $Ensure, $currentState.Ensure)

        $inDesiredState = $false
    }
    elseif ($Ensure -eq 'Present')
    {
        $desiredState = @{
            ClusterName      = $ClusterName
            ClusterPrimaryIP = $ClusterPrimaryIP
            SubnetMask       = $SubnetMask
            OperationMode    = $OperationMode
        }

        $inDesiredState = Test-DscParameterState `
            -CurrentValues $currentState `
            -DesiredValues $desiredState `
            -Properties @('ClusterName', 'ClusterPrimaryIP', 'SubnetMask', 'OperationMode') `
            -TurnOffTypeChecking `
            -Verbose:$VerbosePreference
    }

    if ($inDesiredState)
    {
        Write-Verbose -Message ($script:localizedData.InDesiredState -f $ClusterName)
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.NotInDesiredState -f $ClusterName)
    }

    return $inDesiredState
}

<#
    .SYNOPSIS
        Verifies with Get-NlbClusterNodeNetworkInterface that the interface
        exists and does not use DHCP (unless OverrideDhcp is set).

    .PARAMETER InterfaceName
        The name of the network interface.

    .PARAMETER HostName
        The name of the cluster host. Defaults to the local node.

    .PARAMETER OverrideDhcp
        Allow an interface that uses DHCP.
#>
function Assert-NlbNetworkInterface
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InterfaceName,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $OverrideDhcp
    )

    $getInterfaceParameters = @{
        ErrorAction = 'Stop'
    }

    if (-not [System.String]::IsNullOrWhiteSpace($HostName))
    {
        $getInterfaceParameters['HostName'] = $HostName
    }

    try
    {
        $networkInterfaces = @(Get-NlbClusterNodeNetworkInterface @getInterfaceParameters)
    }
    catch
    {
        # Not fatal - New-NlbCluster reports a precise error if the interface is not usable.
        Write-Verbose -Message ($script:localizedData.InterfaceCheckFailed -f $InterfaceName, $_.Exception.Message)

        return
    }

    $networkInterface = $networkInterfaces | Where-Object -FilterScript {
        [System.String] $_.InterfaceName -eq $InterfaceName
    } | Select-Object -First 1

    if ($null -eq $networkInterface)
    {
        New-ObjectNotFoundException -Message ($script:localizedData.InterfaceNotFound -f $InterfaceName, $HostName)
    }

    if ($networkInterface.DhcpEnabled -and -not $OverrideDhcp)
    {
        New-InvalidOperationException -Message ($script:localizedData.InterfaceUsesDhcp -f $InterfaceName)
    }
}

Export-ModuleMember -Function *-TargetResource
