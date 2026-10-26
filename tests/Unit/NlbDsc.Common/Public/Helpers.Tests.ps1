[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies have been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies have not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'NlbDsc'
    $script:subModuleName = 'NlbDsc.Common'

    $script:parentModule = Get-Module -Name $script:dscModuleName -ListAvailable | Select-Object -First 1
    $script:subModulesFolder = Join-Path -Path $script:parentModule.ModuleBase -ChildPath 'Modules'

    $script:subModulePath = Join-Path -Path $script:subModulesFolder -ChildPath $script:subModuleName

    Import-Module -Name $script:subModulePath -Force -ErrorAction 'Stop'

    # Load stub cmdlets.
    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Stubs\ServerManager.stubs.psm1')
    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Stubs\NetworkLoadBalancingClusters.stubs.psm1')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:subModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:subModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:subModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Remove-Module -Name ServerManager.stubs -Force
    Remove-Module -Name NetworkLoadBalancingClusters.stubs -Force

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:subModuleName -All | Remove-Module -Force
}


Describe 'Get-NlbObjectPropertyValue' {
    It 'Should return the first existing property' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $object = [PSCustomObject] @{ FilteringMode = 'Single' }

            Get-NlbObjectPropertyValue -InputObject $object -Name 'Mode', 'FilteringMode' | Should -Be 'Single'
            Get-NlbObjectPropertyValue -InputObject $object -Name 'Unknown' | Should -BeNullOrEmpty
        }
    }
}

Describe 'ConvertTo-NlbCmdletIPAddress' {
    It 'Should return 255.255.255.255 for All' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            ConvertTo-NlbCmdletIPAddress -IPAddress 'All' | Should -Be '255.255.255.255'
            ConvertTo-NlbCmdletIPAddress -IPAddress '10.0.0.1' | Should -Be '10.0.0.1'
        }
    }
}

Describe 'ConvertTo-NlbNodeState' {
    It 'Should return <Expected> for <State>' -ForEach @(
        @{ State = 'Converged'; Expected = 'Started' }
        @{ State = 'Converged(default)'; Expected = 'Started' }
        @{ State = 'Converging'; Expected = 'Started' }
        @{ State = 'Stopped'; Expected = 'Stopped' }
        @{ State = 'Suspended'; Expected = 'Suspended' }
        @{ State = 'Draining'; Expected = 'Draining' }
        @{ State = 'Misconfigured'; Expected = 'Misconfigured' }
    ) {
        InModuleScope -Parameters $_ -ScriptBlock {
            Set-StrictMode -Version 1.0

            ConvertTo-NlbNodeState -State $State | Should -Be $Expected
        }
    }
}

Describe 'Test-NlbIPAddressEqual' {
    It 'Should return <Expected> for <A> and <B>' -ForEach @(
        @{ A = '2001:db8::1'; B = '2001:0DB8:0000::0001'; Expected = $true }
        @{ A = '10.0.0.1'; B = '10.0.0.1'; Expected = $true }
        @{ A = '10.0.0.1'; B = '10.0.0.2'; Expected = $false }
        @{ A = 'All'; B = 'all'; Expected = $true }
    ) {
        InModuleScope -Parameters $_ -ScriptBlock {
            Set-StrictMode -Version 1.0

            Test-NlbIPAddressEqual -ReferenceIPAddress $A -DifferenceIPAddress $B | Should -Be $Expected
        }
    }
}

Describe 'Get-NlbShortName' {
    It 'Should return the host name part' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Get-NlbShortName -Name 'web01.contoso.com' | Should -Be 'web01'
        }
    }
}

Describe 'Find-NlbClusterNode' {
    BeforeAll {
        Mock -CommandName Get-NlbClusterNode -MockWith {
            [PSCustomObject] @{ Name = 'WEB01' }
            [PSCustomObject] @{ Name = 'web02.contoso.com' }
        }
    }

    It 'Should match short and fully qualified names' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            (Find-NlbClusterNode -Cluster ([PSCustomObject] @{}) -NodeName 'web01.contoso.com').Name | Should -Be 'WEB01'
            (Find-NlbClusterNode -Cluster ([PSCustomObject] @{}) -NodeName 'web02').Name | Should -Be 'web02.contoso.com'
            Find-NlbClusterNode -Cluster ([PSCustomObject] @{}) -NodeName 'web03' | Should -BeNullOrEmpty
        }
    }
}

Describe 'Find-NlbClusterPortRule' {
    BeforeAll {
        Mock -CommandName Get-NlbClusterPortRule -MockWith {
            [PSCustomObject] @{ VirtualIPAddress = '255.255.255.255'; StartPort = 0; EndPort = 65535 }
            [PSCustomObject] @{ VirtualIPAddress = '255.255.255.255'; StartPort = 443; EndPort = 443 }
            [PSCustomObject] @{ VirtualIPAddress = '10.0.0.100'; StartPort = 80; EndPort = 80 }
        }
    }

    It 'Should prefer the rule that starts at the port' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            (Find-NlbClusterPortRule -InputObject ([PSCustomObject] @{}) -IPAddress 'All' -StartPort 443).EndPort | Should -Be 443
        }
    }

    It 'Should return the rule that covers the port' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            (Find-NlbClusterPortRule -InputObject ([PSCustomObject] @{}) -IPAddress 'All' -StartPort 80).EndPort | Should -Be 65535
        }
    }

    It 'Should match the cluster IP address' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            (Find-NlbClusterPortRule -InputObject ([PSCustomObject] @{}) -IPAddress '10.0.0.100' -StartPort 80).StartPort | Should -Be 80
            Find-NlbClusterPortRule -InputObject ([PSCustomObject] @{}) -IPAddress '10.0.0.100' -StartPort 81 | Should -BeNullOrEmpty
        }
    }
}

Describe 'ConvertFrom-NlbPortRule' {
    It 'Should read the documented property names of a node specific port rule' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $portRule = [PSCustomObject] @{
                VirtualIPAddress = '255.255.255.255'; StartPort = 0; EndPort = 65535; Affinity = 'Single'
                FilteringMode = 'Multiple'; Protocol = 'Both'; EqualLoad = 'False'; LoadWeight = 25
                PortState = 'Enabled'; Priority = ''; Timeout = 0
            }

            $result = ConvertFrom-NlbPortRule -PortRule $portRule

            $result.IPAddress | Should -Be 'All'
            $result.Mode | Should -BeExactly 'Multiple'
            $result.State | Should -BeExactly 'Enabled'
            $result.EqualLoad | Should -BeFalse
            $result.LoadWeight | Should -Be 25
            $result.HandlingPriority | Should -BeNullOrEmpty
        }
    }
}
