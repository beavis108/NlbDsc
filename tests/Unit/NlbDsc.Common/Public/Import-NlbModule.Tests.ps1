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

Describe 'Import-NlbModule' {
    Context 'When the module is already imported' {
        BeforeAll {
            Mock -CommandName Get-Module -ParameterFilter { -not $ListAvailable } -MockWith { [PSCustomObject] @{ Name = 'NetworkLoadBalancingClusters' } }
            Mock -CommandName Import-Module
        }

        It 'Should not import the module again' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Import-NlbModule
            }

            Should -Invoke -CommandName Import-Module -Exactly -Times 0 -Scope It
        }
    }

    Context 'When the module is available but not imported' {
        BeforeAll {
            Mock -CommandName Get-Module -ParameterFilter { -not $ListAvailable }
            Mock -CommandName Get-Module -ParameterFilter { $ListAvailable } -MockWith { [PSCustomObject] @{ Name = 'NetworkLoadBalancingClusters' } }
            Mock -CommandName Import-Module
        }

        It 'Should import the module globally' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Import-NlbModule
            }

            Should -Invoke -CommandName Import-Module -Exactly -Times 1 -Scope It -ParameterFilter {
                $Name -eq 'NetworkLoadBalancingClusters' -and $Global -eq $true
            }
        }
    }

    Context 'When the module is not available' {
        BeforeAll {
            Mock -CommandName Get-Module
            Mock -CommandName Import-Module
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Import-NlbModule } | Should -Throw -ExpectedMessage ('*' + $script:localizedData.ModuleNotAvailable + '*')
            }

            Should -Invoke -CommandName Import-Module -Exactly -Times 0 -Scope It
        }
    }
}
