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
        Returns the node specific port rule object, or $null.

    .PARAMETER NodeName
        The name of the node.

    .PARAMETER InterfaceName
        The name of the network interface to which NLB is bound.

    .PARAMETER IPAddress
        The cluster IP address of the port rule.

    .PARAMETER StartPort
        A port within the port range of the port rule.

    .PARAMETER HostName
        The name of a cluster host used to manage the cluster.
#>
function Get-NlbDscNodePortRule
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $NodeName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InterfaceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IPAddress,

        [Parameter(Mandatory = $true)]
        [System.UInt16]
        $StartPort,

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

        return $null
    }

    $portRule = Find-NlbClusterPortRule -InputObject $nlbClusterNode -IPAddress $IPAddress -StartPort $StartPort

    if ($null -eq $portRule)
    {
        Write-Verbose -Message ($script:localizedData.PortRuleNotFound -f $IPAddress, $StartPort)
    }

    return $portRule
}

<#
    .SYNOPSIS
        Returns the node specific settings of the port rule.

    .PARAMETER NodeName
        Specifies the name of the node.

    .PARAMETER InterfaceName
        Specifies the name of the network interface to which NLB is bound.

    .PARAMETER IPAddress
        Specifies the cluster IP address of the port rule, or 'All'.

    .PARAMETER StartPort
        Specifies a port within the port range of the port rule.

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
        $NodeName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InterfaceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IPAddress,

        [Parameter(Mandatory = $true)]
        [System.UInt16]
        $StartPort,

        [Parameter()]
        [System.String]
        $HostName
    )

    Write-Verbose -Message ($script:localizedData.GetCurrentState -f $IPAddress, $StartPort, $NodeName)

    $getTargetResourceResult = @{
        NodeName         = $NodeName
        InterfaceName    = $InterfaceName
        IPAddress        = ConvertTo-NlbPortRuleIPAddress -IPAddress $IPAddress
        StartPort        = $StartPort
        LoadWeight       = $null
        EqualLoad        = $null
        HandlingPriority = $null
        State            = $null
        Drain            = $null
        DrainTimeout     = $null
        HostName         = $HostName
        Mode             = $null
    }

    $portRule = Get-NlbDscNodePortRule -NodeName $NodeName -InterfaceName $InterfaceName -IPAddress $IPAddress -StartPort $StartPort -HostName $HostName

    if ($null -ne $portRule)
    {
        $currentPortRule = ConvertFrom-NlbPortRule -PortRule $portRule

        foreach ($key in @('LoadWeight', 'EqualLoad', 'HandlingPriority', 'State', 'Mode'))
        {
            $getTargetResourceResult[$key] = $currentPortRule[$key]
        }

        Write-Verbose -Message (
            $script:localizedData.PortRuleFound -f $NodeName, $currentPortRule.Mode, $currentPortRule.EqualLoad,
                $currentPortRule.LoadWeight, $currentPortRule.HandlingPriority, $currentPortRule.State
        )
    }

    return $getTargetResourceResult
}

<#
    .SYNOPSIS
        Applies the node specific settings of the port rule.

    .PARAMETER NodeName
        Specifies the name of the node.

    .PARAMETER InterfaceName
        Specifies the name of the network interface to which NLB is bound.

    .PARAMETER IPAddress
        Specifies the cluster IP address of the port rule, or 'All'.

    .PARAMETER StartPort
        Specifies a port within the port range of the port rule.

    .PARAMETER LoadWeight
        Specifies the load weight (0 - 100) of the node (mode Multiple).

    .PARAMETER EqualLoad
        Specifies equal load distribution for the node (mode Multiple).

    .PARAMETER HandlingPriority
        Specifies the handling priority (1 - 32) of the node (mode Single).

    .PARAMETER State
        Specifies if the port rule is enabled or disabled on this node.

    .PARAMETER Drain
        Specifies if existing connections are drained before the rule is disabled.

    .PARAMETER DrainTimeout
        Specifies the number of minutes to wait for the drain operation.

    .PARAMETER HostName
        Specifies the name of a cluster host used to manage the cluster.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $NodeName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InterfaceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IPAddress,

        [Parameter(Mandatory = $true)]
        [System.UInt16]
        $StartPort,

        [Parameter()]
        [ValidateRange(0, 100)]
        [System.UInt32]
        $LoadWeight,

        [Parameter()]
        [System.Boolean]
        $EqualLoad,

        [Parameter()]
        [ValidateRange(1, 32)]
        [System.UInt32]
        $HandlingPriority,

        [Parameter()]
        [ValidateSet('Enabled', 'Disabled')]
        [System.String]
        $State,

        [Parameter()]
        [System.Boolean]
        $Drain = $false,

        [Parameter()]
        [System.UInt32]
        $DrainTimeout,

        [Parameter()]
        [System.String]
        $HostName
    )

    Assert-NlbPortRuleNodeParameter -BoundParameters $PSBoundParameters

    $getParameters = @{
        NodeName      = $NodeName
        InterfaceName = $InterfaceName
        IPAddress     = $IPAddress
        StartPort     = $StartPort
        HostName      = $HostName
    }

    $portRule = Get-NlbDscNodePortRule @getParameters

    if ($null -eq $portRule)
    {
        New-InvalidOperationException -Message ($script:localizedData.PortRuleRequired -f $IPAddress, $StartPort, $NodeName)
    }

    $current = ConvertFrom-NlbPortRule -PortRule $portRule
    $desired = Get-NlbPortRuleNodeDesiredState -BoundParameters $PSBoundParameters -Mode $current.Mode

    try
    {
        if ($desired.ContainsKey('EqualLoad') -and $desired.EqualLoad -and $current.EqualLoad -ne $true)
        {
            Write-Verbose -Message ($script:localizedData.SettingEqualLoad -f $NodeName)

            $null = $portRule | Set-NlbClusterPortRuleNodeWeight -Equal -ErrorAction 'Stop'
        }
        elseif ($desired.ContainsKey('LoadWeight') -and ($current.EqualLoad -eq $true -or $current.LoadWeight -ne $desired.LoadWeight))
        {
            Write-Verbose -Message ($script:localizedData.SettingLoadWeight -f $NodeName, $desired.LoadWeight)

            $null = $portRule | Set-NlbClusterPortRuleNodeWeight -LoadWeight ([System.Int32] $desired.LoadWeight) -ErrorAction 'Stop'
        }

        if ($desired.ContainsKey('HandlingPriority') -and $current.HandlingPriority -ne $desired.HandlingPriority)
        {
            Write-Verbose -Message ($script:localizedData.SettingHandlingPriority -f $NodeName, $desired.HandlingPriority)

            $null = $portRule | Set-NlbClusterPortRuleNodeHandlingPriority -HandlingPriority ([System.Int32] $desired.HandlingPriority) -ErrorAction 'Stop'
        }

        if ($desired.ContainsKey('State') -and $current.State -ne $desired.State)
        {
            # Read the rule again - the previous changes may have replaced the object.
            $portRule = Get-NlbDscNodePortRule @getParameters

            if ($desired.State -eq 'Enabled')
            {
                Write-Verbose -Message ($script:localizedData.EnablingPortRule -f $NodeName)

                $null = $portRule | Enable-NlbClusterPortRule -ErrorAction 'Stop'
            }
            else
            {
                Write-Verbose -Message ($script:localizedData.DisablingPortRule -f $NodeName, $Drain)

                $disableParameters = @{
                    ErrorAction = 'Stop'
                }

                if ($Drain)
                {
                    $disableParameters['Drain'] = $true

                    if ($PSBoundParameters.ContainsKey('DrainTimeout'))
                    {
                        $disableParameters['Timeout'] = $DrainTimeout
                    }
                }

                $null = $portRule | Disable-NlbClusterPortRule @disableParameters
            }
        }
    }
    catch
    {
        New-InvalidOperationException -Message ($script:localizedData.ChangeFailed -f $NodeName) -ErrorRecord $_
    }
}

<#
    .SYNOPSIS
        Tests whether the node specific settings of the port rule are in the
        desired state.

    .PARAMETER NodeName
        Specifies the name of the node.

    .PARAMETER InterfaceName
        Specifies the name of the network interface to which NLB is bound.

    .PARAMETER IPAddress
        Specifies the cluster IP address of the port rule, or 'All'.

    .PARAMETER StartPort
        Specifies a port within the port range of the port rule.

    .PARAMETER LoadWeight
        Specifies the load weight (0 - 100) of the node (mode Multiple).

    .PARAMETER EqualLoad
        Specifies equal load distribution for the node (mode Multiple).

    .PARAMETER HandlingPriority
        Specifies the handling priority (1 - 32) of the node (mode Single).

    .PARAMETER State
        Specifies if the port rule is enabled or disabled on this node.

    .PARAMETER Drain
        Specifies if existing connections are drained before the rule is disabled.

    .PARAMETER DrainTimeout
        Specifies the number of minutes to wait for the drain operation.

    .PARAMETER HostName
        Specifies the name of a cluster host used to manage the cluster.
#>
function Test-TargetResource
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'LoadWeight', Justification = 'Evaluated through PSBoundParameters.')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'EqualLoad', Justification = 'Evaluated through PSBoundParameters.')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'HandlingPriority', Justification = 'Evaluated through PSBoundParameters.')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'State', Justification = 'Evaluated through PSBoundParameters.')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Drain', Justification = 'Only used when the port rule is disabled.')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'DrainTimeout', Justification = 'Only used when the port rule is disabled.')]
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $NodeName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InterfaceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IPAddress,

        [Parameter(Mandatory = $true)]
        [System.UInt16]
        $StartPort,

        [Parameter()]
        [ValidateRange(0, 100)]
        [System.UInt32]
        $LoadWeight,

        [Parameter()]
        [System.Boolean]
        $EqualLoad,

        [Parameter()]
        [ValidateRange(1, 32)]
        [System.UInt32]
        $HandlingPriority,

        [Parameter()]
        [ValidateSet('Enabled', 'Disabled')]
        [System.String]
        $State,

        [Parameter()]
        [System.Boolean]
        $Drain = $false,

        [Parameter()]
        [System.UInt32]
        $DrainTimeout,

        [Parameter()]
        [System.String]
        $HostName
    )

    Write-Verbose -Message ($script:localizedData.TestDesiredState -f $NodeName)

    Assert-NlbPortRuleNodeParameter -BoundParameters $PSBoundParameters

    $currentState = Get-TargetResource -NodeName $NodeName -InterfaceName $InterfaceName -IPAddress $IPAddress -StartPort $StartPort -HostName $HostName

    if ($null -eq $currentState.Mode)
    {
        Write-Verbose -Message ($script:localizedData.NotInDesiredState -f $NodeName)

        return $false
    }

    $desiredState = Get-NlbPortRuleNodeDesiredState -BoundParameters $PSBoundParameters -Mode $currentState.Mode

    $inDesiredState = $true

    if ($desiredState.Count -gt 0)
    {
        # EqualLoad = $true makes the load weight irrelevant.
        if ($desiredState.ContainsKey('EqualLoad') -and $desiredState.EqualLoad)
        {
            $currentState.LoadWeight = $null
        }

        $inDesiredState = Test-DscParameterState `
            -CurrentValues $currentState `
            -DesiredValues $desiredState `
            -Properties @($desiredState.Keys) `
            -TurnOffTypeChecking `
            -Verbose:$VerbosePreference
    }

    if ($inDesiredState)
    {
        Write-Verbose -Message ($script:localizedData.InDesiredState -f $NodeName)
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.NotInDesiredState -f $NodeName)
    }

    return $inDesiredState
}

<#
    .SYNOPSIS
        Throws when EqualLoad = $true and LoadWeight are used together, or
        when EqualLoad = $false is used without LoadWeight.

    .PARAMETER BoundParameters
        The bound parameters of the calling function.
#>
function Assert-NlbPortRuleNodeParameter
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]
        $BoundParameters
    )

    if ($BoundParameters.ContainsKey('LoadWeight') -and $BoundParameters.ContainsKey('EqualLoad') -and $BoundParameters['EqualLoad'])
    {
        New-ArgumentException -ArgumentName 'LoadWeight' -Message $script:localizedData.EqualLoadAndLoadWeight
    }

    if ($BoundParameters.ContainsKey('EqualLoad') -and -not $BoundParameters['EqualLoad'] -and -not $BoundParameters.ContainsKey('LoadWeight'))
    {
        New-ArgumentException -ArgumentName 'EqualLoad' -Message $script:localizedData.EqualLoadFalseRequiresLoadWeight
    }
}

<#
    .SYNOPSIS
        Returns the specified settings that apply to the filtering mode of the
        port rule.

    .PARAMETER BoundParameters
        The bound parameters of the calling function.

    .PARAMETER Mode
        The filtering mode of the port rule.
#>
function Get-NlbPortRuleNodeDesiredState
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]
        $BoundParameters,

        [Parameter()]
        [System.String]
        $Mode
    )

    $desiredState = @{}

    foreach ($propertyName in @('LoadWeight', 'EqualLoad'))
    {
        if ($BoundParameters.ContainsKey($propertyName))
        {
            if ($Mode -eq 'Multiple')
            {
                $desiredState[$propertyName] = $BoundParameters[$propertyName]
            }
            else
            {
                Write-Verbose -Message ($script:localizedData.SettingIgnored -f $propertyName, $Mode)
            }
        }
    }

    if ($BoundParameters.ContainsKey('HandlingPriority'))
    {
        if ($Mode -eq 'Single')
        {
            $desiredState['HandlingPriority'] = $BoundParameters['HandlingPriority']
        }
        else
        {
            Write-Verbose -Message ($script:localizedData.SettingIgnored -f 'HandlingPriority', $Mode)
        }
    }

    if ($BoundParameters.ContainsKey('State'))
    {
        $desiredState['State'] = $BoundParameters['State']
    }

    return $desiredState
}

Export-ModuleMember -Function *-TargetResource
