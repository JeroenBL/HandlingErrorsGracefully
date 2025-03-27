$script:MyModuleVariable = 'Hello from scoping module'

function Get-MyModuleVariable {
    [CmdletBinding()]
    param()

    Write-Host $script:MyModuleVariable
}