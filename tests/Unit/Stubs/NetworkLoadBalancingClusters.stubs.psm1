# Name: NetworkLoadBalancingClusters
# Generated from the official cmdlet documentation (windows-powershell-docs, winserver2025-ps).
# Hand-maintained stubs, see README.md.

function Add-NlbClusterNode
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NlbClusterNode,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [System.String]
        $InterfaceName,

        [Parameter()]
        [System.String]
        $NewNodeName,

        [Parameter()]
        [System.String]
        $NewNodeInterface,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force,

        [Parameter(ValueFromPipeline = $true)]
        [System.Object[]]
        $InputObject
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Add-NlbClusterNodeDip
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NlbClusterNodeDip,

        [Parameter()]
        [System.Object]
        $IP,

        [Parameter()]
        [System.Object]
        $SubnetMask,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [System.String]
        $InterfaceName,

        [Parameter(ValueFromPipeline = $true)]
        [System.Object[]]
        $InputObject
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Add-NlbClusterPortRule
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NlbClusterPortRule,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [System.String]
        $InterfaceName,

        [Parameter()]
        [System.Object]
        $IP,

        [Parameter()]
        [System.Object]
        $Protocol,

        [Parameter()]
        [System.Int32]
        $StartPort,

        [Parameter()]
        [System.Int32]
        $EndPort,

        [Parameter()]
        [System.Object]
        $Mode,

        [Parameter()]
        [System.Object]
        $Affinity,

        [Parameter()]
        [System.UInt32]
        $Timeout,

        [Parameter(ValueFromPipeline = $true)]
        [System.Object[]]
        $InputObject
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Add-NlbClusterVip
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NlbClusterVip,

        [Parameter()]
        [System.Object]
        $IP,

        [Parameter()]
        [System.Object]
        $SubnetMask,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [System.String]
        $InterfaceName,

        [Parameter(ValueFromPipeline = $true)]
        [System.Object[]]
        $InputObject
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Disable-NlbClusterPortRule
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NlbClusterPortRule,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Drain,

        [Parameter()]
        [System.UInt32]
        $Timeout,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $ClusterWide,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [System.String]
        $InterfaceName,

        [Parameter()]
        [System.Object]
        $IP,

        [Parameter()]
        [System.UInt32]
        $Port,

        [Parameter(ValueFromPipeline = $true)]
        [System.Object[]]
        $InputObject
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Enable-NlbClusterPortRule
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NlbClusterPortRule,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $ClusterWide,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [System.String]
        $InterfaceName,

        [Parameter()]
        [System.Object]
        $IP,

        [Parameter()]
        [System.UInt32]
        $Port,

        [Parameter(ValueFromPipeline = $true)]
        [System.Object[]]
        $InputObject
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Get-NlbCluster
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NlbCluster,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [System.String]
        $InterfaceName
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Get-NlbClusterDriverInfo
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NlbClusterDriverInfo,

        [Parameter()]
        [System.String]
        $InterfaceName,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Params,

        [Parameter()]
        [System.Object]
        $Filter,

        [Parameter()]
        [System.Object]
        $ClientIP,

        [Parameter()]
        [System.Int32]
        $ClientPort,

        [Parameter()]
        [System.Object]
        $ServerIP,

        [Parameter()]
        [System.Int32]
        $ServerPort,

        [Parameter()]
        [System.Object]
        $Flags,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $ConvergenceHistory,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $ExtendedAffinityList,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $ExtendedAffinityExceptionList,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $OpenConnections
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Get-NlbClusterNode
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NlbClusterNode,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [System.String]
        $InterfaceName,

        [Parameter()]
        [System.String]
        $NodeName,

        [Parameter(ValueFromPipeline = $true)]
        [System.Object[]]
        $InputObject
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Get-NlbClusterNodeDip
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NlbClusterNodeDip,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [System.String]
        $InterfaceName,

        [Parameter()]
        [System.String]
        $NodeName,

        [Parameter()]
        [System.Object]
        $IP,

        [Parameter(ValueFromPipeline = $true)]
        [System.Object[]]
        $InputObject
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Get-NlbClusterNodeNetworkInterface
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NlbClusterNodeNetworkInterface,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [System.String]
        $InterfaceName,

        [Parameter(ValueFromPipeline = $true)]
        [System.Object[]]
        $InputObject
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Get-NlbClusterPortRule
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NlbClusterPortRule,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [System.String]
        $InterfaceName,

        [Parameter()]
        [System.Object]
        $IP,

        [Parameter()]
        [System.UInt32]
        $Port,

        [Parameter()]
        [System.String]
        $NodeName,

        [Parameter(ValueFromPipeline = $true)]
        [System.Object[]]
        $InputObject
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Get-NlbClusterVip
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NlbClusterVip,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [System.String]
        $InterfaceName,

        [Parameter()]
        [System.Object]
        $IP,

        [Parameter(ValueFromPipeline = $true)]
        [System.Object[]]
        $InputObject
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function New-NlbCluster
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NlbCluster,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [System.String]
        $InterfaceName,

        [Parameter()]
        [System.String]
        $ClusterName,

        [Parameter()]
        [System.Object]
        $ClusterPrimaryIP,

        [Parameter()]
        [System.Object]
        $SubnetMask,

        [Parameter()]
        [System.Object]
        $DedicatedIP,

        [Parameter()]
        [System.Object]
        $DedicatedIPSubnetMask,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force,

        [Parameter()]
        [System.Object]
        $OperationMode
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function New-NlbClusterIpv6Address
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NlbClusterIpv6Address,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [System.String]
        $InterfaceName,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $LinkLocal,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Global
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Remove-NlbCluster
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NlbCluster,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [System.String]
        $InterfaceName,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force,

        [Parameter(ValueFromPipeline = $true)]
        [System.Object[]]
        $InputObject
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Remove-NlbClusterNode
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NlbClusterNode,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [System.String]
        $InterfaceName,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force,

        [Parameter(ValueFromPipeline = $true)]
        [System.Object[]]
        $InputObject
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Remove-NlbClusterNodeDip
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NlbClusterNodeDip,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [System.String]
        $InterfaceName,

        [Parameter()]
        [System.Object]
        $IP,

        [Parameter(ValueFromPipeline = $true)]
        [System.Object[]]
        $InputObject
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Remove-NlbClusterPortRule
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NlbClusterPortRule,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [System.String]
        $InterfaceName,

        [Parameter()]
        [System.Object]
        $IP,

        [Parameter()]
        [System.UInt32]
        $Port,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force,

        [Parameter(ValueFromPipeline = $true)]
        [System.Object[]]
        $InputObject
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Remove-NlbClusterVip
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NlbClusterVip,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [System.String]
        $InterfaceName,

        [Parameter()]
        [System.Object]
        $IP,

        [Parameter(ValueFromPipeline = $true)]
        [System.Object[]]
        $InputObject
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Resume-NlbCluster
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NlbCluster,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [System.String]
        $InterfaceName,

        [Parameter(ValueFromPipeline = $true)]
        [System.Object[]]
        $InputObject
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Resume-NlbClusterNode
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NlbClusterNode,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [System.String]
        $InterfaceName,

        [Parameter(ValueFromPipeline = $true)]
        [System.Object[]]
        $InputObject
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Set-NlbCluster
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NlbCluster,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [System.String]
        $InterfaceName,

        [Parameter()]
        [System.Object]
        $ClusterPrimaryIP,

        [Parameter()]
        [System.String]
        $Name,

        [Parameter()]
        [System.Object]
        $OperationMode,

        [Parameter(ValueFromPipeline = $true)]
        [System.Object[]]
        $InputObject
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Set-NlbClusterNode
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NlbClusterNode,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [System.String]
        $InterfaceName,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Reload,

        [Parameter()]
        [System.Int32]
        $HostPriority,

        [Parameter()]
        [System.Object]
        $InitialHostState,

        [Parameter()]
        [System.Boolean]
        $RetainSuspended,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force,

        [Parameter(ValueFromPipeline = $true)]
        [System.Object[]]
        $InputObject
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Set-NlbClusterNodeDip
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NlbClusterNodeDip,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [System.String]
        $InterfaceName,

        [Parameter()]
        [System.Object]
        $IP,

        [Parameter()]
        [System.Object]
        $NewDip,

        [Parameter(ValueFromPipeline = $true)]
        [System.Object[]]
        $InputObject
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Set-NlbClusterPortRule
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NlbClusterPortRule,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [System.String]
        $InterfaceName,

        [Parameter()]
        [System.Object]
        $IP,

        [Parameter()]
        [System.UInt32]
        $Port,

        [Parameter()]
        [System.Object]
        $NewIP,

        [Parameter()]
        [System.Object]
        $NewProtocol,

        [Parameter()]
        [System.Int32]
        $NewStartPort,

        [Parameter()]
        [System.Int32]
        $NewEndPort,

        [Parameter()]
        [System.Object]
        $NewMode,

        [Parameter()]
        [System.Object]
        $NewAffinity,

        [Parameter()]
        [System.UInt32]
        $NewTimeout,

        [Parameter(ValueFromPipeline = $true)]
        [System.Object[]]
        $InputObject
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Set-NlbClusterPortRuleNodeHandlingPriority
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NlbClusterPortRuleNodeHandlingPriority,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [System.String]
        $InterfaceName,

        [Parameter()]
        [System.Object]
        $IP,

        [Parameter()]
        [System.UInt32]
        $Port,

        [Parameter()]
        [System.Int32]
        $HandlingPriority,

        [Parameter(ValueFromPipeline = $true)]
        [System.Object[]]
        $InputObject
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Set-NlbClusterPortRuleNodeWeight
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NlbClusterPortRuleNodeWeight,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [System.String]
        $InterfaceName,

        [Parameter()]
        [System.Object]
        $IP,

        [Parameter()]
        [System.UInt32]
        $Port,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Equal,

        [Parameter()]
        [System.Int32]
        $LoadWeight,

        [Parameter(ValueFromPipeline = $true)]
        [System.Object[]]
        $InputObject
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Set-NlbClusterVip
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NlbClusterVip,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [System.String]
        $InterfaceName,

        [Parameter()]
        [System.Object]
        $IP,

        [Parameter()]
        [System.Object]
        $NewIP,

        [Parameter(ValueFromPipeline = $true)]
        [System.Object[]]
        $InputObject
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Start-NlbCluster
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NlbCluster,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [System.String]
        $InterfaceName,

        [Parameter(ValueFromPipeline = $true)]
        [System.Object[]]
        $InputObject
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Start-NlbClusterNode
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NlbClusterNode,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [System.String]
        $InterfaceName,

        [Parameter(ValueFromPipeline = $true)]
        [System.Object[]]
        $InputObject
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Stop-NlbCluster
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NlbCluster,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Drain,

        [Parameter()]
        [System.UInt32]
        $Timeout,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [System.String]
        $InterfaceName,

        [Parameter(ValueFromPipeline = $true)]
        [System.Object[]]
        $InputObject
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Stop-NlbClusterNode
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NlbClusterNode,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Drain,

        [Parameter()]
        [System.UInt32]
        $Timeout,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [System.String]
        $InterfaceName,

        [Parameter(ValueFromPipeline = $true)]
        [System.Object[]]
        $InputObject
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Suspend-NlbCluster
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NlbCluster,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [System.String]
        $InterfaceName,

        [Parameter(ValueFromPipeline = $true)]
        [System.Object[]]
        $InputObject
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}

function Suspend-NlbClusterNode
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NlbClusterNode,

        [Parameter()]
        [System.String]
        $HostName,

        [Parameter()]
        [System.String]
        $InterfaceName,

        [Parameter(ValueFromPipeline = $true)]
        [System.Object[]]
        $InputObject
    )

    process
    {
        throw ('{0}: StubNotImplemented' -f $MyInvocation.MyCommand)
    }
}
