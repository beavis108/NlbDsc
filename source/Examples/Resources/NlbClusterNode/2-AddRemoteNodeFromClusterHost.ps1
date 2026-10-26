<#
    .DESCRIPTION
        This example shows how to add a remote node (web03) to the NLB cluster
        from an existing cluster host. The Windows feature NLB must already be
        installed on web03.
#>

configuration Example
{
    Import-DscResource -ModuleName 'NlbDsc'

    node localhost {

        NlbClusterNode AddWeb03 {
            NodeName          = 'web03.contoso.com'
            NodeInterfaceName = 'NLB'
            InterfaceName     = 'NLB'
            Ensure            = 'Present'
        }
    }
}
