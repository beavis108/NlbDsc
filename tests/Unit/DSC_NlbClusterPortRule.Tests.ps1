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
    $script:dscResourceName = 'DSC_NlbClusterPortRule'

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

Describe 'DSC_NlbClusterPortRule\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        $script:defaultParameters = @{
            InterfaceName = 'NLB'
            IPAddress     = 'All'
            StartPort     = 80
            EndPort       = 443
        }

        Mock -CommandName Import-NlbModule
    }

    Context 'When the NLB feature is not installed' {
        BeforeAll {
            Mock -CommandName Test-NlbFeatureInstalled -MockWith { $false }
            Mock -CommandName Get-NlbDscCluster
        }

        It 'Should return Ensure Absent' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                (Get-TargetResource @testParameters).Ensure | Should -Be 'Absent'
            }

            Should -Invoke -CommandName Get-NlbDscCluster -Exactly -Times 0 -Scope It
        }
    }

    Context 'When the port rule exists' {
        BeforeAll {
            Mock -CommandName Test-NlbFeatureInstalled -MockWith { $true }
            Mock -CommandName Get-NlbDscCluster -MockWith { [PSCustomObject] @{ Name = 'web' } }
            Mock -CommandName Find-NlbClusterPortRule -MockWith {
                [PSCustomObject] @{
                    VirtualIPAddress = '255.255.255.255'
                    StartPort        = 0
                    EndPort          = 65535
                    Protocol         = 'BOTH'
                    FilteringMode    = 'MULTIPLE'
                    Affinity         = 'SINGLE'
                    Timeout          = 0
                    PortState        = 'Enabled'
                }
            }
        }

        It 'Should return the rule that covers the start port' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @testParameters

                $result.Ensure | Should -Be 'Present'
                $result.IPAddress | Should -Be 'All'
                $result.StartPort | Should -Be 0
                $result.EndPort | Should -Be 65535
                $result.Protocol | Should -BeExactly 'Both'
                $result.Mode | Should -BeExactly 'Multiple'
                $result.Affinity | Should -BeExactly 'Single'
                $result.Timeout | Should -Be 0
                $result.State | Should -BeExactly 'Enabled'
            }
        }
    }

    Context 'When no port rule covers the start port' {
        BeforeAll {
            Mock -CommandName Test-NlbFeatureInstalled -MockWith { $true }
            Mock -CommandName Get-NlbDscCluster -MockWith { [PSCustomObject] @{ Name = 'web' } }
            Mock -CommandName Find-NlbClusterPortRule
        }

        It 'Should return Ensure Absent' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                (Get-TargetResource @testParameters).Ensure | Should -Be 'Absent'
            }
        }
    }
}

Describe 'DSC_NlbClusterPortRule\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        $script:defaultParameters = @{
            InterfaceName = 'NLB'
            IPAddress     = 'All'
            StartPort     = 80
            EndPort       = 443
            Protocol      = 'Tcp'
        }
    }

    Context 'When the rule is in the desired state' {
        BeforeAll {
            Mock -CommandName Get-TargetResource -MockWith {
                @{
                    Ensure    = 'Present'
                    StartPort = [System.UInt16] 80
                    EndPort   = [System.UInt16] 443
                    Protocol  = 'Tcp'
                    Mode      = 'Multiple'
                    Affinity  = 'Single'
                    Timeout   = [System.UInt32] 0
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

    Context 'When the mode is Single and the affinity differs' {
        BeforeAll {
            Mock -CommandName Get-TargetResource -MockWith {
                @{
                    Ensure    = 'Present'
                    StartPort = [System.UInt16] 80
                    EndPort   = [System.UInt16] 443
                    Protocol  = 'Tcp'
                    Mode      = 'Single'
                    Affinity  = 'None'
                    Timeout   = [System.UInt32] 0
                }
            }
        }

        It 'Should ignore Affinity and return $true' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters -Mode 'Single' -Affinity 'Network' | Should -BeTrue
            }
        }
    }

    Context 'When the port range differs' {
        BeforeAll {
            Mock -CommandName Get-TargetResource -MockWith {
                @{
                    Ensure    = 'Present'
                    StartPort = [System.UInt16] 0
                    EndPort   = [System.UInt16] 65535
                    Protocol  = 'Tcp'
                    Mode      = 'Multiple'
                    Affinity  = 'Single'
                    Timeout   = [System.UInt32] 0
                }
            }
        }

        It 'Should return $false' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeFalse
            }
        }
    }

    Context 'When EndPort is lower than StartPort' {
        It 'Should throw' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Test-TargetResource -InterfaceName 'NLB' -IPAddress 'All' -StartPort 443 -EndPort 80 } | Should -Throw
            }
        }
    }
}

Describe 'DSC_NlbClusterPortRule\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        $script:defaultParameters = @{
            InterfaceName = 'NLB'
            IPAddress     = '10.0.0.100'
            StartPort     = 443
            EndPort       = 443
            Protocol      = 'Tcp'
        }

        Mock -CommandName Import-NlbModule
        Mock -CommandName Add-NlbClusterPortRule
        Mock -CommandName Set-NlbClusterPortRule
        Mock -CommandName Remove-NlbClusterPortRule
        Mock -CommandName Enable-NlbClusterPortRule
        Mock -CommandName Disable-NlbClusterPortRule
    }

    Context 'When the NLB feature is not installed' {
        BeforeAll {
            Mock -CommandName Test-NlbFeatureInstalled -MockWith { $false }
        }

        It 'Should throw the correct error' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TargetResource @testParameters } | Should -Throw -ExpectedMessage ('*' + $script:localizedData.FeatureRequired + '*')
            }
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

                { Set-TargetResource @testParameters } | Should -Throw -ExpectedMessage ('*' + ($script:localizedData.ClusterRequired -f 'NLB') + '*')
            }
        }
    }

    Context 'When the rule does not exist' {
        BeforeAll {
            Mock -CommandName Test-NlbFeatureInstalled -MockWith { $true }
            Mock -CommandName Get-NlbDscCluster -MockWith { [PSCustomObject] @{ Name = 'web' } }
            Mock -CommandName Find-NlbClusterPortRule
        }

        It 'Should add the rule with affinity for mode Multiple' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TargetResource @testParameters -Affinity 'Single' -Timeout 30 } | Should -Not -Throw
            }

            Should -Invoke -CommandName Add-NlbClusterPortRule -Exactly -Times 1 -Scope It -ParameterFilter {
                $IP -eq '10.0.0.100' -and $StartPort -eq 443 -and $EndPort -eq 443 -and $Affinity -eq 'Single' -and $Timeout -eq 30
            }
        }

        It 'Should add the rule without affinity for mode Single' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TargetResource @testParameters -Mode 'Single' } | Should -Not -Throw
            }

            Should -Invoke -CommandName Add-NlbClusterPortRule -Exactly -Times 1 -Scope It -ParameterFilter {
                $Mode -eq 'Single' -and -not $PSBoundParameters.ContainsKey('Affinity')
            }
        }

        It 'Should not pass IP for IPAddress All' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $parameters = $testParameters.Clone()
                $parameters.IPAddress = 'All'

                { Set-TargetResource @parameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Add-NlbClusterPortRule -Exactly -Times 1 -Scope It -ParameterFilter {
                -not $PSBoundParameters.ContainsKey('IP')
            }
        }
    }

    Context 'When a rule covers the start port' {
        BeforeAll {
            Mock -CommandName Test-NlbFeatureInstalled -MockWith { $true }
            Mock -CommandName Get-NlbDscCluster -MockWith { [PSCustomObject] @{ Name = 'web' } }
            Mock -CommandName Find-NlbClusterPortRule -MockWith {
                [PSCustomObject] @{
                    IPAddress = '10.0.0.100'
                    StartPort = 0
                    EndPort   = 65535
                    Protocol  = 'Both'
                    Mode      = 'Multiple'
                    Affinity  = 'Single'
                    Timeout   = 0
                }
            }
        }

        It 'Should update only that rule' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TargetResource @testParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Add-NlbClusterPortRule -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Set-NlbClusterPortRule -Exactly -Times 1 -Scope It -ParameterFilter {
                $NewStartPort -eq 443 -and $NewEndPort -eq 443 -and $NewProtocol -eq 'Tcp'
            }
        }

        It 'Should remove the rule when Ensure is Absent' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TargetResource @testParameters -Ensure 'Absent' } | Should -Not -Throw
            }

            Should -Invoke -CommandName Remove-NlbClusterPortRule -Exactly -Times 1 -Scope It
        }

        It 'Should disable the rule cluster wide with drain' {
            InModuleScope -Parameters @{ testParameters = $script:defaultParameters } -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TargetResource @testParameters -State 'Disabled' -Drain $true -DrainTimeout 10 } | Should -Not -Throw
            }

            Should -Invoke -CommandName Disable-NlbClusterPortRule -Exactly -Times 1 -Scope It -ParameterFilter {
                $ClusterWide -and $IP -eq '10.0.0.100' -and $Port -eq 443 -and $Drain -and $Timeout -eq 10
            }
            Should -Invoke -CommandName Enable-NlbClusterPortRule -Exactly -Times 0 -Scope It
        }
    }
}
