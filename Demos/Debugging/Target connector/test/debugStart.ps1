#####################################################
# debugStart
# PowerShell V2
#####################################################

# Select the code below and press F8 to initialize the variable(s) in your PSSession
$WarningPreference = 'Continue'
$VerbosePreference = 'SilentlyContinue'
$InformationPreference = 'Continue'

$currentDirectory = $PSScriptRoot
$actionContext = Get-Content "$currentDirectory\actionContext.json" -Encoding 'UTF8' | ConvertFrom-Json

# The 'CustomList' is a wrapper class around '[System.Collections.Generic.List].
# Its being used in the 'outputContext.AuditLogs'.
# When a new auditLog is added, the message will be automatically displayed within the VSCode UI.
class CustomList {
    $list = [System.Collections.Generic.List[object]]::new()
    [void] Add([object] $obj) {
        $this.list.Add($obj)
        $scriptBlock = {
            if ($obj.IsError) {
                $psEditor.Window.ShowErrorMessage("Message: [$($obj.Message)]. Action: [$($obj.Action)]")
            } else {
                $psEditor.Window.ShowInformationMessage("Message: [$($obj.Message)]. Action: [$($obj.Action)]")
            }
        }
        $method = [ScriptBlock]::Create($scriptBlock)
        $method.Invoke()
    }
}

$outputContext = [PSCustomObject]@{
    Data              = $null
    PreviousData      = $null
    AuditLogs         = [CustomList]::new()
    AccountReference  = $null
    Success           = $null
    Permissions       = [System.Collections.Generic.List[object]]::new()
    AccountCorrelated = $false
}
