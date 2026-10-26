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
    $script:dscResourceName = 'DSC_NlbClusterDeployment'

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

Describe 'DSC_NlbClusterDeployment\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        Mock -CommandName Import-NlbModule
    }

    Context 'When the NLB feature is not installed' {
        BeforeAll {
            Mock -CommandName Test-NlbFeatureInstalled -MockWith { $false }
            Mock -CommandName Get-NlbDscCluster
        }

        It 'Should return Ensure Absent without calling any NLB cmdlet' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource -ClusterName 'web' -InterfaceName 'NLB' -ClusterPrimaryIP '10.0.0.100' -SubnetMask '255.255.255.0'

                $result.Ensure | Should -Be 'Absent'
                $result.FeatureInstalled | Should -BeFalse
                $result.ClusterName | Should -Be 'web'
            }

            Should -Invoke -CommandName Import-NlbModule -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-NlbDscCluster -Exactly -Times 0 -Scope It
        }
    }

    Context 'When the cluster does not exist' {
        BeforeAll {
            Mock -CommandName Test-NlbFeatureInstalled -MockWith { $true }
            Mock -CommandName Get-NlbDscCluster
        }

        It 'Should return Ensure Absent' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource -ClusterName 'web' -InterfaceName 'NLB' -ClusterPrimaryIP '10.0.0.100' -SubnetMask '255.255.255.0'

                $result.Ensure | Should -Be 'Absent'
                $result.FeatureInstalled | Should -BeTrue
            }
        }
    }

    Context 'When the cluster exists' {
        BeforeAll {
            Mock -CommandName Test-NlbFeatureInstalled -MockWith { $true }
            Mock -CommandName Get-NlbDscCluster -MockWith {
                [PSCustomObject] @{
                    Name       = 'web'
                    IPAddress  = '10.0.0.100'
                    SubnetMask = '255.255.255.0'
                    Mode       = 'MULTICAST'
                }
            }
            Mock -CommandName Get-NlbClusterNode -MockWith {
                [PSCustomObject] @{ Name = 'web01' }
                [PSCustomObject] @{ Name = 'web02' }
            }
            Mock -CommandName Get-NlbClusterDriverInfo -MockWith {
                [PSCustomObject] @{ ClusterMacAddress = '03-BF-0A-00-00-64' }
            }
        }

        It 'Should return the current state' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource -ClusterName 'web' -InterfaceName 'NLB' -ClusterPrimaryIP '10.0.0.100' -SubnetMask '255.255.255.0'

                $result.Ensure | Should -Be 'Present'
                $result.ClusterName | Should -Be 'web'
                $result.ClusterPrimaryIP | Should -Be '10.0.0.100'
                $result.SubnetMask | Should -Be '255.255.255.0'
                $result.OperationMode | Should -BeExactly 'Multicast'
                $result.Nodes | Should -Be @('web01', 'web02')
                $result.ClusterMacAddress | Should -Be '03-BF-0A-00-00-64'
            }
        }
    }
}

Describe 'DSC_NlbClusterDeployment\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        $script:defaultParameters = @{
            ClusterName      = 'web'
            InterfaceName    = 'NLB'
            ClusterPrimaryIP = '10.0.0.100'
            SubnetMask       = '255.255.255.0'
        }
    }

    Context 'When the cluster is in the desired state' {
        BeforeAll {
            Mock -CommandName Get-TargetResource -MockWith {
                @{
                    ClusterName      = 'web'
                    ClusterPrimaryIP = '10.0.0.100'
                    SubnetMask       = '255.255.255.0'
                    OperationMode    = 'Unicast'
                    Ensure           = 'Present'
                }
            }
        }

        It 'Should return $true' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeTrue
            }
        }
    }

    Context 'When the operation mode differs' {
        BeforeAll {
            Mock -CommandName Get-TargetResource -MockWith {
                @{
                    ClusterName      = 'web'
                    ClusterPrimaryIP = '10.0.0.100'
                    SubnetMask       = '255.255.255.0'
                    OperationMode    = 'Multicast'
                    Ensure           = 'Present'
                }
            }
        }

        It 'Should return $false' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters -OperationMode 'Unicast' | Should -BeFalse
            }
        }
    }

    Context 'When the cluster is absent but should be present' {
        BeforeAll {
            Mock -CommandName Get-TargetResource -MockWith {
                @{
                    Ensure = 'Absent'
                }
            }
        }

        It 'Should return $false' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeFalse
            }
        }

        It 'Should return $true when Ensure is Absent' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters -Ensure 'Absent' | Should -BeTrue
            }
        }
    }
}

Describe 'DSC_NlbClusterDeployment\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        $script:defaultParameters = @{
            ClusterName      = 'web'
            InterfaceName    = 'NLB'
            ClusterPrimaryIP = '10.0.0.100'
            SubnetMask       = '255.255.255.0'
        }

        Mock -CommandName Import-NlbModule
        Mock -CommandName New-NlbCluster
        Mock -CommandName Set-NlbCluster
        Mock -CommandName Remove-NlbCluster
        Mock -CommandName Set-NlbClusterVip
        Mock -CommandName Add-NlbClusterVip
        Mock -CommandName Remove-NlbClusterVip
        Mock -CommandName Get-NlbClusterNodeNetworkInterface -MockWith {
            [PSCustomObject] @{ InterfaceName = 'NLB'; DhcpEnabled = $false }
        }
    }

    Context 'When the NLB feature is not installed' {
        BeforeAll {
            Mock -CommandName Test-NlbFeatureInstalled -MockWith { $false }
            Mock -CommandName Get-NlbDscCluster
        }

        Context 'When the installation does not require a restart' {
            BeforeAll {
                Mock -CommandName Install-NlbFeature -MockWith { $false }
            }

            It 'Should install the feature and create the cluster' {
                InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Install-NlbFeature -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Import-NlbModule -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName New-NlbCluster -Exactly -Times 1 -Scope It -ParameterFilter {
                    $ClusterName -eq 'web' -and $OperationMode -eq 'Unicast' -and $InterfaceName -eq 'NLB'
                }
            }
        }

        Context 'When the installation requires a restart' {
            BeforeAll {
                Mock -CommandName Install-NlbFeature -MockWith { $true }
            }

            It 'Should install the feature and not create the cluster yet' {
                InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Install-NlbFeature -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName New-NlbCluster -Exactly -Times 0 -Scope It
            }
        }
    }

    Context 'When the cluster exists with a different operation mode' {
        BeforeAll {
            Mock -CommandName Test-NlbFeatureInstalled -MockWith { $true }
            Mock -CommandName Install-NlbFeature
            Mock -CommandName Get-NlbDscCluster -MockWith {
                [PSCustomObject] @{
                    Name       = 'web'
                    IPAddress  = '10.0.0.100'
                    SubnetMask = '255.255.255.0'
                    Mode       = 'UNICAST'
                }
            }
        }

        It 'Should change the operation mode' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TargetResource @testParameters -OperationMode 'IgmpMulticast' } | Should -Not -Throw
            }

            Should -Invoke -CommandName Install-NlbFeature -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName New-NlbCluster -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Set-NlbCluster -Exactly -Times 1 -Scope It -ParameterFilter {
                $OperationMode -eq 'IgmpMulticast'
            }
        }
    }

    Context 'When the cluster exists with a different primary IP address and the same subnet mask' {
        BeforeAll {
            Mock -CommandName Test-NlbFeatureInstalled -MockWith { $true }
            Mock -CommandName Get-NlbDscCluster -MockWith {
                [PSCustomObject] @{
                    Name       = 'web'
                    IPAddress  = '10.0.0.200'
                    SubnetMask = '255.255.255.0'
                    Mode       = 'UNICAST'
                }
            }
            Mock -CommandName Get-NlbClusterVip -ParameterFilter { -not $IP } -MockWith {
                [PSCustomObject] @{ IPAddress = '10.0.0.200'; SubnetMask = '255.255.255.0' }
            }
            Mock -CommandName Get-NlbClusterVip -ParameterFilter { $IP -eq '10.0.0.200' } -MockWith {
                [PSCustomObject] @{ IPAddress = '10.0.0.200'; SubnetMask = '255.255.255.0' }
            }
        }

        It 'Should replace the primary virtual IP address in place' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TargetResource @testParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Set-NlbClusterVip -Exactly -Times 1 -Scope It -ParameterFilter {
                $NewIP -eq '10.0.0.100'
            }
            Should -Invoke -CommandName New-NlbCluster -Exactly -Times 0 -Scope It
        }
    }

    Context 'When the cluster exists with a different subnet mask' {
        BeforeAll {
            Mock -CommandName Test-NlbFeatureInstalled -MockWith { $true }
            Mock -CommandName Get-NlbDscCluster -MockWith {
                [PSCustomObject] @{
                    Name       = 'web'
                    IPAddress  = '10.0.0.100'
                    SubnetMask = '255.255.0.0'
                    Mode       = 'UNICAST'
                }
            }
        }

        It 'Should throw the correct error' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorMessage = $script:localizedData.SubnetMaskMismatch -f '10.0.0.100', '255.255.0.0', '255.255.255.0'

                { Set-TargetResource @testParameters } | Should -Throw -ExpectedMessage ('*' + $errorMessage + '*')
            }
        }
    }

    Context 'When the cluster exists with a different name' {
        BeforeAll {
            Mock -CommandName Test-NlbFeatureInstalled -MockWith { $true }
            Mock -CommandName Get-NlbDscCluster -MockWith {
                [PSCustomObject] @{
                    Name       = 'old'
                    IPAddress  = '10.0.0.100'
                    SubnetMask = '255.255.255.0'
                    Mode       = 'UNICAST'
                }
            }
        }

        It 'Should rename the cluster' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TargetResource @testParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Set-NlbCluster -Exactly -Times 1 -Scope It -ParameterFilter {
                $Name -eq 'web' -and -not $PSBoundParameters.ContainsKey('OperationMode')
            }
        }
    }

    Context 'When the interface uses DHCP' {
        BeforeAll {
            Mock -CommandName Test-NlbFeatureInstalled -MockWith { $true }
            Mock -CommandName Get-NlbDscCluster
            Mock -CommandName Get-NlbClusterNodeNetworkInterface -MockWith {
                [PSCustomObject] @{ InterfaceName = 'NLB'; DhcpEnabled = $true }
            }
        }

        It 'Should throw without OverrideDhcp' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TargetResource @testParameters } | Should -Throw -ExpectedMessage ('*' + ($script:localizedData.InterfaceUsesDhcp -f 'NLB') + '*')
            }

            Should -Invoke -CommandName New-NlbCluster -Exactly -Times 0 -Scope It
        }

        It 'Should create the cluster with -Force and the dedicated IP address when OverrideDhcp is $true' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TargetResource @testParameters -OverrideDhcp $true -DedicatedIP '10.0.0.11' } | Should -Not -Throw
            }

            Should -Invoke -CommandName New-NlbCluster -Exactly -Times 1 -Scope It -ParameterFilter {
                $Force -and $DedicatedIP -eq '10.0.0.11'
            }
        }
    }

    Context 'When the cluster should be absent' {
        BeforeAll {
            Mock -CommandName Test-NlbFeatureInstalled -MockWith { $true }
            Mock -CommandName Get-NlbDscCluster -MockWith {
                [PSCustomObject] @{
                    Name = 'web'
                }
            }
        }

        It 'Should remove the cluster' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TargetResource @testParameters -Ensure 'Absent' } | Should -Not -Throw
            }

            Should -Invoke -CommandName Remove-NlbCluster -Exactly -Times 1 -Scope It
        }
    }

    Context 'When New-NlbCluster fails' {
        BeforeAll {
            Mock -CommandName Test-NlbFeatureInstalled -MockWith { $true }
            Mock -CommandName Get-NlbDscCluster
            Mock -CommandName New-NlbCluster -MockWith { throw 'Interface not found' }
        }

        It 'Should throw the correct error' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorMessage = $script:localizedData.CreateClusterFailed -f 'web'

                { Set-TargetResource @testParameters } | Should -Throw -ExpectedMessage ('*' + $errorMessage + '*')
            }
        }
    }
}
