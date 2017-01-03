#region Script scoped

$script:ProviderName = 'chocolatey'
$script:ChocolateyInstalled = $false

#endregion script scoped

<#
.Synopsis
   Find a chocolatey package
.DESCRIPTION
   Find a given package on the chocolatey repository using the prototype chocolatey provider
.EXAMPLE
   Find-ChocolateyPackage -Name git
.EXAMPLE
   Find-ChocolateyPacakge -Name git -MinimumVersion 2.5
.INPUTS
   Name of package (optional)
.OUTPUTS
   Available packages
#>
function Find-ChocolateyPackage
{
    [CmdletBinding()]
    [OutputType('Microsoft.PackageManagement.Packaging.SoftwareIdentity')]

param(
    
    [switch]
    ${IncludeDependencies},

    [switch]
    ${AllVersions},

    [Parameter(Position=0)]
    [string[]]
    ${Name},

    [string]
    ${RequiredVersion},

    [Alias('Version')]
    [string]
    ${MinimumVersion},

    [string]
    ${MaximumVersion}

)

    Find-Package -ProviderName Chocolatey @PSBoundParameters
}

function Test-ChocolateyProvider
{
    [CmdletBinding()]
    param()

    if ($script:ChocolateyInstalled) {return $script:ChocolateyInstalled }

    Write-Verbose 'Checking (in a separate process) if chocolatey provider is installed'
    $provider = (Start-Job {Get-PackageProvider -Name chocolatey -ListAvailable 2> $Null} | Receive-Job -Wait )

    if ($provider -eq $null)
    {
        Write-Verbose 'chocolatey provider is not installed'
        return $false
    }

    # check if the right version is available
    if ($provider.Version -eq '2.8.5.130')
    {
        Write-Verbose 'Chocolatey provider expected version 2.8.5.130 is installed'
        $script:ChocolateyInstalled = $true
        return $true
    }

    Write-Verbose "Chocolatey provider expected version 2.8.5.130 is not installed, installed version is $($provider.Version)"
    return $false
}

function Install-ChocolateyProvider
{
    [CmdletBinding()]
    param(
        [switch]
        $Force
    )

    if (Test-ChocolateyProvider) 
    {
        Write-Verbose 'Chocalatey provider is already installed, skipping'
        return
    }

    Write-Verbose 'Installing chocolatey provider'
    Get-PackageProvider -Name chocolatey -Force
}

function Uninstall-ChocolateyProvider
{
    [CmdletBinding()]
    param()

    if ( -not (Test-ChocolateyProvider )) 
    {
        Write-Verbose 'Chocolatey provider not installed, skipping'
        return
    }

    $provider = (Start-Job {Get-PackageProvider -Name chocolatey} | Receive-Job -Wait)

    $pos = $provider[0].ProviderPath.LastIndexOf('ProviderAssemblies\')
    $AssembliesRoot = $provider[0].ProviderPath.Substring(0, 35+'ProviderAssemblies\'.Length)

    pushd $AssembliesRoot

    try
    {
        # delete the chocolatey provider folder
        Write-Verbose 'Removing chocolatey provider version 2.8.5.130'
        Remove-Item -Recurse -Force '.\chocolatey\2.8.5.130'
        $script:ChocolateyInstalled = $false
    }
    finally
    {
        popd
    }
}

function Install-ChocolateyPackage
{
    [CmdletBinding(DefaultParameterSetName='PackageBySearch', SupportsShouldProcess=$true, ConfirmImpact='Medium')]

    param(

        [Parameter(ParameterSetName='PackageByInputObject', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [Microsoft.PackageManagement.Packaging.SoftwareIdentity[]]
        ${InputObject},

        [Parameter(ParameterSetName='PackageBySearch', Position=0)]
        [string[]]
        ${Name},

        [Parameter(ParameterSetName='PackageBySearch')]
        [string]
        ${RequiredVersion},

        [Parameter(ParameterSetName='PackageBySearch')]
        [string]
        ${MinimumVersion},

        [Parameter(ParameterSetName='PackageBySearch')]
        [string]
        ${MaximumVersion},    

        [switch]
        ${AllVersions},

        [switch]
        ${Force})
    

        begin
        {
            try {
                $outBuffer = $null
                if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
                {
                    $PSBoundParameters['OutBuffer'] = 1
                }

                $Force = $false
                $PSBoundParameters.TryGetValue('Force', [ref]$Force) > $null        
                $PSBoundParameters['ProviderName'] = $script:ProviderName

                $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('PackageManagement\Install-Package', [System.Management.Automation.CommandTypes]::Cmdlet)
                $scriptCmd = {& $wrappedCmd @PSBoundParameters }
                $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
                $steppablePipeline.Begin($PSCmdlet)

                Install-ChocolateyProvider -Force:$Force
            } catch {
                throw
            }
        }

        process
        {
            try {
                $steppablePipeline.Process($_)
            } catch {
                throw
            }
        }

        end
        {
            try {
                $steppablePipeline.End()
            } catch {
                throw
            }
        }
}

function Uninstall-ChocolateyPackage
{
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
    param(
        [Parameter(ParameterSetName='PackageByInputObject', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [Microsoft.PackageManagement.Packaging.SoftwareIdentity[]]
        ${InputObject},

        [Parameter(ParameterSetName='PackageBySearch', Mandatory=$true, Position=0)]
        [string[]]
        ${Name},

        [Parameter(ParameterSetName='PackageBySearch')]
        [string]
        ${RequiredVersion},

        [Parameter(ParameterSetName='PackageBySearch')]
        [Alias('Version')]
        [string]
        ${MinimumVersion},

        [Parameter(ParameterSetName='PackageBySearch')]
        [string]
        ${MaximumVersion},

        [switch]
        ${AllVersions},

        [switch]
        ${Force},

        [switch]
        ${ForceBootstrap})    

        begin
        {
            try {
                $outBuffer = $null
                if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
                {
                    $PSBoundParameters['OutBuffer'] = 1
                }
                $Force = $false
                $PSBoundParameters.TryGetValue('Force', [ref]$Force) > $null        

                if ($PSCmdlet.ParameterSetName -eq 'PackageBySearch')
                {
                    $PSBoundParameters['ProviderName'] = $script:ProviderName
                }

                $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('PackageManagement\Uninstall-Package', [System.Management.Automation.CommandTypes]::Cmdlet)
                $scriptCmd = {& $wrappedCmd @PSBoundParameters }
                $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
                $steppablePipeline.Begin($PSCmdlet)

                Install-ChocolateyProvider -Force:$Force

            } catch {
                throw
            }
        }

        process
        {
            try {
                $steppablePipeline.Process($_)
            } catch {
                throw
            }
        }

        end
        {
            try {
                $steppablePipeline.End()
            } catch {
                throw
            }
        }
}

function Get-ChocolateyPackage
{
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

        begin
        {
            try {
                $outBuffer = $null
                if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
                {
                    $PSBoundParameters['OutBuffer'] = 1
                }

                $Force = $false
                $PSBoundParameters.TryGetValue('Force', [ref]$Force) > $null        
                $PSBoundParameters['ProviderName'] = $script:ProviderName

                $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('PackageManagement\Get-Package', [System.Management.Automation.CommandTypes]::Cmdlet)

                $scriptCmd = {& $wrappedCmd @PSBoundParameters }
                $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
                $steppablePipeline.Begin($PSCmdlet)

                Install-ChocolateyProvider -Force:$Force

            } catch {
                throw
            }
        }

        process
        {
            try {
                $steppablePipeline.Process($_)
            } catch {
                throw
            }
        }

        end
        {
            try {
                $steppablePipeline.End()
            } catch {
                throw
            }
        }
}

function Test-ChocolateyPackage
{
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

        $package = Get-ChocolateyPackage @PSBoundParameters 2> $null

        if ($package -eq $null)
        {
            return $false
        }

        return $true
}

[DscResource()]
class ChocolateyPackage
{
    [DscProperty(Key)]
    [string]
    $Name

    [DscProperty()]
    [string]
    $RequiredVersion

    [DscProperty()]
    [string]
    $MinimumVersion

    [DscProperty()]
    [string]
    $MaximumVersion

    [DscProperty(NotConfigurable)]
    [string]
    $InstalledVersion

    [DscProperty(Mandatory)]
    [string]
    [ValidateSet('Present', 'Absent')]
    $Ensure

    [ChocolateyPackage] Get()
    {
        $properties = $this.GetProperty()

        $package = Get-ChocolateyPackage @properties 2> $null

        if ($package -eq $null)
        {
            return @{
                Name = $this.Name
                Ensure = 'Absent'
                InstalledVersion = '0.0.0.0'
            }    
        }
        else
        {
            return @{
                Name = $this.Name
                Ensure = 'Present'
                InstalledVersion = $package.Version
            }
        }

        return $this
    }

    [bool] Test()
    {
        $properties = $this.GetProperty()

        $installed = Test-ChocolateyPackage @properties

        if ($this.Ensure -eq 'Present')
        {
            return $installed
        }
        else 
        {
            return (!$installed)
        }

        return $false
    }

    [void] Set()
    {
        $properties = $this.GetProperty()

        if ($this.Ensure -eq 'Present')
        {
            Install-ChocolateyPackage @properties -Force
        }
        else
        {
            # remove all versions present if no version has been specified
            while((Test-ChocolateyPackage @properties))
            {
                Uninstall-ChocolateyPackage @properties -Force
            }
            
            #Uninstall-ChocolateyPackage @properties -Force 
        }
    }

    [hashtable] GetProperty()
    {
        $properties = @{}

        if ($this.Name) {$properties += @{Name = $this.Name}}
        if ($this.RequiredVersion) {$properties += @{RequiredVersion = $this.RequiredVersion}}
        if ($this.MinimumVersion) {$properties += @{MinimumVersion = $this.MinimumVersion}}
        if ($this.MaximumVersion) {$properties += @{MaximumVersion = $this.MaximumVersion}}
                
        return $properties
    }

}

function New-ChocolateyPackage
{
    [ChocolateyPackage]::new()
}