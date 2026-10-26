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

Describe 'Install-NlbFeature' {
    BeforeAll {
        Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'Install-WindowsFeature' } -MockWith { $true }
        Mock -CommandName Set-DscMachineRebootRequired
    }

    Context 'When the installation succeeds without restart' {
        BeforeAll {
            Mock -CommandName Install-WindowsFeature -MockWith {
                [PSCustomObject] @{ Success = $true; RestartNeeded = 'No'; ExitCode = 'Success' }
            }
        }

        It 'Should install NLB and RSAT-NLB and return $false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Install-NlbFeature | Should -BeFalse
            }

            Should -Invoke -CommandName Install-WindowsFeature -Exactly -Times 1 -Scope It -ParameterFilter {
                $Name -contains 'NLB' -and $Name -contains 'RSAT-NLB'
            }
            Should -Invoke -CommandName Set-DscMachineRebootRequired -Exactly -Times 0 -Scope It
        }
    }

    Context 'When the installation requires a restart' {
        BeforeAll {
            Mock -CommandName Install-WindowsFeature -MockWith {
                [PSCustomObject] @{ Success = $true; RestartNeeded = 'Yes'; ExitCode = 'SuccessRestartRequired' }
            }
        }

        It 'Should request a restart and return $true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Install-NlbFeature -WarningAction 'SilentlyContinue' | Should -BeTrue
            }

            Should -Invoke -CommandName Set-DscMachineRebootRequired -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the installation fails' {
        BeforeAll {
            Mock -CommandName Install-WindowsFeature -MockWith {
                [PSCustomObject] @{ Success = $false; RestartNeeded = 'No'; ExitCode = 'Failed' }
            }
        }

        It 'Should throw' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Install-NlbFeature } | Should -Throw
            }
        }
    }
}
