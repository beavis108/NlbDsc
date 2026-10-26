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

$script:initialHostStateValues = @('Started', 'Stopped', 'Suspended')

<#
    .SYNOPSIS
        Returns the membership and the settings of the node in the NLB cluster.

    .PARAMETER NodeName
        Specifies the name of the node.

    .PARAMETER NodeInterfaceName
        Specifies the name of the network interface on the node.

    .PARAMETER InterfaceName
        Specifies the name of the network interface on the existing cluster host.

    .PARAMETER HostName
        Specifies the name of an existing cluster host. Defaults to the local node.
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
        $NodeInterfaceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InterfaceName,

        [Parameter()]
        [System.String]
        $HostName
    )

    Write-Verbose -Message ($script:localizedData.GetCurrentState -f $NodeName, $InterfaceName)

    $getTargetResourceResult = @{
        NodeName          = $NodeName
        NodeInterfaceName = $NodeInterfaceName
        InterfaceName     = $InterfaceName
        HostName          = $HostName
        HostPriority      = $null
        InitialHostState  = $null
        RetainSuspended   = $null
        Ensure            = 'Absent'
        State             = $null
    }

    if (-not (Test-NlbFeatureInstalled))
    {
        Write-Verbose -Message ($script:localizedData.FeatureNotInstalled -f $NodeName)

        return $getTargetResourceResult
    }

    Import-NlbModule

    $nlbCluster = Get-NlbDscCluster -InterfaceName $InterfaceName -HostName $HostName

    if ($null -eq $nlbCluster)
    {
        Write-Verbose -Message ($script:localizedData.ClusterNotFound -f $InterfaceName, $HostName, $NodeName)

        return $getTargetResourceResult
    }

    $nlbClusterNode = Find-NlbClusterNode -Cluster $nlbCluster -NodeName $NodeName

    if ($null -eq $nlbClusterNode)
    {
        Write-Verbose -Message ($script:localizedData.NodeNotFound -f $NodeName, $nlbCluster.Name)
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.NodeFound -f $NodeName, $nlbCluster.Name, $nlbClusterNode.State)

        $hostPriority = Get-NlbObjectPropertyValue -InputObject $nlbClusterNode -Name 'HostPriority', 'HostID'
        $retainSuspended = Get-NlbObjectPropertyValue -InputObject $nlbClusterNode -Name 'PersistSuspendOnReboot', 'RetainSuspended'

        $getTargetResourceResult.Ensure = 'Present'
        $getTargetResourceResult.State = [System.String] $nlbClusterNode.State
        $getTargetResourceResult.NodeInterfaceName = [System.String] (Get-NlbObjectPropertyValue -InputObject $nlbClusterNode -Name 'InterfaceName', 'Interface')
        $getTargetResourceResult.InitialHostState = ConvertTo-NlbDscValue -Value (Get-NlbObjectPropertyValue -InputObject $nlbClusterNode -Name 'InitialHostState') -AllowedValues $script:initialHostStateValues

        if ($null -ne $hostPriority)
        {
            $getTargetResourceResult.HostPriority = [System.UInt32] $hostPriority
        }

        if ($null -ne $retainSuspended)
        {
            $getTargetResourceResult.RetainSuspended = [System.Boolean]::Parse([System.String] $retainSuspended)
        }
    }

    return $getTargetResourceResult
}

<#
    .SYNOPSIS
        Adds the node to or removes the node from the NLB cluster and applies
        the node settings.

    .PARAMETER NodeName
        Specifies the name of the node.

    .PARAMETER NodeInterfaceName
        Specifies the name of the network interface on the node.

    .PARAMETER InterfaceName
        Specifies the name of the network interface on the existing cluster host.

    .PARAMETER HostName
        Specifies the name of an existing cluster host. Defaults to the local node.

    .PARAMETER HostPriority
        Specifies the host priority (1 - 32) of the node.

    .PARAMETER InitialHostState
        Specifies the initial host state of the node after a restart.

    .PARAMETER RetainSuspended
        Specifies if a suspended node stays suspended after a restart.

    .PARAMETER Ensure
        Specifies if the node should be a member of the cluster. Defaults to 'Present'.
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
        $NodeInterfaceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InterfaceName,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [ValidateRange(1, 32)]
        [System.UInt32]
        $HostPriority,

        [Parameter()]
        [ValidateSet('Started', 'Stopped', 'Suspended')]
        [System.String]
        $InitialHostState,

        [Parameter()]
        [System.Boolean]
        $RetainSuspended,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    Write-Verbose -Message ($script:localizedData.SetDesiredState -f $NodeName)

    if (-not (Test-NlbFeatureInstalled))
    {
        if ($Ensure -eq 'Absent')
        {
            return
        }

        # The NLB cmdlets are needed locally in any case - install the features (fix for the former xNLB bug).
        $restartRequired = Install-NlbFeature

        if ($restartRequired)
        {
            Write-Verbose -Message ($script:localizedData.RestartRequiredAfterFeatureInstall -f $NodeName)

            return
        }
    }

    Import-NlbModule

    $nlbCluster = Get-NlbDscCluster -InterfaceName $InterfaceName -HostName $HostName

    if ($null -eq $nlbCluster)
    {
        if ($Ensure -eq 'Absent')
        {
            return
        }

        New-InvalidOperationException -Message ($script:localizedData.ClusterRequired -f $InterfaceName, $HostName)
    }

    $nlbClusterNode = Find-NlbClusterNode -Cluster $nlbCluster -NodeName $NodeName

    if ($Ensure -eq 'Absent')
    {
        if ($null -ne $nlbClusterNode)
        {
            Write-Verbose -Message ($script:localizedData.RemovingNode -f $NodeName, $nlbCluster.Name)

            try
            {
                $nlbClusterNode | Remove-NlbClusterNode -Force -ErrorAction 'Stop'
            }
            catch
            {
                New-InvalidOperationException -Message (
                    $script:localizedData.RemoveNodeFailed -f $NodeName, $nlbCluster.Name
                ) -ErrorRecord $_
            }
        }

        return
    }

    if ($null -eq $nlbClusterNode)
    {
        Write-Verbose -Message ($script:localizedData.AddingNode -f $NodeName, $NodeInterfaceName, $nlbCluster.Name)

        try
        {
            $null = $nlbCluster | Add-NlbClusterNode -NewNodeName $NodeName -NewNodeInterface $NodeInterfaceName -Force -ErrorAction 'Stop'
        }
        catch
        {
            New-InvalidOperationException -Message (
                $script:localizedData.AddNodeFailed -f $NodeName, $nlbCluster.Name, $NodeInterfaceName
            ) -ErrorRecord $_
        }

        $nlbClusterNode = Find-NlbClusterNode -Cluster $nlbCluster -NodeName $NodeName
    }

    # Node settings (Set-NlbClusterNode).
    $setNodeParameters = @{}

    if ($PSBoundParameters.ContainsKey('HostPriority') -and
        [System.String] (Get-NlbObjectPropertyValue -InputObject $nlbClusterNode -Name 'HostPriority', 'HostID') -ne [System.String] $HostPriority)
    {
        $setNodeParameters['HostPriority'] = [System.Int32] $HostPriority
    }

    if ($PSBoundParameters.ContainsKey('InitialHostState') -and
        [System.String] (Get-NlbObjectPropertyValue -InputObject $nlbClusterNode -Name 'InitialHostState') -ne $InitialHostState)
    {
        $setNodeParameters['InitialHostState'] = $InitialHostState
    }

    if ($PSBoundParameters.ContainsKey('RetainSuspended') -and
        [System.String] (Get-NlbObjectPropertyValue -InputObject $nlbClusterNode -Name 'PersistSuspendOnReboot', 'RetainSuspended') -ne [System.String] $RetainSuspended)
    {
        $setNodeParameters['RetainSuspended'] = $RetainSuspended
    }

    if ($setNodeParameters.Count -gt 0 -and $null -ne $nlbClusterNode)
    {
        Write-Verbose -Message ($script:localizedData.ChangingNodeSettings -f $NodeName, ($setNodeParameters.Keys -join "', '"))

        try
        {
            $null = $nlbClusterNode | Set-NlbClusterNode @setNodeParameters -Force -ErrorAction 'Stop'
        }
        catch
        {
            New-InvalidOperationException -Message ($script:localizedData.ChangeNodeSettingsFailed -f $NodeName) -ErrorRecord $_
        }
    }
}

<#
    .SYNOPSIS
        Tests whether the node is in the desired state.

    .PARAMETER NodeName
        Specifies the name of the node.

    .PARAMETER NodeInterfaceName
        Specifies the name of the network interface on the node.

    .PARAMETER InterfaceName
        Specifies the name of the network interface on the existing cluster host.

    .PARAMETER HostName
        Specifies the name of an existing cluster host. Defaults to the local node.

    .PARAMETER HostPriority
        Specifies the host priority (1 - 32) of the node.

    .PARAMETER InitialHostState
        Specifies the initial host state of the node after a restart.

    .PARAMETER RetainSuspended
        Specifies if a suspended node stays suspended after a restart.

    .PARAMETER Ensure
        Specifies if the node should be a member of the cluster. Defaults to 'Present'.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $NodeName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $NodeInterfaceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InterfaceName,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [ValidateRange(1, 32)]
        [System.UInt32]
        $HostPriority,

        [Parameter()]
        [ValidateSet('Started', 'Stopped', 'Suspended')]
        [System.String]
        $InitialHostState,

        [Parameter()]
        [System.Boolean]
        $RetainSuspended,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    Write-Verbose -Message ($script:localizedData.TestDesiredState -f $NodeName)

    $getTargetResourceParameters = @{
        NodeName          = $NodeName
        NodeInterfaceName = $NodeInterfaceName
        InterfaceName     = $InterfaceName
        HostName          = $HostName
    }

    $currentState = Get-TargetResource @getTargetResourceParameters

    if ($currentState.Ensure -ne $Ensure)
    {
        Write-Verbose -Message ($script:localizedData.NotInDesiredState -f $NodeName, $Ensure, $currentState.Ensure)

        return $false
    }

    $inDesiredState = $true

    if ($Ensure -eq 'Present')
    {
        $boundParameters = $PSBoundParameters

        $propertiesToCheck = @(
            @('HostPriority', 'InitialHostState', 'RetainSuspended') | Where-Object -FilterScript {
                $boundParameters.ContainsKey($_)
            }
        )

        if ($propertiesToCheck.Count -gt 0)
        {
            $inDesiredState = Test-DscParameterState `
                -CurrentValues $currentState `
                -DesiredValues $boundParameters `
                -Properties $propertiesToCheck `
                -TurnOffTypeChecking `
                -Verbose:$VerbosePreference
        }
    }

    if ($inDesiredState)
    {
        Write-Verbose -Message ($script:localizedData.InDesiredState -f $NodeName)
    }

    return $inDesiredState
}

Export-ModuleMember -Function *-TargetResource
