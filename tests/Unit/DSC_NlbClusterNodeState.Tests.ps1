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
    $script:dscResourceName = 'DSC_NlbClusterNodeState'

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

Describe 'DSC_NlbClusterNodeState\Test-TargetResource' -Tag 'Test' {
    It 'Should return <Expected> when the node is <Current> and <Desired> is desired' -ForEach @(
        @{ Current = 'Converged'; Desired = 'Started'; Expected = $true }
        @{ Current = 'Converged(default)'; Desired = 'Started'; Expected = $true }
        @{ Current = 'Draining'; Desired = 'Stopped'; Expected = $true }
        @{ Current = 'Stopped'; Desired = 'Started'; Expected = $false }
        @{ Current = 'Suspended'; Desired = 'Stopped'; Expected = $false }
    ) {
        InModuleScope -Parameters $_ -ScriptBlock {
            Set-StrictMode -Version 1.0

            Mock -CommandName Get-NlbDscClusterNode -MockWith { [PSCustomObject] @{ Name = 'web02'; State = $Current } }

            Test-TargetResource -NodeName 'web02' -InterfaceName 'NLB' -State $Desired | Should -Be $Expected
        }
    }
}

Describe 'DSC_NlbClusterNodeState\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        Mock -CommandName Start-NlbClusterNode
        Mock -CommandName Stop-NlbClusterNode
        Mock -CommandName Suspend-NlbClusterNode
        Mock -CommandName Resume-NlbClusterNode
    }

    It 'Should resume and start a suspended node' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Mock -CommandName Get-NlbDscClusterNode -MockWith { [PSCustomObject] @{ Name = 'web02'; State = 'Suspended' } }

            Set-TargetResource -NodeName 'web02' -InterfaceName 'NLB' -State 'Started'
        }

        Should -Invoke -CommandName Resume-NlbClusterNode -Exactly -Times 1 -Scope It
        Should -Invoke -CommandName Start-NlbClusterNode -Exactly -Times 1 -Scope It
    }

    It 'Should only resume a suspended node that should be stopped' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Mock -CommandName Get-NlbDscClusterNode -MockWith { [PSCustomObject] @{ Name = 'web02'; State = 'Suspended' } }

            Set-TargetResource -NodeName 'web02' -InterfaceName 'NLB' -State 'Stopped'
        }

        Should -Invoke -CommandName Resume-NlbClusterNode -Exactly -Times 1 -Scope It
        Should -Invoke -CommandName Stop-NlbClusterNode -Exactly -Times 0 -Scope It
    }

    It 'Should stop a running node with drain' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Mock -CommandName Get-NlbDscClusterNode -MockWith { [PSCustomObject] @{ Name = 'web02'; State = 'Converged' } }

            Set-TargetResource -NodeName 'web02' -InterfaceName 'NLB' -State 'Stopped' -Drain $true -DrainTimeout 120
        }

        Should -Invoke -CommandName Stop-NlbClusterNode -Exactly -Times 1 -Scope It -ParameterFilter { $Drain -and $Timeout -eq 120 }
    }

    It 'Should throw when the node does not exist' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Mock -CommandName Get-NlbDscClusterNode

            { Set-TargetResource -NodeName 'web09' -InterfaceName 'NLB' -State 'Started' } |
                Should -Throw -ExpectedMessage ('*' + ($script:localizedData.NodeRequired -f 'web09', 'NLB') + '*')
        }
    }
}

Describe 'DSC_NlbClusterNodeState\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        Mock -CommandName Import-NlbModule
        Mock -CommandName Test-NlbFeatureInstalled -MockWith { $true }
        Mock -CommandName Get-NlbDscCluster -MockWith { [PSCustomObject] @{ Name = 'web' } }
        Mock -CommandName Find-NlbClusterNode -MockWith { [PSCustomObject] @{ Name = 'web02'; State = 'Converged' } }
    }

    It 'Should return the host state of the node' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $result = Get-TargetResource -NodeName 'web02' -InterfaceName 'NLB' -State 'Started'

            $result.State | Should -Be 'Started'
            $result.CurrentState | Should -Be 'Converged'
        }
    }

    It 'Should return no state when <Case>' -ForEach @(
        @{ Case = 'the feature is not installed'; FeatureInstalled = $false; ClusterFound = $true; NodeFound = $true }
        @{ Case = 'the cluster does not exist'; FeatureInstalled = $true; ClusterFound = $false; NodeFound = $true }
        @{ Case = 'the node does not exist'; FeatureInstalled = $true; ClusterFound = $true; NodeFound = $false }
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

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $result = Get-TargetResource -NodeName 'web02' -InterfaceName 'NLB' -State 'Started'

            $result.State | Should -BeNullOrEmpty
            $result.CurrentState | Should -BeNullOrEmpty
        }
    }
}

Describe 'DSC_NlbClusterNodeState\Set-TargetResource (additional cases)' -Tag 'Set' {
    BeforeAll {
        Mock -CommandName Start-NlbClusterNode
        Mock -CommandName Stop-NlbClusterNode
        Mock -CommandName Suspend-NlbClusterNode
        Mock -CommandName Resume-NlbClusterNode
    }

    It 'Should suspend a running node' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Mock -CommandName Get-NlbDscClusterNode -MockWith { [PSCustomObject] @{ Name = 'web02'; State = 'Converged' } }

            Set-TargetResource -NodeName 'web02' -InterfaceName 'NLB' -State 'Suspended'
        }

        Should -Invoke -CommandName Suspend-NlbClusterNode -Exactly -Times 1 -Scope It
    }

    It 'Should not suspend a suspended node again' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Mock -CommandName Get-NlbDscClusterNode -MockWith { [PSCustomObject] @{ Name = 'web02'; State = 'Suspended' } }

            Set-TargetResource -NodeName 'web02' -InterfaceName 'NLB' -State 'Suspended'
        }

        Should -Invoke -CommandName Suspend-NlbClusterNode -Exactly -Times 0 -Scope It
    }

    It 'Should throw the correct error when the change fails' {
        Mock -CommandName Start-NlbClusterNode -MockWith { throw 'The node is not reachable.' }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Mock -CommandName Get-NlbDscClusterNode -MockWith { [PSCustomObject] @{ Name = 'web02'; State = 'Stopped' } }

            { Set-TargetResource -NodeName 'web02' -InterfaceName 'NLB' -State 'Started' } |
                Should -Throw -ExpectedMessage ('*' + ($script:localizedData.ChangeStateFailed -f 'web02', 'Started') + '*')
        }
    }
}
