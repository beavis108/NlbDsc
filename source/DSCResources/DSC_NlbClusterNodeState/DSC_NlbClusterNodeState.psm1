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
        Returns the node object, or $null when the feature, the cluster or the
        node does not exist.

    .PARAMETER NodeName
        The name of the node.

    .PARAMETER InterfaceName
        The name of the network interface to which NLB is bound.

    .PARAMETER HostName
        The name of the cluster host used to manage the node.
#>
function Get-NlbDscClusterNode
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
        Write-Verbose -Message ($script:localizedData.ClusterNotFound -f $InterfaceName, $HostName)

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
        Returns the host state of the node.

    .PARAMETER NodeName
        Specifies the name of the cluster node.

    .PARAMETER InterfaceName
        Specifies the name of the network interface to which NLB is bound.

    .PARAMETER State
        Specifies the desired host state of the node.

    .PARAMETER HostName
        Specifies the name of a cluster host used to manage the node.
#>
function Get-TargetResource
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'State', Justification = 'Required parameter of the DSC schema. The current value is returned from the node.')]
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
        [ValidateSet('Started', 'Stopped', 'Suspended')]
        [System.String]
        $State,

        [Parameter()]
        [System.String]
        $HostName
    )

    Write-Verbose -Message ($script:localizedData.GetCurrentState -f $NodeName)

    $getTargetResourceResult = @{
        NodeName      = $NodeName
        InterfaceName = $InterfaceName
        State         = $null
        HostName      = $HostName
        Drain         = $null
        DrainTimeout  = $null
        CurrentState  = $null
    }

    $nlbClusterNode = Get-NlbDscClusterNode -NodeName $NodeName -InterfaceName $InterfaceName -HostName $HostName

    if ($null -ne $nlbClusterNode)
    {
        $getTargetResourceResult.CurrentState = [System.String] $nlbClusterNode.State
        $getTargetResourceResult.State = ConvertTo-NlbNodeState -State $nlbClusterNode.State

        Write-Verbose -Message (
            $script:localizedData.NodeStateFound -f $NodeName, $getTargetResourceResult.CurrentState, $getTargetResourceResult.State
        )
    }

    return $getTargetResourceResult
}

<#
    .SYNOPSIS
        Starts, stops, suspends or resumes the node.

    .PARAMETER NodeName
        Specifies the name of the cluster node.

    .PARAMETER InterfaceName
        Specifies the name of the network interface to which NLB is bound.

    .PARAMETER State
        Specifies the desired host state of the node.

    .PARAMETER HostName
        Specifies the name of a cluster host used to manage the node.

    .PARAMETER Drain
        Specifies if existing connections are drained before the node is stopped.

    .PARAMETER DrainTimeout
        Specifies the number of seconds to wait for the drain operation.
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
        [ValidateSet('Started', 'Stopped', 'Suspended')]
        [System.String]
        $State,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [System.Boolean]
        $Drain = $false,

        [Parameter()]
        [System.UInt32]
        $DrainTimeout
    )

    $nlbClusterNode = Get-NlbDscClusterNode -NodeName $NodeName -InterfaceName $InterfaceName -HostName $HostName

    if ($null -eq $nlbClusterNode)
    {
        New-InvalidOperationException -Message ($script:localizedData.NodeRequired -f $NodeName, $InterfaceName)
    }

    $currentState = ConvertTo-NlbNodeState -State $nlbClusterNode.State

    try
    {
        switch ($State)
        {
            'Started'
            {
                if ($currentState -eq 'Suspended')
                {
                    Write-Verbose -Message ($script:localizedData.ResumingNode -f $NodeName)

                    $null = $nlbClusterNode | Resume-NlbClusterNode -ErrorAction 'Stop'
                }

                if ($currentState -ne 'Started')
                {
                    Write-Verbose -Message ($script:localizedData.StartingNode -f $NodeName)

                    $null = $nlbClusterNode | Start-NlbClusterNode -ErrorAction 'Stop'
                }
            }

            'Stopped'
            {
                if ($currentState -eq 'Suspended')
                {
                    Write-Verbose -Message ($script:localizedData.ResumingNode -f $NodeName)

                    $null = $nlbClusterNode | Resume-NlbClusterNode -ErrorAction 'Stop'
                }
                elseif ($currentState -notin @('Stopped', 'Draining'))
                {
                    Write-Verbose -Message ($script:localizedData.StoppingNode -f $NodeName, $Drain)

                    $stopParameters = @{
                        ErrorAction = 'Stop'
                    }

                    if ($Drain)
                    {
                        $stopParameters['Drain'] = $true

                        if ($PSBoundParameters.ContainsKey('DrainTimeout'))
                        {
                            $stopParameters['Timeout'] = $DrainTimeout
                        }
                    }

                    $null = $nlbClusterNode | Stop-NlbClusterNode @stopParameters
                }
            }

            'Suspended'
            {
                if ($currentState -ne 'Suspended')
                {
                    Write-Verbose -Message ($script:localizedData.SuspendingNode -f $NodeName)

                    $null = $nlbClusterNode | Suspend-NlbClusterNode -ErrorAction 'Stop'
                }
            }
        }
    }
    catch
    {
        New-InvalidOperationException -Message ($script:localizedData.ChangeStateFailed -f $NodeName, $State) -ErrorRecord $_
    }
}

<#
    .SYNOPSIS
        Tests whether the node has the desired host state.

    .PARAMETER NodeName
        Specifies the name of the cluster node.

    .PARAMETER InterfaceName
        Specifies the name of the network interface to which NLB is bound.

    .PARAMETER State
        Specifies the desired host state of the node.

    .PARAMETER HostName
        Specifies the name of a cluster host used to manage the node.

    .PARAMETER Drain
        Specifies if existing connections are drained before the node is stopped.

    .PARAMETER DrainTimeout
        Specifies the number of seconds to wait for the drain operation.
#>
function Test-TargetResource
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Drain', Justification = 'Only used when the node is stopped.')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'DrainTimeout', Justification = 'Only used when the node is stopped.')]
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
        [ValidateSet('Started', 'Stopped', 'Suspended')]
        [System.String]
        $State,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [System.Boolean]
        $Drain = $false,

        [Parameter()]
        [System.UInt32]
        $DrainTimeout
    )

    Write-Verbose -Message ($script:localizedData.TestDesiredState -f $NodeName, $State)

    $currentState = (Get-TargetResource -NodeName $NodeName -InterfaceName $InterfaceName -State $State -HostName $HostName).State

    $inDesiredState = $currentState -eq $State -or ($State -eq 'Stopped' -and $currentState -eq 'Draining')

    if ($inDesiredState)
    {
        Write-Verbose -Message ($script:localizedData.InDesiredState -f $NodeName, $State)
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.NotInDesiredState -f $NodeName, $State, $currentState)
    }

    return $inDesiredState
}

Export-ModuleMember -Function *-TargetResource
