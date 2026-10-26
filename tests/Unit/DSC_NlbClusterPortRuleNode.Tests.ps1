# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
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
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
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
    $script:dscResourceName = 'DSC_NlbClusterPortRuleNode'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    # Load stub cmdlets.
    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs\NetworkLoadBalancingClusters.stubs.psm1')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscResourceName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    # Unload stub module
    Remove-Module -Name NetworkLoadBalancingClusters.stubs -Force

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force
}

Describe 'DSC_NlbClusterPortRuleNode\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        $script:defaultParameters = @{
            NodeName      = 'web01'
            InterfaceName = 'NLB'
            IPAddress     = 'All'
            StartPort     = 80
        }
    }

    Context 'When the port rule uses the filtering mode Multiple' {
        BeforeAll {
            Mock -CommandName Get-TargetResource -MockWith {
                @{ Mode = 'Multiple'; EqualLoad = $false; LoadWeight = [System.UInt32] 70; HandlingPriority = $null; State = 'Enabled' }
            }
        }

        It 'Should return <Expected> for <Name>' -ForEach @(
            @{ Name = 'LoadWeight 70'; Settings = @{ LoadWeight = 70 }; Expected = $true }
            @{ Name = 'LoadWeight 30'; Settings = @{ LoadWeight = 30 }; Expected = $false }
            @{ Name = 'EqualLoad'; Settings = @{ EqualLoad = $true }; Expected = $false }
            @{ Name = 'HandlingPriority (ignored)'; Settings = @{ HandlingPriority = 3 }; Expected = $true }
            @{ Name = 'State Disabled'; Settings = @{ State = 'Disabled' }; Expected = $false }
        ) {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters; settings = $Settings; expected = $Expected } -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters @settings | Should -Be $expected
            }
        }

        It 'Should throw when EqualLoad and LoadWeight are combined' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Test-TargetResource @testParameters -EqualLoad $true -LoadWeight 10 } |
                    Should -Throw -ExpectedMessage ('*' + $script:localizedData.EqualLoadAndLoadWeight + '*')
            }
        }
    }

    Context 'When the port rule does not exist' {
        BeforeAll {
            Mock -CommandName Get-TargetResource -MockWith { @{ Mode = $null } }
        }

        It 'Should return $false' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters -State 'Enabled' | Should -BeFalse
            }
        }
    }
}

Describe 'DSC_NlbClusterPortRuleNode\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        $script:defaultParameters = @{
            NodeName      = 'web01'
            InterfaceName = 'NLB'
            IPAddress     = 'All'
            StartPort     = 80
        }

        Mock -CommandName Set-NlbClusterPortRuleNodeWeight
        Mock -CommandName Set-NlbClusterPortRuleNodeHandlingPriority
        Mock -CommandName Enable-NlbClusterPortRule
        Mock -CommandName Disable-NlbClusterPortRule
    }

    Context 'When the port rule uses the filtering mode Multiple' {
        BeforeAll {
            Mock -CommandName Get-NlbDscNodePortRule -MockWith {
                [PSCustomObject] @{
                    VirtualIPAddress = '255.255.255.255'; StartPort = 0; EndPort = 65535; FilteringMode = 'Multiple'
                    Protocol = 'Both'; EqualLoad = 'True'; LoadWeight = ''; Priority = ''; PortState = 'Enabled'; Timeout = 0
                }
            }
        }

        It 'Should set the load weight' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource @testParameters -LoadWeight 70
            }

            Should -Invoke -CommandName Set-NlbClusterPortRuleNodeWeight -Exactly -Times 1 -Scope It -ParameterFilter { $LoadWeight -eq 70 -and -not $Equal }
        }

        It 'Should not set the handling priority' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource @testParameters -HandlingPriority 2
            }

            Should -Invoke -CommandName Set-NlbClusterPortRuleNodeHandlingPriority -Exactly -Times 0 -Scope It
        }

        It 'Should disable the port rule on the node with drain' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource @testParameters -State 'Disabled' -Drain $true -DrainTimeout 5
            }

            Should -Invoke -CommandName Disable-NlbClusterPortRule -Exactly -Times 1 -Scope It -ParameterFilter { $Drain -and $Timeout -eq 5 -and -not $ClusterWide }
        }
    }

    Context 'When the port rule uses the filtering mode Single' {
        BeforeAll {
            Mock -CommandName Get-NlbDscNodePortRule -MockWith {
                [PSCustomObject] @{
                    VirtualIPAddress = '255.255.255.255'; StartPort = 0; EndPort = 65535; FilteringMode = 'Single'
                    Protocol = 'Both'; EqualLoad = 'False'; LoadWeight = ''; Priority = 1; PortState = 'Enabled'; Timeout = ''
                }
            }
        }

        It 'Should set the handling priority' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource @testParameters -HandlingPriority 2
            }

            Should -Invoke -CommandName Set-NlbClusterPortRuleNodeHandlingPriority -Exactly -Times 1 -Scope It -ParameterFilter { $HandlingPriority -eq 2 }
        }
    }

    Context 'When the port rule does not exist' {
        BeforeAll {
            Mock -CommandName Get-NlbDscNodePortRule
        }

        It 'Should throw the correct error' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TargetResource @testParameters -State 'Enabled' } |
                    Should -Throw -ExpectedMessage ('*' + ($script:localizedData.PortRuleRequired -f 'All', 80, 'web01') + '*')
            }
        }
    }
}

Describe 'DSC_NlbClusterPortRuleNode\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        $script:defaultParameters = @{
            NodeName      = 'web01'
            InterfaceName = 'NLB'
            IPAddress     = 'All'
            StartPort     = 80
        }

        Mock -CommandName Import-NlbModule
        Mock -CommandName Test-NlbFeatureInstalled -MockWith { $true }
        Mock -CommandName Get-NlbDscCluster -MockWith { [PSCustomObject] @{ Name = 'web' } }
        Mock -CommandName Find-NlbClusterNode -MockWith { [PSCustomObject] @{ Name = 'web01' } }
        Mock -CommandName Find-NlbClusterPortRule -MockWith {
            [PSCustomObject] @{
                VirtualIPAddress = '255.255.255.255'; StartPort = 0; EndPort = 65535; FilteringMode = 'Multiple'
                Protocol = 'Both'; EqualLoad = 'False'; LoadWeight = 70; Priority = ''; PortState = 'Enabled'; Timeout = 0
            }
        }
    }

    It 'Should return the node specific settings of the port rule' {
        InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
            Set-StrictMode -Version 1.0

            $result = Get-TargetResource @testParameters

            $result.Mode | Should -Be 'Multiple'
            $result.EqualLoad | Should -BeFalse
            $result.LoadWeight | Should -Be 70
            $result.State | Should -Be 'Enabled'
            $result.HandlingPriority | Should -BeNullOrEmpty
        }
    }

    It 'Should return no settings when <Case>' -ForEach @(
        @{ Case = 'the feature is not installed'; FeatureInstalled = $false; ClusterFound = $true; NodeFound = $true; RuleFound = $true }
        @{ Case = 'the cluster does not exist'; FeatureInstalled = $true; ClusterFound = $false; NodeFound = $true; RuleFound = $true }
        @{ Case = 'the node does not exist'; FeatureInstalled = $true; ClusterFound = $true; NodeFound = $false; RuleFound = $true }
        @{ Case = 'the port rule does not exist'; FeatureInstalled = $true; ClusterFound = $true; NodeFound = $true; RuleFound = $false }
    ) {
        Mock -CommandName Test-NlbFeatureInstalled -MockWith { $FeatureInstalled }

        if (-not $ClusterFound)
        {
            Mock -CommandName Get-NlbDscCluster
        }

        if (-not $NodeFound)
        {
            Mock -CommandName Find-NlbClusterNode
        }

        if (-not $RuleFound)
        {
            Mock -CommandName Find-NlbClusterPortRule
        }

        InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
            Set-StrictMode -Version 1.0

            $result = Get-TargetResource @testParameters

            $result.Mode | Should -BeNullOrEmpty
            $result.State | Should -BeNullOrEmpty
            $result.NodeName | Should -Be 'web01'
        }
    }
}

Describe 'DSC_NlbClusterPortRuleNode\Set-TargetResource (additional cases)' -Tag 'Set' {
    BeforeAll {
        $script:defaultParameters = @{
            NodeName      = 'web01'
            InterfaceName = 'NLB'
            IPAddress     = 'All'
            StartPort     = 80
        }

        Mock -CommandName Set-NlbClusterPortRuleNodeWeight
        Mock -CommandName Set-NlbClusterPortRuleNodeHandlingPriority
        Mock -CommandName Enable-NlbClusterPortRule
        Mock -CommandName Disable-NlbClusterPortRule
        Mock -CommandName Get-NlbDscNodePortRule -MockWith {
            [PSCustomObject] @{
                VirtualIPAddress = '255.255.255.255'; StartPort = 0; EndPort = 65535; FilteringMode = 'Multiple'
                Protocol = 'Both'; EqualLoad = 'False'; LoadWeight = 70; Priority = ''; PortState = 'Disabled'; Timeout = 0
            }
        }
    }

    It 'Should set equal load distribution' {
        InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
            Set-StrictMode -Version 1.0

            Set-TargetResource @testParameters -EqualLoad $true
        }

        Should -Invoke -CommandName Set-NlbClusterPortRuleNodeWeight -Exactly -Times 1 -Scope It -ParameterFilter { $Equal }
    }

    It 'Should enable the port rule on the node' {
        InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
            Set-StrictMode -Version 1.0

            Set-TargetResource @testParameters -State 'Enabled'
        }

        Should -Invoke -CommandName Enable-NlbClusterPortRule -Exactly -Times 1 -Scope It
        Should -Invoke -CommandName Disable-NlbClusterPortRule -Exactly -Times 0 -Scope It
    }

    It 'Should throw when EqualLoad is $false without LoadWeight' {
        InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
            Set-StrictMode -Version 1.0

            { Set-TargetResource @testParameters -EqualLoad $false } |
                Should -Throw -ExpectedMessage ('*' + $script:localizedData.EqualLoadFalseRequiresLoadWeight + '*')
        }
    }

    It 'Should throw the correct error when the change fails' {
        Mock -CommandName Enable-NlbClusterPortRule -MockWith { throw 'The cluster is not reachable.' }

        InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
            Set-StrictMode -Version 1.0

            { Set-TargetResource @testParameters -State 'Enabled' } |
                Should -Throw -ExpectedMessage ('*' + ($script:localizedData.ChangeFailed -f 'web01') + '*')
        }
    }
}
