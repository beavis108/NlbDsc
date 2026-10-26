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
    $script:dscResourceName = 'DSC_NlbClusterState'

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

Describe 'DSC_NlbClusterState\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        Mock -CommandName Import-NlbModule
        Mock -CommandName Test-NlbFeatureInstalled -MockWith { $true }
        Mock -CommandName Get-NlbDscCluster -MockWith { [PSCustomObject] @{ Name = 'web' } }
        Mock -CommandName Get-NlbClusterNode -MockWith {
            [PSCustomObject] @{ Name = 'web01'; State = 'Converged' }
            [PSCustomObject] @{ Name = 'web02'; State = 'Suspended' }
        }
    }

    It 'Should return the state of every node and Mixed' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $result = Get-TargetResource -InterfaceName 'NLB' -State 'Started'

            $result.NodeStates | Should -Be @('web01=Started', 'web02=Suspended')
            $result.State | Should -Be 'Mixed'
        }
    }
}

Describe 'DSC_NlbClusterState\Test-TargetResource' -Tag 'Test' {
    It 'Should return <Expected> for node states <NodeStates> and desired state <Desired>' -ForEach @(
        @{ NodeStates = @('a=Started', 'b=Started'); Desired = 'Started'; Expected = $true }
        @{ NodeStates = @('a=Stopped', 'b=Draining'); Desired = 'Stopped'; Expected = $true }
        @{ NodeStates = @('a=Started', 'b=Suspended'); Desired = 'Started'; Expected = $false }
        @{ NodeStates = @(); Desired = 'Started'; Expected = $false }
    ) {
        InModuleScope -Parameters $_ -ScriptBlock {
            Set-StrictMode -Version 1.0

            Mock -CommandName Get-TargetResource -MockWith { @{ NodeStates = [System.String[]] $NodeStates } }

            Test-TargetResource -InterfaceName 'NLB' -State $Desired | Should -Be $Expected
        }
    }
}

Describe 'DSC_NlbClusterState\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        Mock -CommandName Import-NlbModule
        Mock -CommandName Test-NlbFeatureInstalled -MockWith { $true }
        Mock -CommandName Get-NlbDscCluster -MockWith { [PSCustomObject] @{ Name = 'web' } }
        Mock -CommandName Get-NlbClusterNode -MockWith {
            [PSCustomObject] @{ Name = 'web01'; State = 'Converged' }
            [PSCustomObject] @{ Name = 'web02'; State = 'Suspended' }
        }
        Mock -CommandName Start-NlbCluster
        Mock -CommandName Stop-NlbCluster
        Mock -CommandName Suspend-NlbCluster
        Mock -CommandName Resume-NlbCluster
    }

    It 'Should resume and start the cluster' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Set-TargetResource -InterfaceName 'NLB' -State 'Started'
        }

        Should -Invoke -CommandName Resume-NlbCluster -Exactly -Times 1 -Scope It
        Should -Invoke -CommandName Start-NlbCluster -Exactly -Times 1 -Scope It
    }

    It 'Should resume and stop the cluster with drain' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Set-TargetResource -InterfaceName 'NLB' -State 'Stopped' -Drain $true -DrainTimeout 15
        }

        Should -Invoke -CommandName Resume-NlbCluster -Exactly -Times 1 -Scope It
        Should -Invoke -CommandName Stop-NlbCluster -Exactly -Times 1 -Scope It -ParameterFilter { $Drain -and $Timeout -eq 15 }
    }

    It 'Should suspend the cluster' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Set-TargetResource -InterfaceName 'NLB' -State 'Suspended'
        }

        Should -Invoke -CommandName Suspend-NlbCluster -Exactly -Times 1 -Scope It
        Should -Invoke -CommandName Resume-NlbCluster -Exactly -Times 0 -Scope It
    }
}
