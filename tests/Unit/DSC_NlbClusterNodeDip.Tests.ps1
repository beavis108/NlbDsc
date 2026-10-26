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
    $script:dscResourceName = 'DSC_NlbClusterNodeDip'

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

Describe 'DSC_NlbClusterNodeDip\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        Mock -CommandName Import-NlbModule
        Mock -CommandName Test-NlbFeatureInstalled -MockWith { $true }
        Mock -CommandName Get-NlbDscCluster -MockWith { [PSCustomObject] @{ Name = 'web' } }
        Mock -CommandName Find-NlbClusterNode -MockWith { [PSCustomObject] @{ Name = 'web02' } }
        Mock -CommandName Get-NlbClusterNodeDip -MockWith {
            [PSCustomObject] @{ Node = 'web02'; IPAddress = '10.0.0.12'; SubnetMask = '255.255.255.0' }
        }
    }

    It 'Should return the dedicated IP address' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $result = Get-TargetResource -InterfaceName 'NLB' -IPAddress '10.0.0.12' -NodeName 'web02'

            $result.Ensure | Should -Be 'Present'
            $result.SubnetMask | Should -Be '255.255.255.0'
        }
    }

    It 'Should default NodeName to the local node' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Mock -CommandName Get-ComputerName -MockWith { 'web02' }

            (Get-TargetResource -InterfaceName 'NLB' -IPAddress '10.0.0.12').NodeName | Should -Be 'web02'
        }
    }
}

Describe 'DSC_NlbClusterNodeDip\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        Mock -CommandName Import-NlbModule
        Mock -CommandName Test-NlbFeatureInstalled -MockWith { $true }
        Mock -CommandName Get-NlbDscCluster -MockWith { [PSCustomObject] @{ Name = 'web' } }
        Mock -CommandName Get-NlbClusterNodeDip -MockWith {
            [PSCustomObject] @{ Node = 'web02'; IPAddress = '10.0.0.12'; SubnetMask = '255.255.255.0' }
        }
        Mock -CommandName Add-NlbClusterNodeDip
        Mock -CommandName Remove-NlbClusterNodeDip
    }

    Context 'When the node exists' {
        BeforeAll {
            Mock -CommandName Find-NlbClusterNode -MockWith { [PSCustomObject] @{ Name = 'web02' } }
        }

        It 'Should add a missing dedicated IP address' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource -InterfaceName 'NLB' -IPAddress '10.0.0.22' -NodeName 'web02' -SubnetMask '255.255.255.0'
            }

            Should -Invoke -CommandName Add-NlbClusterNodeDip -Exactly -Times 1 -Scope It -ParameterFilter { $IP -eq '10.0.0.22' }
        }

        It 'Should remove the dedicated IP address' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource -InterfaceName 'NLB' -IPAddress '10.0.0.12' -NodeName 'web02' -Ensure 'Absent'
            }

            Should -Invoke -CommandName Remove-NlbClusterNodeDip -Exactly -Times 1 -Scope It -ParameterFilter { $Force }
        }
    }

    Context 'When the node does not exist' {
        BeforeAll {
            Mock -CommandName Find-NlbClusterNode
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TargetResource -InterfaceName 'NLB' -IPAddress '10.0.0.22' -NodeName 'web09' } |
                    Should -Throw -ExpectedMessage ('*' + ($script:localizedData.NodeRequired -f 'web09', 'NLB') + '*')
            }
        }
    }
}

Describe 'DSC_NlbClusterNodeDip\Get-TargetResource (missing objects)' -Tag 'Get' {
    BeforeAll {
        Mock -CommandName Import-NlbModule
        Mock -CommandName Test-NlbFeatureInstalled -MockWith { $true }
        Mock -CommandName Get-NlbDscCluster -MockWith { [PSCustomObject] @{ Name = 'web' } }
        Mock -CommandName Find-NlbClusterNode -MockWith { [PSCustomObject] @{ Name = 'web02' } }
        Mock -CommandName Get-NlbClusterNodeDip -MockWith {
            [PSCustomObject] @{ Node = 'web02'; IPAddress = '10.0.0.12'; SubnetMask = '255.255.255.0' }
        }
    }

    It 'Should return Absent when <Case>' -ForEach @(
        @{ Case = 'the feature is not installed'; FeatureInstalled = $false; ClusterFound = $true; NodeFound = $true; IPAddress = '10.0.0.12' }
        @{ Case = 'the cluster does not exist'; FeatureInstalled = $true; ClusterFound = $false; NodeFound = $true; IPAddress = '10.0.0.12' }
        @{ Case = 'the node does not exist'; FeatureInstalled = $true; ClusterFound = $true; NodeFound = $false; IPAddress = '10.0.0.12' }
        @{ Case = 'the dedicated IP address does not exist'; FeatureInstalled = $true; ClusterFound = $true; NodeFound = $true; IPAddress = '10.0.0.99' }
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

        InModuleScope -Parameters @{ IPAddress = $IPAddress } -ScriptBlock {
            Set-StrictMode -Version 1.0

            $result = Get-TargetResource -InterfaceName 'NLB' -IPAddress $IPAddress -NodeName 'web02'

            $result.Ensure | Should -Be 'Absent'
            $result.SubnetMask | Should -BeNullOrEmpty
        }
    }
}

Describe 'DSC_NlbClusterNodeDip\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        Mock -CommandName Get-TargetResource -MockWith {
            @{ Ensure = 'Present'; SubnetMask = '255.255.255.0' }
        }
    }

    It 'Should return <Expected> for <Case>' -ForEach @(
        @{ Case = 'a present address'; Parameters = @{}; Expected = $true }
        @{ Case = 'the same subnet mask'; Parameters = @{ SubnetMask = '255.255.255.0' }; Expected = $true }
        @{ Case = 'a different subnet mask'; Parameters = @{ SubnetMask = '255.255.0.0' }; Expected = $false }
        @{ Case = 'Ensure Absent'; Parameters = @{ Ensure = 'Absent' }; Expected = $false }
    ) {
        InModuleScope -Parameters $_ -ScriptBlock {
            Set-StrictMode -Version 1.0

            Test-TargetResource -InterfaceName 'NLB' -IPAddress '10.0.0.12' -NodeName 'web02' @Parameters | Should -Be $Expected
        }
    }
}

Describe 'DSC_NlbClusterNodeDip\Set-TargetResource (additional cases)' -Tag 'Set' {
    BeforeAll {
        Mock -CommandName Import-NlbModule
        Mock -CommandName Test-NlbFeatureInstalled -MockWith { $true }
        Mock -CommandName Get-NlbDscCluster -MockWith { [PSCustomObject] @{ Name = 'web' } }
        Mock -CommandName Find-NlbClusterNode -MockWith { [PSCustomObject] @{ Name = 'web02' } }
        Mock -CommandName Get-NlbClusterNodeDip -MockWith {
            [PSCustomObject] @{ Node = 'web02'; IPAddress = '10.0.0.12'; SubnetMask = '255.255.255.0' }
        }
        Mock -CommandName Add-NlbClusterNodeDip
        Mock -CommandName Remove-NlbClusterNodeDip
        Mock -CommandName Get-ComputerName -MockWith { 'web02' }
    }

    It 'Should replace the dedicated IP address when the subnet mask differs' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Set-TargetResource -InterfaceName 'NLB' -IPAddress '10.0.0.12' -SubnetMask '255.255.0.0'
        }

        Should -Invoke -CommandName Get-ComputerName -Exactly -Times 1 -Scope It
        Should -Invoke -CommandName Remove-NlbClusterNodeDip -Exactly -Times 1 -Scope It
        Should -Invoke -CommandName Add-NlbClusterNodeDip -Exactly -Times 1 -Scope It -ParameterFilter { $SubnetMask -eq '255.255.0.0' }
    }

    It 'Should not throw when the node does not exist and the address should be absent' {
        Mock -CommandName Find-NlbClusterNode

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            { Set-TargetResource -InterfaceName 'NLB' -IPAddress '10.0.0.12' -NodeName 'web09' -Ensure 'Absent' } | Should -Not -Throw
        }

        Should -Invoke -CommandName Remove-NlbClusterNodeDip -Exactly -Times 0 -Scope It
    }

    It 'Should throw the correct error when the change fails' {
        Mock -CommandName Add-NlbClusterNodeDip -MockWith { throw 'The address is already in use.' }

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            { Set-TargetResource -InterfaceName 'NLB' -IPAddress '10.0.0.22' -NodeName 'web02' } |
                Should -Throw -ExpectedMessage ('*' + ($script:localizedData.ChangeDipFailed -f '10.0.0.22', 'web02') + '*')
        }
    }
}
