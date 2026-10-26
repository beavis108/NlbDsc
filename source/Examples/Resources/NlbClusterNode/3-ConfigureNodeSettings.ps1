<#
    .DESCRIPTION
        This example shows how to add a node with host priority 2 that stays
        suspended after a restart when it was suspended before (for example
        during a maintenance window).
#>

configuration Example
{
    Import-DscResource -ModuleName 'NlbDsc'

    node localhost {

        NlbClusterNode Web02 {
            NodeName          = 'web02.contoso.com'
            NodeInterfaceName = 'NLB'
            HostName          = 'web01.contoso.com'
            InterfaceName     = 'NLB'
            HostPriority      = 2
            InitialHostState  = 'Started'
            RetainSuspended   = $true
        }
    }
}
