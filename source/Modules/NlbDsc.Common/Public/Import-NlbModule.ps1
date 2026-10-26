<#
    .SYNOPSIS
        Imports the PowerShell module 'NetworkLoadBalancingClusters' into the
        global scope.

    .DESCRIPTION
        The DSC resources must not import 'NetworkLoadBalancingClusters' when the
        resource module is loaded, because the module does not exist until the
        Windows features 'NLB' and 'RSAT-NLB' are installed. Importing it at load
        time made every resource fail on a node where the feature had not been
        installed yet - even if the feature was installed by a previous resource
        in the same configuration.

        This function is called lazily by each resource function after the
        feature has been verified. The module is imported with -Global so the
        cmdlets are visible to the calling DSC resource also when the LCM runs
        the resource inside wmiprvse.exe.

    .OUTPUTS
        None

    .EXAMPLE
        Import-NlbModule

        Imports the NetworkLoadBalancingClusters module if it is not already imported.
#>
function Import-NlbModule
{
    [CmdletBinding()]
    [OutputType()]
    param ()

    if (Get-Module -Name 'NetworkLoadBalancingClusters')
    {
        return
    }

    if (-not (Get-Module -Name 'NetworkLoadBalancingClusters' -ListAvailable))
    {
        New-InvalidOperationException -Message $script:localizedData.ModuleNotAvailable
    }

    Write-Verbose -Message $script:localizedData.ImportingModule

    Import-Module -Name 'NetworkLoadBalancingClusters' -Global -Force -ErrorAction 'Stop'
}
