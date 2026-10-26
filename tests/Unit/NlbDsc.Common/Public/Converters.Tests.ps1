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

Describe 'ConvertTo-NlbPortRuleIPAddress' {
    It 'Should return ''All'' for ''<Value>''' -ForEach @(
        @{ Value = 'All' }
        @{ Value = '0.0.0.0' }
        @{ Value = '255.255.255.255' }
        @{ Value = '' }
        @{ Value = $null }
    ) {
        InModuleScope -Parameters $_ -ScriptBlock {
            Set-StrictMode -Version 1.0

            ConvertTo-NlbPortRuleIPAddress -IPAddress $Value | Should -Be 'All'
        }
    }

    It 'Should return the IP address unchanged' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            ConvertTo-NlbPortRuleIPAddress -IPAddress ' 10.0.0.100 ' | Should -Be '10.0.0.100'
        }
    }
}

Describe 'ConvertTo-NlbDscValue' {
    It 'Should return ''<Expected>'' for ''<Value>''' -ForEach @(
        @{ Value = 'UNICAST'; Expected = 'Unicast' }
        @{ Value = 'igmpmulticast'; Expected = 'IgmpMulticast' }
        @{ Value = 'Unknown'; Expected = 'Unknown' }
    ) {
        InModuleScope -Parameters $_ -ScriptBlock {
            Set-StrictMode -Version 1.0

            ConvertTo-NlbDscValue -Value $Value -AllowedValues @('Unicast', 'Multicast', 'IgmpMulticast') | Should -BeExactly $Expected
        }
    }
}

Describe 'Test-NlbDscOsRequirement' {
    It 'Should return <Expected> for version <Version>' -ForEach @(
        @{ Version = '6.1.7601.0'; Expected = $false }
        @{ Version = '6.2.9200.0'; Expected = $true }
        @{ Version = '10.0.20348.0'; Expected = $true }
    ) {
        InModuleScope -Parameters $_ -ScriptBlock {
            Set-StrictMode -Version 1.0

            Mock -CommandName Get-NlbDscOsVersion -MockWith { [System.Version] $Version }

            Test-NlbDscOsRequirement | Should -Be $Expected
        }
    }
}
