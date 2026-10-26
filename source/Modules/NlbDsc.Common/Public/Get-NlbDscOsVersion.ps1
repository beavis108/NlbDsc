<#
    .SYNOPSIS
        Returns the version of the operating system.

    .DESCRIPTION
        Returns the version of the operating system as a System.Version object.
        Wrapped in a function so the value can be mocked in unit tests.

    .OUTPUTS
        System.Version

    .EXAMPLE
        Get-NlbDscOsVersion

        Returns for example 10.0.20348.0 on Windows Server 2022.
#>
function Get-NlbDscOsVersion
{
    [CmdletBinding()]
    [OutputType([System.Version])]
    param ()

    return [System.Environment]::OSVersion.Version
}
