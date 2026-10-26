<#
    .SYNOPSIS
        Converts a port rule object of the NetworkLoadBalancingClusters module
        to a hashtable with normalized values.

    .DESCRIPTION
        Reads all known property names of a cluster or node specific port rule
        and returns a hashtable with the keys IPAddress, StartPort, EndPort,
        Protocol, Mode, Affinity, Timeout, State, EqualLoad, LoadWeight and
        HandlingPriority. Values are converted to the casing used in the DSC
        schemas.

    .PARAMETER PortRule
        The port rule object.

    .OUTPUTS
        System.Collections.Hashtable

    .EXAMPLE
        ConvertFrom-NlbPortRule -PortRule (Find-NlbClusterPortRule -InputObject $cluster -IPAddress 'All' -StartPort 80)
#>
function ConvertFrom-NlbPortRule
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $PortRule
    )

    $timeout = [System.String] (Get-NlbObjectPropertyValue -InputObject $PortRule -Name 'Timeout')
    $loadWeight = [System.String] (Get-NlbObjectPropertyValue -InputObject $PortRule -Name 'LoadWeight')
    $priority = [System.String] (Get-NlbObjectPropertyValue -InputObject $PortRule -Name 'Priority', 'HandlingPriority')
    $equalLoad = [System.String] (Get-NlbObjectPropertyValue -InputObject $PortRule -Name 'EqualLoad')

    $portRuleValues = @{
        IPAddress        = ConvertTo-NlbPortRuleIPAddress -IPAddress (Get-NlbObjectPropertyValue -InputObject $PortRule -Name 'VirtualIPAddress', 'IPAddress', 'IP')
        StartPort        = [System.UInt16] (Get-NlbObjectPropertyValue -InputObject $PortRule -Name 'StartPort', 'Start')
        EndPort          = [System.UInt16] (Get-NlbObjectPropertyValue -InputObject $PortRule -Name 'EndPort', 'End')
        Protocol         = ConvertTo-NlbDscValue -Value (Get-NlbObjectPropertyValue -InputObject $PortRule -Name 'Protocol') -AllowedValues 'Both', 'Tcp', 'Udp'
        Mode             = ConvertTo-NlbDscValue -Value (Get-NlbObjectPropertyValue -InputObject $PortRule -Name 'FilteringMode', 'Mode') -AllowedValues 'Single', 'Multiple', 'Disabled'
        Affinity         = ConvertTo-NlbDscValue -Value (Get-NlbObjectPropertyValue -InputObject $PortRule -Name 'Affinity') -AllowedValues 'None', 'Single', 'Network'
        Timeout          = [System.UInt32] 0
        State            = ConvertTo-NlbDscValue -Value (Get-NlbObjectPropertyValue -InputObject $PortRule -Name 'PortState', 'State') -AllowedValues 'Enabled', 'Disabled'
        EqualLoad        = $null
        LoadWeight       = $null
        HandlingPriority = $null
    }

    if (-not [System.String]::IsNullOrEmpty($timeout))
    {
        $portRuleValues.Timeout = [System.UInt32] $timeout
    }

    if (-not [System.String]::IsNullOrEmpty($equalLoad))
    {
        $portRuleValues.EqualLoad = [System.Boolean]::Parse($equalLoad)
    }

    if (-not [System.String]::IsNullOrEmpty($loadWeight))
    {
        $portRuleValues.LoadWeight = [System.UInt32] $loadWeight
    }

    if (-not [System.String]::IsNullOrEmpty($priority))
    {
        $portRuleValues.HandlingPriority = [System.UInt32] $priority
    }

    return $portRuleValues
}
