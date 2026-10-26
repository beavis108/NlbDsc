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

Describe 'Get-NlbDscCluster' {
    Context 'When a cluster is bound to the interface' {
        BeforeAll {
            Mock -CommandName Get-NlbCluster -MockWith { [PSCustomObject] @{ Name = 'web' } }
        }

        It 'Should return the cluster and only pass HostName when specified' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                (Get-NlbDscCluster -InterfaceName 'NLB').Name | Should -Be 'web'
            }

            Should -Invoke -CommandName Get-NlbCluster -Exactly -Times 1 -Scope It -ParameterFilter {
                $InterfaceName -eq 'NLB' -and -not $PSBoundParameters.ContainsKey('HostName')
            }
        }
    }

    Context 'When Get-NlbCluster throws' {
        BeforeAll {
            Mock -CommandName Get-NlbCluster -MockWith { throw 'The specified interface is not bound to NLB.' }
        }

        It 'Should return $null' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Get-NlbDscCluster -InterfaceName 'NLB' -HostName 'web01' | Should -BeNullOrEmpty
            }
        }
    }
}
