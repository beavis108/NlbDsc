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
    $script:dscResourceName = 'DSC_NlbClusterVip'

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

Describe 'DSC_NlbClusterVip\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        Mock -CommandName Import-NlbModule
        Mock -CommandName Test-NlbFeatureInstalled -MockWith { $true }
        Mock -CommandName Get-NlbDscCluster -MockWith { [PSCustomObject] @{ Name = 'web'; IPAddress = '10.0.0.100' } }
        Mock -CommandName Get-NlbClusterVip -MockWith {
            [PSCustomObject] @{ IPAddress = '10.0.0.100'; SubnetMask = '255.255.255.0' }
            [PSCustomObject] @{ IPAddress = '2001:db8::101'; SubnetMask = '::' }
        }
    }

    It 'Should return Present for an IPv6 address written differently' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $result = Get-TargetResource -InterfaceName 'NLB' -IPAddress '2001:0DB8:0::0101'

            $result.Ensure | Should -Be 'Present'
            $result.IsPrimary | Should -BeFalse
        }
    }

    It 'Should report the primary IP address' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            (Get-TargetResource -InterfaceName 'NLB' -IPAddress '10.0.0.100').IsPrimary | Should -BeTrue
        }
    }

    It 'Should return Absent for an unknown address' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            (Get-TargetResource -InterfaceName 'NLB' -IPAddress '10.0.0.150').Ensure | Should -Be 'Absent'
        }
    }
}

Describe 'DSC_NlbClusterVip\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        Mock -CommandName Get-TargetResource -MockWith { @{ Ensure = 'Present'; SubnetMask = '255.255.255.0' } }
    }

    It 'Should return <Expected> for Ensure <Ensure> and subnet mask <SubnetMask>' -ForEach @(
        @{ Ensure = 'Present'; SubnetMask = '255.255.255.0'; Expected = $true }
        @{ Ensure = 'Present'; SubnetMask = '255.255.0.0'; Expected = $false }
        @{ Ensure = 'Absent'; SubnetMask = ''; Expected = $false }
    ) {
        InModuleScope -Parameters $_ -ScriptBlock {
            Set-StrictMode -Version 1.0

            Test-TargetResource -InterfaceName 'NLB' -IPAddress '10.0.0.101' -SubnetMask $SubnetMask -Ensure $Ensure | Should -Be $Expected
        }
    }
}

Describe 'DSC_NlbClusterVip\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        Mock -CommandName Import-NlbModule
        Mock -CommandName Test-NlbFeatureInstalled -MockWith { $true }
        Mock -CommandName Get-NlbDscCluster -MockWith { [PSCustomObject] @{ Name = 'web'; IPAddress = '10.0.0.100' } }
        Mock -CommandName Get-NlbClusterVip -MockWith {
            [PSCustomObject] @{ IPAddress = '10.0.0.100'; SubnetMask = '255.255.255.0' }
            [PSCustomObject] @{ IPAddress = '10.0.0.101'; SubnetMask = '255.255.0.0' }
        }
        Mock -CommandName Add-NlbClusterVip
        Mock -CommandName Remove-NlbClusterVip
    }

    It 'Should add a missing virtual IP address' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Set-TargetResource -InterfaceName 'NLB' -IPAddress '10.0.0.102' -SubnetMask '255.255.255.0'
        }

        Should -Invoke -CommandName Add-NlbClusterVip -Exactly -Times 1 -Scope It -ParameterFilter { $IP -eq '10.0.0.102' -and $SubnetMask -eq '255.255.255.0' }
        Should -Invoke -CommandName Remove-NlbClusterVip -Exactly -Times 0 -Scope It
    }

    It 'Should remove and add the address when the subnet mask differs' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Set-TargetResource -InterfaceName 'NLB' -IPAddress '10.0.0.101' -SubnetMask '255.255.255.0'
        }

        Should -Invoke -CommandName Remove-NlbClusterVip -Exactly -Times 1 -Scope It -ParameterFilter { $Force }
        Should -Invoke -CommandName Add-NlbClusterVip -Exactly -Times 1 -Scope It
    }

    It 'Should not remove the primary IP address' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            { Set-TargetResource -InterfaceName 'NLB' -IPAddress '10.0.0.100' -Ensure 'Absent' } |
                Should -Throw -ExpectedMessage ('*' + ($script:localizedData.PrimaryVipChange -f '10.0.0.100') + '*')
        }

        Should -Invoke -CommandName Remove-NlbClusterVip -Exactly -Times 0 -Scope It
    }
}
