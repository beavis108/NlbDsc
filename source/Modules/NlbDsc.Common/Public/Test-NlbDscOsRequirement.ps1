<#
    .SYNOPSIS
        Verifies that the operating system meets the minimum requirement of NlbDsc.

    .DESCRIPTION
        Returns $true when Get-NlbDscOsVersion reports at least Windows Server 2012
        (6.2.9200.0); otherwise returns $false.

    .OUTPUTS
        System.Boolean

    .EXAMPLE
        Test-NlbDscOsRequirement

        Returns $true if the OS is Windows Server 2012 or later, otherwise $false.
#>
function Test-NlbDscOsRequirement
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param ()

    return (Get-NlbDscOsVersion) -ge ([System.Version]::new(6, 2, 9200, 0))
}
