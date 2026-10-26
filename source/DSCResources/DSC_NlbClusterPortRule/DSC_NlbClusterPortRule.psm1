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
        Returns the current state of the NLB port rule.

    .PARAMETER InterfaceName
        Specifies the name of the network interface to which NLB is bound.

    .PARAMETER IPAddress
        Specifies the cluster IP address of the port rule, or 'All'.

    .PARAMETER StartPort
        Specifies the start port of the port rule.

    .PARAMETER EndPort
        Specifies the end port of the port rule.

    .PARAMETER HostName
        Specifies the name of the cluster host. Defaults to the local node.
#>
function Get-TargetResource
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'EndPort', Justification = 'Required parameter of the DSC schema. The current value is returned from the port rule.')]
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

        [Parameter(Mandatory = $true)]
        [System.UInt16]
        $StartPort,

        [Parameter(Mandatory = $true)]
        [System.UInt16]
        $EndPort,

        [Parameter()]
        [System.String]
        $HostName
    )

    Write-Verbose -Message ($script:localizedData.GetCurrentState -f $IPAddress, $StartPort, $InterfaceName)

    $getTargetResourceResult = @{
        InterfaceName = $InterfaceName
        IPAddress     = ConvertTo-NlbPortRuleIPAddress -IPAddress $IPAddress
        StartPort     = $StartPort
        EndPort       = $null
        Protocol      = $null
        Mode          = $null
        Affinity      = $null
        Timeout       = $null
        State         = $null
        Drain         = $null
        DrainTimeout  = $null
        HostName      = $HostName
        Ensure        = 'Absent'
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

    $portRule = Find-NlbClusterPortRule -InputObject $nlbCluster -IPAddress $IPAddress -StartPort $StartPort

    if ($null -eq $portRule)
    {
        Write-Verbose -Message ($script:localizedData.PortRuleNotFound -f $IPAddress, $StartPort)

        return $getTargetResourceResult
    }

    $currentPortRule = ConvertFrom-NlbPortRule -PortRule $portRule

    foreach ($key in @('IPAddress', 'StartPort', 'EndPort', 'Protocol', 'Mode', 'Affinity', 'Timeout', 'State'))
    {
        $getTargetResourceResult[$key] = $currentPortRule[$key]
    }

    $getTargetResourceResult.Ensure = 'Present'

    Write-Verbose -Message (
        $script:localizedData.PortRuleFound -f $currentPortRule.StartPort,
            $currentPortRule.EndPort,
            $currentPortRule.IPAddress,
            $currentPortRule.Protocol,
            $currentPortRule.Mode,
            $currentPortRule.Affinity,
            $currentPortRule.Timeout
    )

    return $getTargetResourceResult
}

<#
    .SYNOPSIS
        Adds, updates, enables, disables or removes the NLB port rule.

    .PARAMETER InterfaceName
        Specifies the name of the network interface to which NLB is bound.

    .PARAMETER IPAddress
        Specifies the cluster IP address of the port rule, or 'All'.

    .PARAMETER StartPort
        Specifies the start port of the port rule.

    .PARAMETER EndPort
        Specifies the end port of the port rule.

    .PARAMETER Protocol
        Specifies the protocol of the port rule. Defaults to 'Both'.

    .PARAMETER Mode
        Specifies the filtering mode of the port rule. Defaults to 'Multiple'.

    .PARAMETER Affinity
        Specifies the client affinity (only for Mode 'Multiple'). Defaults to 'Single'.

    .PARAMETER Timeout
        Specifies the affinity timeout in minutes (only for Mode 'Multiple'). Defaults to 0.

    .PARAMETER State
        Specifies if the port rule is enabled or disabled on all cluster nodes.

    .PARAMETER Drain
        Specifies if existing connections are drained before the rule is disabled.

    .PARAMETER DrainTimeout
        Specifies the number of minutes to wait for the drain operation.

    .PARAMETER HostName
        Specifies the name of the cluster host. Defaults to the local node.

    .PARAMETER Ensure
        Specifies if the port rule should be present or absent. Defaults to 'Present'.
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

        [Parameter(Mandatory = $true)]
        [System.UInt16]
        $StartPort,

        [Parameter(Mandatory = $true)]
        [System.UInt16]
        $EndPort,

        [Parameter()]
        [ValidateSet('Both', 'Tcp', 'Udp')]
        [System.String]
        $Protocol = 'Both',

        [Parameter()]
        [ValidateSet('Single', 'Multiple', 'Disabled')]
        [System.String]
        $Mode = 'Multiple',

        [Parameter()]
        [ValidateSet('None', 'Single', 'Network')]
        [System.String]
        $Affinity = 'Single',

        [Parameter()]
        [ValidateRange(0, 240)]
        [System.UInt32]
        $Timeout = 0,

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
        $HostName,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    Write-Verbose -Message ($script:localizedData.SetDesiredState -f $IPAddress, $StartPort)

    Assert-NlbPortRange -StartPort $StartPort -EndPort $EndPort

    if (-not (Test-NlbFeatureInstalled))
    {
        if ($Ensure -eq 'Absent')
        {
            return
        }

        New-InvalidOperationException -Message $script:localizedData.FeatureRequired
    }

    Import-NlbModule

    $nlbCluster = Get-NlbDscCluster -InterfaceName $InterfaceName -HostName $HostName

    if ($null -eq $nlbCluster)
    {
        if ($Ensure -eq 'Absent')
        {
            return
        }

        New-InvalidOperationException -Message ($script:localizedData.ClusterRequired -f $InterfaceName)
    }

    $portRule = Find-NlbClusterPortRule -InputObject $nlbCluster -IPAddress $IPAddress -StartPort $StartPort
    $normalizedIPAddress = ConvertTo-NlbPortRuleIPAddress -IPAddress $IPAddress

    if ($Ensure -eq 'Absent')
    {
        if ($null -ne $portRule)
        {
            $currentPortRule = ConvertFrom-NlbPortRule -PortRule $portRule

            Write-Verbose -Message ($script:localizedData.RemovingPortRule -f $currentPortRule.StartPort, $currentPortRule.EndPort, $normalizedIPAddress)

            try
            {
                $portRule | Remove-NlbClusterPortRule -Force -ErrorAction 'Stop'
            }
            catch
            {
                New-InvalidOperationException -Message (
                    $script:localizedData.RemovePortRuleFailed -f $currentPortRule.StartPort, $currentPortRule.EndPort, $normalizedIPAddress
                ) -ErrorRecord $_
            }
        }

        return
    }

    # Affinity and timeout are only valid for the filtering mode 'Multiple'.
    $useAffinity = $Mode -eq 'Multiple'

    if ($null -eq $portRule)
    {
        Write-Verbose -Message ($script:localizedData.AddingPortRule -f $StartPort, $EndPort, $normalizedIPAddress)

        $addPortRuleParameters = @{
            StartPort   = $StartPort
            EndPort     = $EndPort
            Protocol    = $Protocol
            Mode        = $Mode
            ErrorAction = 'Stop'
        }

        if ($normalizedIPAddress -ne 'All')
        {
            $addPortRuleParameters['IP'] = $normalizedIPAddress
        }

        if ($useAffinity)
        {
            $addPortRuleParameters['Affinity'] = $Affinity
            $addPortRuleParameters['Timeout'] = $Timeout
        }

        try
        {
            $null = $nlbCluster | Add-NlbClusterPortRule @addPortRuleParameters
        }
        catch
        {
            New-InvalidOperationException -Message (
                $script:localizedData.AddPortRuleFailed -f $StartPort, $EndPort, $normalizedIPAddress
            ) -ErrorRecord $_
        }
    }
    else
    {
        $currentPortRule = ConvertFrom-NlbPortRule -PortRule $portRule

        $settingsInDesiredState = $currentPortRule.StartPort -eq $StartPort -and
            $currentPortRule.EndPort -eq $EndPort -and
            $currentPortRule.Protocol -eq $Protocol -and
            $currentPortRule.Mode -eq $Mode -and
            (-not $useAffinity -or ($currentPortRule.Affinity -eq $Affinity -and $currentPortRule.Timeout -eq $Timeout))

        if (-not $settingsInDesiredState)
        {
            Write-Verbose -Message (
                $script:localizedData.UpdatingPortRule -f $currentPortRule.StartPort, $currentPortRule.EndPort, $normalizedIPAddress, $StartPort, $EndPort
            )

            $setPortRuleParameters = @{
                NewStartPort = $StartPort
                NewEndPort   = $EndPort
                NewProtocol  = $Protocol
                NewMode      = $Mode
                ErrorAction  = 'Stop'
            }

            if ($useAffinity)
            {
                $setPortRuleParameters['NewAffinity'] = $Affinity
                $setPortRuleParameters['NewTimeout'] = $Timeout
            }

            try
            {
                $null = $portRule | Set-NlbClusterPortRule @setPortRuleParameters
            }
            catch
            {
                New-InvalidOperationException -Message (
                    $script:localizedData.UpdatePortRuleFailed -f $currentPortRule.StartPort, $currentPortRule.EndPort, $normalizedIPAddress
                ) -ErrorRecord $_
            }
        }
    }

    if ($PSBoundParameters.ContainsKey('State'))
    {
        $currentState = $null

        $portRule = Find-NlbClusterPortRule -InputObject $nlbCluster -IPAddress $IPAddress -StartPort $StartPort

        if ($null -ne $portRule)
        {
            $currentState = (ConvertFrom-NlbPortRule -PortRule $portRule).State
        }

        if ($currentState -ne $State)
        {
            $portRuleParameters = @{
                ClusterWide   = $true
                InterfaceName = $InterfaceName
                IP            = ConvertTo-NlbCmdletIPAddress -IPAddress $IPAddress
                Port          = [System.UInt32] $StartPort
                ErrorAction   = 'Stop'
            }

            if (-not [System.String]::IsNullOrWhiteSpace($HostName))
            {
                $portRuleParameters['HostName'] = $HostName
            }

            try
            {
                if ($State -eq 'Enabled')
                {
                    Write-Verbose -Message ($script:localizedData.EnablingPortRule -f $normalizedIPAddress, $StartPort)

                    $null = Enable-NlbClusterPortRule @portRuleParameters
                }
                else
                {
                    Write-Verbose -Message ($script:localizedData.DisablingPortRule -f $normalizedIPAddress, $StartPort, $Drain)

                    if ($Drain)
                    {
                        $portRuleParameters['Drain'] = $true

                        if ($PSBoundParameters.ContainsKey('DrainTimeout'))
                        {
                            $portRuleParameters['Timeout'] = $DrainTimeout
                        }
                    }

                    $null = Disable-NlbClusterPortRule @portRuleParameters
                }
            }
            catch
            {
                New-InvalidOperationException -Message (
                    $script:localizedData.ChangePortRuleStateFailed -f $normalizedIPAddress, $StartPort
                ) -ErrorRecord $_
            }
        }
    }
}

<#
    .SYNOPSIS
        Tests whether the NLB port rule is in the desired state.

    .PARAMETER InterfaceName
        Specifies the name of the network interface to which NLB is bound.

    .PARAMETER IPAddress
        Specifies the cluster IP address of the port rule, or 'All'.

    .PARAMETER StartPort
        Specifies the start port of the port rule.

    .PARAMETER EndPort
        Specifies the end port of the port rule.

    .PARAMETER Protocol
        Specifies the protocol of the port rule. Defaults to 'Both'.

    .PARAMETER Mode
        Specifies the filtering mode of the port rule. Defaults to 'Multiple'.

    .PARAMETER Affinity
        Specifies the client affinity (only for Mode 'Multiple'). Defaults to 'Single'.

    .PARAMETER Timeout
        Specifies the affinity timeout in minutes (only for Mode 'Multiple'). Defaults to 0.

    .PARAMETER State
        Specifies if the port rule is enabled or disabled on all cluster nodes.

    .PARAMETER Drain
        Specifies if existing connections are drained before the rule is disabled.

    .PARAMETER DrainTimeout
        Specifies the number of minutes to wait for the drain operation.

    .PARAMETER HostName
        Specifies the name of the cluster host. Defaults to the local node.

    .PARAMETER Ensure
        Specifies if the port rule should be present or absent. Defaults to 'Present'.
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

        [Parameter(Mandatory = $true)]
        [System.UInt16]
        $StartPort,

        [Parameter(Mandatory = $true)]
        [System.UInt16]
        $EndPort,

        [Parameter()]
        [ValidateSet('Both', 'Tcp', 'Udp')]
        [System.String]
        $Protocol = 'Both',

        [Parameter()]
        [ValidateSet('Single', 'Multiple', 'Disabled')]
        [System.String]
        $Mode = 'Multiple',

        [Parameter()]
        [ValidateSet('None', 'Single', 'Network')]
        [System.String]
        $Affinity = 'Single',

        [Parameter()]
        [ValidateRange(0, 240)]
        [System.UInt32]
        $Timeout = 0,

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
        $HostName,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    Write-Verbose -Message ($script:localizedData.TestDesiredState -f $IPAddress, $StartPort)

    Assert-NlbPortRange -StartPort $StartPort -EndPort $EndPort

    $getTargetResourceParameters = @{
        InterfaceName = $InterfaceName
        IPAddress     = $IPAddress
        StartPort     = $StartPort
        EndPort       = $EndPort
        HostName      = $HostName
    }

    $currentState = Get-TargetResource @getTargetResourceParameters

    $inDesiredState = $true

    if ($currentState.Ensure -ne $Ensure)
    {
        Write-Verbose -Message ($script:localizedData.EnsureMismatch -f $Ensure, $currentState.Ensure)

        $inDesiredState = $false
    }
    elseif ($Ensure -eq 'Present')
    {
        $desiredState = @{
            StartPort = $StartPort
            EndPort   = $EndPort
            Protocol  = $Protocol
            Mode      = $Mode
            Affinity  = $Affinity
            Timeout   = $Timeout
            State     = $State
        }

        $propertiesToCheck = @('StartPort', 'EndPort', 'Protocol', 'Mode')

        if ($Mode -eq 'Multiple')
        {
            $propertiesToCheck += @('Affinity', 'Timeout')
        }

        if ($PSBoundParameters.ContainsKey('State'))
        {
            $propertiesToCheck += 'State'
        }

        $inDesiredState = Test-DscParameterState `
            -CurrentValues $currentState `
            -DesiredValues $desiredState `
            -Properties $propertiesToCheck `
            -TurnOffTypeChecking `
            -Verbose:$VerbosePreference
    }

    if ($inDesiredState)
    {
        Write-Verbose -Message ($script:localizedData.InDesiredState -f $IPAddress, $StartPort)
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.NotInDesiredState -f $IPAddress, $StartPort)
    }

    return $inDesiredState
}

<#
    .SYNOPSIS
        Throws an error if EndPort is lower than StartPort.

    .PARAMETER StartPort
        The start port of the port rule.

    .PARAMETER EndPort
        The end port of the port rule.
#>
function Assert-NlbPortRange
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.UInt16]
        $StartPort,

        [Parameter(Mandatory = $true)]
        [System.UInt16]
        $EndPort
    )

    if ($EndPort -lt $StartPort)
    {
        New-ArgumentException -ArgumentName 'EndPort' -Message ($script:localizedData.InvalidPortRange -f $StartPort, $EndPort)
    }
}

Export-ModuleMember -Function *-TargetResource
