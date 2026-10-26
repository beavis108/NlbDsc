<#
    .DESCRIPTION
        This example shows how a node joins an existing NLB cluster. The
        configuration is applied to the joining node (web02); HostName is an
        existing cluster host. The Windows features NLB and RSAT-NLB are
        installed automatically on the joining node when they are missing.
#>

configuration Example
{
    Import-DscResource -ModuleName 'NlbDsc'

    node localhost {

        NlbClusterNode JoinWebCluster {
            NodeName          = 'web02.contoso.com'
            NodeInterfaceName = 'NLB'
            HostName          = 'web01.contoso.com'
            InterfaceName     = 'NLB'
            Ensure            = 'Present'
        }
    }
}
