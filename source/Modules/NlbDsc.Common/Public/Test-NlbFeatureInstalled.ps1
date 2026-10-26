<#
    .SYNOPSIS
        Tests whether the Windows features required for Network Load Balancing
        are installed on the local node.

    .DESCRIPTION
        Network Load Balancing needs two Windows features:

        - 'NLB' (the Network Load Balancing service and driver).
        - 'RSAT-NLB' (the management tools, which contain the PowerShell module
          'NetworkLoadBalancingClusters' used by all NlbDsc resources).

        The function never throws. It returns $false when Get-WindowsFeature is
        not available (for example on a client operating system) or when at least
        one of the features is not installed.

    .PARAMETER Name
        The names of the Windows features to test. Defaults to 'NLB' and 'RSAT-NLB'.

    .OUTPUTS
        System.Boolean

    .EXAMPLE
        Test-NlbFeatureInstalled

        Returns $true if both 'NLB' and 'RSAT-NLB' are installed.
#>
function Test-NlbFeatureInstalled
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

    if (-not (Get-Command -Name 'Get-WindowsFeature' -ErrorAction 'SilentlyContinue'))
    {
        Write-Verbose -Message $script:localizedData.FeatureCmdletNotAvailable

        return $false
    }

    $windowsFeatures = @(Get-WindowsFeature -Name $Name -ErrorAction 'SilentlyContinue')

    foreach ($featureName in $Name)
    {
        $windowsFeature = $windowsFeatures | Where-Object -FilterScript {
            $_.Name -eq $featureName
        }

        if (-not $windowsFeature -or -not $windowsFeature.Installed)
        {
            Write-Verbose -Message ($script:localizedData.FeatureNotInstalled -f $featureName)

            return $false
        }
    }

    Write-Verbose -Message $script:localizedData.FeatureInstalled

    return $true
}
