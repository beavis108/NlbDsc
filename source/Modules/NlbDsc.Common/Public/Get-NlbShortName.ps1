<#
    .SYNOPSIS
        Returns the host name part of a (fully qualified) computer name.

    .PARAMETER Name
        The computer name.

    .OUTPUTS
        System.String

    .EXAMPLE
        Get-NlbShortName -Name 'web01.contoso.com'

        Returns 'web01'.
#>
function Get-NlbShortName
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [AllowNull()]
        [AllowEmptyString()]
        [System.String]
        $Name
    )

    if ([System.String]::IsNullOrWhiteSpace($Name))
    {
        return $Name
    }

    return ($Name.Trim() -split '\.')[0]
}
