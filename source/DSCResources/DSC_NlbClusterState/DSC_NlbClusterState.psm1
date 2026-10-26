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
        Returns the host state of all nodes of the NLB cluster.

    .PARAMETER InterfaceName
        Specifies the name of the network interface to which NLB is bound.

    .PARAMETER State
        Specifies the desired host state of all nodes.

    .PARAMETER HostName
        Specifies the name of a cluster host used to manage the cluster.
#>
function Get-TargetResource
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'State', Justification = 'Required parameter of the DSC schema. The current states are returned in NodeStates.')]
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
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

    Write-Verbose -Message ($script:localizedData.GetCurrentState -f $InterfaceName)

    $getTargetResourceResult = @{
        InterfaceName = $InterfaceName
        State         = $null
        HostName      = $HostName
        Drain         = $null
        DrainTimeout  = $null
        NodeStates    = [System.String[]] @()
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
        Write-Verbose -Message ($script:localizedData.ClusterNotFound -f $InterfaceName, $HostName)

        return $getTargetResourceResult
    }

    $nodes = @($nlbCluster | Get-NlbClusterNode -ErrorAction 'Stop')

    $getTargetResourceResult.NodeStates = [System.String[]] @(
        $nodes | ForEach-Object -Process {
            '{0}={1}' -f $_.Name, (ConvertTo-NlbNodeState -State $_.State)
        }
    )

    $distinctStates = @(
        $nodes | ForEach-Object -Process {
            ConvertTo-NlbNodeState -State $_.State
        } | Sort-Object -Unique
    )

    # Report a single state only when all nodes share it.
    if ($distinctStates.Count -eq 1)
    {
        $getTargetResourceResult.State = $distinctStates[0]
    }
    elseif ($distinctStates.Count -gt 1)
    {
        $getTargetResourceResult.State = 'Mixed'
    }

    Write-Verbose -Message ($script:localizedData.NodeStates -f ($getTargetResourceResult.NodeStates -join "', '"))

    return $getTargetResourceResult
}

<#
    .SYNOPSIS
        Starts, stops, suspends or resumes all nodes of the NLB cluster.

    .PARAMETER InterfaceName
        Specifies the name of the network interface to which NLB is bound.

    .PARAMETER State
        Specifies the desired host state of all nodes.

    .PARAMETER HostName
        Specifies the name of a cluster host used to manage the cluster.

    .PARAMETER Drain
        Specifies if existing connections are drained before the cluster is stopped.

    .PARAMETER DrainTimeout
        Specifies the number of minutes to wait for the drain operation.
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

    if (-not (Test-NlbFeatureInstalled))
    {
        New-InvalidOperationException -Message ($script:localizedData.ClusterRequired -f $InterfaceName, $HostName)
    }

    Import-NlbModule

    $nlbCluster = Get-NlbDscCluster -InterfaceName $InterfaceName -HostName $HostName

    if ($null -eq $nlbCluster)
    {
        New-InvalidOperationException -Message ($script:localizedData.ClusterRequired -f $InterfaceName, $HostName)
    }

    $nodeStates = @(
        $nlbCluster | Get-NlbClusterNode -ErrorAction 'Stop' | ForEach-Object -Process {
            ConvertTo-NlbNodeState -State $_.State
        }
    )

    try
    {
        if ($State -in @('Started', 'Stopped') -and $nodeStates -contains 'Suspended')
        {
            Write-Verbose -Message ($script:localizedData.ResumingCluster -f $nlbCluster.Name)

            $null = $nlbCluster | Resume-NlbCluster -ErrorAction 'Stop'
        }

        switch ($State)
        {
            'Started'
            {
                Write-Verbose -Message ($script:localizedData.StartingCluster -f $nlbCluster.Name)

                $null = $nlbCluster | Start-NlbCluster -ErrorAction 'Stop'
            }

            'Stopped'
            {
                if ($nodeStates -contains 'Started')
                {
                    Write-Verbose -Message ($script:localizedData.StoppingCluster -f $nlbCluster.Name, $Drain)

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

                    $null = $nlbCluster | Stop-NlbCluster @stopParameters
                }
            }

            'Suspended'
            {
                Write-Verbose -Message ($script:localizedData.SuspendingCluster -f $nlbCluster.Name)

                $null = $nlbCluster | Suspend-NlbCluster -ErrorAction 'Stop'
            }
        }
    }
    catch
    {
        New-InvalidOperationException -Message ($script:localizedData.ChangeStateFailed -f $nlbCluster.Name, $State) -ErrorRecord $_
    }
}

<#
    .SYNOPSIS
        Tests whether all nodes of the NLB cluster have the desired host state.

    .PARAMETER InterfaceName
        Specifies the name of the network interface to which NLB is bound.

    .PARAMETER State
        Specifies the desired host state of all nodes.

    .PARAMETER HostName
        Specifies the name of a cluster host used to manage the cluster.

    .PARAMETER Drain
        Specifies if existing connections are drained before the cluster is stopped.

    .PARAMETER DrainTimeout
        Specifies the number of minutes to wait for the drain operation.
#>
function Test-TargetResource
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Drain', Justification = 'Only used when the cluster is stopped.')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'DrainTimeout', Justification = 'Only used when the cluster is stopped.')]
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
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

    Write-Verbose -Message ($script:localizedData.TestDesiredState -f $State)

    $currentState = Get-TargetResource -InterfaceName $InterfaceName -State $State -HostName $HostName

    $acceptedStates = @($State)

    if ($State -eq 'Stopped')
    {
        $acceptedStates += 'Draining'
    }

    $nodeStates = @($currentState.NodeStates | ForEach-Object -Process { ($_ -split '=', 2)[1] })

    $inDesiredState = $nodeStates.Count -gt 0 -and @($nodeStates | Where-Object -FilterScript { $_ -notin $acceptedStates }).Count -eq 0

    if ($inDesiredState)
    {
        Write-Verbose -Message ($script:localizedData.InDesiredState -f $State)
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.NotInDesiredState -f $State, ($currentState.NodeStates -join "', '"))
    }

    return $inDesiredState
}

Export-ModuleMember -Function *-TargetResource
