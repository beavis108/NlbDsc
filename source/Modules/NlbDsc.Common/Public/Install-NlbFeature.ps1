<#
    .SYNOPSIS
        Installs the Windows features required for Network Load Balancing.

    .DESCRIPTION
        Installs the Windows features 'NLB' and 'RSAT-NLB' (incl. the PowerShell
        module 'NetworkLoadBalancingClusters'). When the installation requires a
        restart, the DSC engine is told to restart the node by setting
        $global:DSCMachineStatus = 1 (through Set-DscMachineRebootRequired).

    .PARAMETER Name
        The names of the Windows features to install. Defaults to 'NLB' and 'RSAT-NLB'.

    .OUTPUTS
        System.Boolean

        Returns $true if a restart is required to complete the installation,
        otherwise $false.

    .EXAMPLE
        $restartRequired = Install-NlbFeature

        Installs the features and returns whether a restart is pending.
#>
function Install-NlbFeature
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $Name = @('NLB', 'RSAT-NLB')
    )

    if (-not (Get-Command -Name 'Install-WindowsFeature' -ErrorAction 'SilentlyContinue'))
    {
        New-InvalidOperationException -Message $script:localizedData.FeatureCmdletNotAvailable
    }

    $featureList = $Name -join "', '"

    Write-Verbose -Message ($script:localizedData.InstallingFeature -f $featureList)

    $installResult = Install-WindowsFeature -Name $Name -ErrorAction 'Stop'

    if (-not $installResult.Success)
    {
        New-InvalidOperationException -Message (
            $script:localizedData.InstallFeatureFailed -f $featureList, $installResult.ExitCode
        )
    }

    $restartRequired = [System.String] $installResult.RestartNeeded -eq 'Yes'

    if ($restartRequired)
    {
        Write-Warning -Message ($script:localizedData.InstallFeatureRestartRequired -f $featureList)

        Set-DscMachineRebootRequired
    }

    return $restartRequired
}
