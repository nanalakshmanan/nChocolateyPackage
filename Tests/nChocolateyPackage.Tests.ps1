$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

$global:TestPackageNamePresent = '7zip'
$global:TestPackageNameAbsent = '7zip.commandline'
$global:TestPackageMinVersion = '15.10'
$global:TestPackageMaxVersion = '15.14'
$global:TestPackageRequiredVersion = '15.12'

function Install-RequiredPackage
{
    Install-ChocolateyPackage -Name $global:TestPackageNamePresent -RequiredVersion $global:TestPackageMinVersion -Force 
    Install-ChocolateyPackage -Name $global:TestPackageNamePresent -RequiredVersion $global:TestPackageMaxVersion -Force 
    Install-ChocolateyPackage -Name $global:TestPackageNamePresent -RequiredVersion $global:TestPackageRequiredVersion -Force 
}

function Uninstall-RequiredPackage
{
    Uninstall-ChocolateyPackage -Name $global:TestPackageNameAbsent -AllVersions -Force 2> $null
}

Describe "nChocolateyPackage Tests" {

    BeforeAll {
        
        # Ensure provider is installed
        <#$global:ProviderInstalled = $false

        $global:ProviderInstalled = Test-ChocolateyProvider 

        if (!$global:ProviderInstalled)
        {
            Install-ChocolateyProvider -Force 
        }#>
        $global:ProviderInstalled = $true

        <#Uninstall-RequiredPackage
        Install-RequiredPackage#>
    }

    AfterAll {
        
        if (!$global:ProviderInstalled)
        {
            #provider was installed by suite, remove it
            Write-Warning 'Test suite installed chocolatey provider. To uninstall -  close all PowerShell windows, open a new one and run Uninstall-ChocolateyProvider'
        }

        #Uninstall-RequiredPackage
    }   
        
    Mock -CommandName Get-Package -ModuleName PackageManagement -MockWith {

        [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string[]]
        ${Name},

        [string]
        ${RequiredVersion},

        [Alias('Version')]
        [string]
        ${MinimumVersion},

        [string]
        ${MaximumVersion},

        [switch]
        ${AllVersions},

        [switch]
        ${Force})
    }

    Context 'Test method tests' {
        
        $Testcases = @()
        $Testcases += @{Name = $global:TestPackageNameAbsent; Ensure = 'Present'; ExpectedResult = $false}
        $Testcases += @{Name = $global:TestPackageNameAbsent; Ensure = 'Absent'; ExpectedResult = $true}
        $Testcases += @{Name = $global:TestPackageNamePresent; Ensure = 'Present'; ExpectedResult = $true}
        $Testcases += @{Name = $global:TestPackageNamePresent; Ensure = 'Absent'; ExpectedResult = $false}

        It 'Test(): Name : <Name>, Ensure : <Ensure>' -TestCases $Testcases {
            param($Name, $Ensure, $ExpectedResult)

            $package = New-ChocolateyPackage

            $package.Name = $Name
            $package.Ensure = $Ensure

            $package.Test() | should be $ExpectedResult

            Assert-MockCalled -CommandName Get-Package
        }                

        $Testcases = @()
        $Testcases += @{Name = $global:TestPackageNamePresent; Ensure = 'Present'; MinVersion = $global:TestPackageMinVersion; ExpectedResult = $true}
        $Testcases += @{Name = $global:TestPackageNamePresent; Ensure = 'Present'; MinVersion = '1000'; ExpectedResult = $false}
        $Testcases += @{Name = $global:TestPackageNamePresent; Ensure = 'Present'; MinVersion = '0.0'; ExpectedResult = $true}
        $Testcases += @{Name = $global:TestPackageNamePresent; Ensure = 'Absent'; MinVersion = $global:TestPackageMinVersion; ExpectedResult = $false}
        $Testcases += @{Name = $global:TestPackageNamePresent; Ensure = 'Absent'; MinVersion = '1000'; ExpectedResult = $true}
        $Testcases += @{Name = $global:TestPackageNamePresent; Ensure = 'Absent'; MinVersion = '0.0'; ExpectedResult = $false}

        $Testcases += @{Name = $global:TestPackageNameAbsent; Ensure = 'Absent'; MinVersion = $global:TestPackageMinVersion; ExpectedResult = $true}
        $Testcases += @{Name = $global:TestPackageNameAbsent; Ensure = 'Absent'; MinVersion = '1000'; ExpectedResult = $true}
        $Testcases += @{Name = $global:TestPackageNameAbsent; Ensure = 'Absent'; MinVersion = '0.0'; ExpectedResult = $true}
        $Testcases += @{Name = $global:TestPackageNameAbsent; Ensure = 'Present'; MinVersion = $global:TestPackageMinVersion; ExpectedResult = $false}
        $Testcases += @{Name = $global:TestPackageNameAbsent; Ensure = 'Present'; MinVersion = '1000'; ExpectedResult = $false}
        $Testcases += @{Name = $global:TestPackageNameAbsent; Ensure = 'Present'; MinVersion = '0.0'; ExpectedResult = $false}

        It 'Test(): Name : <Name>, Ensure : <Ensure>, MinVersion : <MinVersion>' -TestCases $Testcases {
            param($Name, $Ensure, $MinVersion, $ExpectedResult)

            $package = New-ChocolateyPackage

            $package.Name = $Name
            $package.Ensure = $Ensure
            $package.MinimumVersion = $MinVersion

            $package.Test() | should be $ExpectedResult
        }                        

        $Testcases = @()
        $Testcases += @{Name = $global:TestPackageNamePresent; Ensure = 'Present'; MaxVersion = $global:TestPackageMaxVersion; ExpectedResult = $true}
        $Testcases += @{Name = $global:TestPackageNamePresent; Ensure = 'Present'; MaxVersion = '1000'; ExpectedResult = $true}
        $Testcases += @{Name = $global:TestPackageNamePresent; Ensure = 'Present'; MaxVersion = '0.0'; ExpectedResult = $false}
        $Testcases += @{Name = $global:TestPackageNamePresent; Ensure = 'Absent'; MaxVersion = $global:TestPackageMaxVersion; ExpectedResult = $false}
        $Testcases += @{Name = $global:TestPackageNamePresent; Ensure = 'Absent'; MaxVersion = '1000'; ExpectedResult = $true}
        $Testcases += @{Name = $global:TestPackageNamePresent; Ensure = 'Absent'; MaxVersion = '0.0'; ExpectedResult = $false}

        $Testcases += @{Name = $global:TestPackageNameAbsent; Ensure = 'Absent'; MaxVersion = $global:TestPackageMaxVersion; ExpectedResult = $true}
        $Testcases += @{Name = $global:TestPackageNameAbsent; Ensure = 'Absent'; MaxVersion = '1000'; ExpectedResult = $true}
        $Testcases += @{Name = $global:TestPackageNameAbsent; Ensure = 'Absent'; MaxVersion = '0.0'; ExpectedResult = $true}
        $Testcases += @{Name = $global:TestPackageNameAbsent; Ensure = 'Present'; MaxVersion = $global:TestPackageMaxVersion; ExpectedResult = $false}
        $Testcases += @{Name = $global:TestPackageNameAbsent; Ensure = 'Present'; MaxVersion = '1000'; ExpectedResult = $false}
        $Testcases += @{Name = $global:TestPackageNameAbsent; Ensure = 'Present'; MaxVersion = '0.0'; ExpectedResult = $false}

        It 'Test(): Name : <Name>, Ensure : <Ensure>, MaxVersion : <MaxVersion>' -TestCases $Testcases {
            param($Name, $Ensure, $MaxVersion, $ExpectedResult)

            $package = New-ChocolateyPackage

            $package.Name = $Name
            $package.Ensure = $Ensure
            $package.MaximumVersion = $MaxVersion

            $package.Test() | should be $ExpectedResult
        }                        

    }

    <#Context 'Set method tests' {

        AfterEach {
            Uninstall-RequiredPackage
            Install-RequiredPackage
        }

        $Testcases = @()
        $Testcases += @{Name = $global:TestPackageNameAbsent; Ensure = 'Present'; TestResult = $true}
        $Testcases += @{Name = $global:TestPackageNamePresent; Ensure = 'Absent'; TestResult = $false}

        It 'Set(): Name : <Name>, Ensure : <Ensure>' -TestCases $Testcases {
            param($Name, $Ensure, $TestResult)

            $package = New-ChocolateyPackage

            $package.Name = $Name
            $package.Ensure = $Ensure

            $package.Set()
            Test-ChocolateyPackage -Name $Name | Should be $TestResult
        }

    }#>
}
