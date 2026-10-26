<#
    .SYNOPSIS
        Returns the value of the first property that exists on an object.

    .DESCRIPTION
        The objects returned by the NetworkLoadBalancingClusters module use
        different property names than the column headers of their default
        table view (for example the port rule column 'Mode' is the property
        'FilteringMode', 'IPAddress' is 'VirtualIPAddress' and 'State' is
        'PortState'). This function returns the value of the first property in
        Name that exists on the object, so the resources work with all known
        property names.

    .PARAMETER InputObject
        The object to read the property from.

    .PARAMETER Name
        The candidate property names, in order of preference.

    .OUTPUTS
        System.Object

    .EXAMPLE
        Get-NlbObjectPropertyValue -InputObject $portRule -Name 'FilteringMode', 'Mode'

        Returns the filtering mode of the port rule.
#>
function Get-NlbObjectPropertyValue
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [System.Object]
        $InputObject,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Name
    )

    if ($null -eq $InputObject)
    {
        return $null
    }

    foreach ($propertyName in $Name)
    {
        $property = $InputObject.PSObject.Properties[$propertyName]

        if ($null -ne $property)
        {
            return $property.Value
        }
    }

    return $null
}
