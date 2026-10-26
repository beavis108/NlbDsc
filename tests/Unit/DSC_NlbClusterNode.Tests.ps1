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
    $script:dscResourceName = 'DSC_NlbClusterNode'

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

Describe 'DSC_NlbClusterNode\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        $script:defaultParameters = @{
            NodeName          = 'web02.contoso.com'
            NodeInterfaceName = 'NLB'
            InterfaceName     = 'NLB'
            HostName          = 'web01.contoso.com'
        }

        Mock -CommandName Import-NlbModule
    }

    Context 'When the NLB feature is not installed' {
        BeforeAll {
            Mock -CommandName Test-NlbFeatureInstalled -MockWith { $false }
        }

        It 'Should return Ensure Absent' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                (Get-TargetResource @testParameters).Ensure | Should -Be 'Absent'
            }
        }
    }

    Context 'When the node is a member of the cluster' {
        BeforeAll {
            Mock -CommandName Test-NlbFeatureInstalled -MockWith { $true }
            Mock -CommandName Get-NlbDscCluster -MockWith { [PSCustomObject] @{ Name = 'web' } }
            Mock -CommandName Find-NlbClusterNode -MockWith {
                [PSCustomObject] @{
                    Name                   = 'WEB02'
                    State                  = 'Converged'
                    InterfaceName          = 'NLB'
                    HostPriority           = 2
                    InitialHostState       = 'Started'
                    PersistSuspendOnReboot = $true
                }
            }
        }

        It 'Should return Ensure Present and the state' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @testParameters

                $result.Ensure | Should -Be 'Present'
                $result.State | Should -Be 'Converged'
                $result.HostPriority | Should -Be 2
                $result.InitialHostState | Should -Be 'Started'
                $result.RetainSuspended | Should -BeTrue
            }
        }
    }

    Context 'When the node is not a member of the cluster' {
        BeforeAll {
            Mock -CommandName Test-NlbFeatureInstalled -MockWith { $true }
            Mock -CommandName Get-NlbDscCluster -MockWith { [PSCustomObject] @{ Name = 'web' } }
            Mock -CommandName Find-NlbClusterNode
        }

        It 'Should return Ensure Absent' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                (Get-TargetResource @testParameters).Ensure | Should -Be 'Absent'
            }
        }
    }
}

Describe 'DSC_NlbClusterNode\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        $script:defaultParameters = @{
            NodeName          = 'web02'
            NodeInterfaceName = 'NLB'
            InterfaceName     = 'NLB'
        }
    }

    Context 'When the node is a member of the cluster' {
        BeforeAll {
            Mock -CommandName Get-TargetResource -MockWith { @{ Ensure = 'Present' } }
        }

        It 'Should return $true (regression test for the inverted result of xNLBAddAdditionalNode)' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeTrue
            }
        }

        It 'Should return $false when Ensure is Absent' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters -Ensure 'Absent' | Should -BeFalse
            }
        }
    }

    Context 'When the node is not a member of the cluster' {
        BeforeAll {
            Mock -CommandName Get-TargetResource -MockWith { @{ Ensure = 'Absent' } }
        }

        It 'Should return $false' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeFalse
            }
        }
    }
}

Describe 'DSC_NlbClusterNode\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        $script:defaultParameters = @{
            NodeName          = 'web02.contoso.com'
            NodeInterfaceName = 'NLB'
            InterfaceName     = 'NLB'
            HostName          = 'web01.contoso.com'
        }

        Mock -CommandName Import-NlbModule
        Mock -CommandName Add-NlbClusterNode
        Mock -CommandName Remove-NlbClusterNode
        Mock -CommandName Set-NlbClusterNode
    }

    Context 'When the NLB feature is not installed on the joining node' {
        BeforeAll {
            Mock -CommandName Test-NlbFeatureInstalled -MockWith { $false }
            Mock -CommandName Install-NlbFeature -MockWith { $false }
            Mock -CommandName Get-NlbDscCluster -MockWith { [PSCustomObject] @{ Name = 'web' } }
            Mock -CommandName Find-NlbClusterNode
        }

        It 'Should install the feature and add the node with -Force' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TargetResource @testParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Install-NlbFeature -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Add-NlbClusterNode -Exactly -Times 1 -Scope It -ParameterFilter {
                $NewNodeName -eq 'web02.contoso.com' -and $NewNodeInterface -eq 'NLB' -and $Force
            }
        }
    }

    Context 'When the node is already a member of the cluster' {
        BeforeAll {
            Mock -CommandName Test-NlbFeatureInstalled -MockWith { $true }
            Mock -CommandName Get-NlbDscCluster -MockWith { [PSCustomObject] @{ Name = 'web' } }
            Mock -CommandName Find-NlbClusterNode -MockWith {
                [PSCustomObject] @{ Name = 'web02'; State = 'Converged'; HostPriority = 2 }
            }
        }

        It 'Should not add the node again' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TargetResource @testParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Add-NlbClusterNode -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Set-NlbClusterNode -Exactly -Times 0 -Scope It
        }

        It 'Should change the host priority when it differs' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TargetResource @testParameters -HostPriority 5 } | Should -Not -Throw
            }

            Should -Invoke -CommandName Set-NlbClusterNode -Exactly -Times 1 -Scope It -ParameterFilter {
                $HostPriority -eq 5 -and $Force
            }
        }

        It 'Should remove the node when Ensure is Absent' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TargetResource @testParameters -Ensure 'Absent' } | Should -Not -Throw
            }

            Should -Invoke -CommandName Remove-NlbClusterNode -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the cluster does not exist' {
        BeforeAll {
            Mock -CommandName Test-NlbFeatureInstalled -MockWith { $true }
            Mock -CommandName Get-NlbDscCluster
        }

        It 'Should throw the correct error' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorMessage = $script:localizedData.ClusterRequired -f 'NLB', 'web01.contoso.com'

                { Set-TargetResource @testParameters } | Should -Throw -ExpectedMessage ('*' + $errorMessage + '*')
            }
        }
    }
}
