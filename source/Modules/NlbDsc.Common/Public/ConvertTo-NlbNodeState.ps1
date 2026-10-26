<#
    .SYNOPSIS
        Converts the state reported by Get-NlbClusterNode to a host state.

    .DESCRIPTION
        Get-NlbClusterNode reports states such as 'Converged',
        'Converged(default)', 'Converging', 'Draining', 'Stopped' or
        'Suspended'. This function maps them to the host states used by the
        resources: 'Started' (Converged, Converging), 'Stopped', 'Suspended'
        and 'Draining'. Any other value is returned unchanged.

    .PARAMETER State
        The state reported by Get-NlbClusterNode.

    .OUTPUTS
        System.String

    .EXAMPLE
        ConvertTo-NlbNodeState -State 'Converged(default)'

        Returns 'Started'.
#>
function ConvertTo-NlbNodeState
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [AllowNull()]
        [AllowEmptyString()]
        [System.String]
        $State
    )

    $value = ([System.String] $State).Trim()

    switch -Regex ($value)
    {
        '^Converg'
        {
            return 'Started'
        }

        '^Stopped'
        {
            return 'Stopped'
        }

        '^Suspended'
        {
            return 'Suspended'
        }

        '^Drain'
        {
            return 'Draining'
        }

        default
        {
            return $value
        }
    }
}
