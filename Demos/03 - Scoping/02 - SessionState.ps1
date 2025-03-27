##################################
# Make sure reflection is enabled!
##################################
Import-Module "$PSScriptRoot\ScopingModule.psm1"
$module = Get-Module ScopingModule

# Shows which scopes are available on the internal session state
$module.SessionState.Internal
# GlobalScope  : System.Management.Automation.SessionStateScope
# ModuleScope  : System.Management.Automation.SessionStateScope
# CurrentScope : System.Management.Automation.SessionStateScope
# ScriptScope  : System.Management.Automation.SessionStateScope

# Shows all variables in the script scope
$module.SessionState.Internal.ScriptScope.Variables
# Key                      Value
# ---                      -----
# null                     System.Management.Automation.NullVariable
# false                    System.Management.Automation.PSVariable
# true                     System.Management.Automation.PSVariable
# MaximumErrorCount        System.Management.Automation.SessionStateCapacityVariable
# MaximumVariableCount     System.Management.Automation.SessionStateCapacityVariable
# MaximumFunctionCount     System.Management.Automation.SessionStateCapacityVariable
# MaximumAliasCount        System.Management.Automation.SessionStateCapacityVariable
# MaximumDriveCount        System.Management.Automation.SessionStateCapacityVariable
# Error                    System.Management.Automation.PSVariable
# PSDefaultParameterValues System.Management.Automation.PSVariable
# MyModuleVariable         System.Management.Automation.PSVariable

# Show 'MyModuleVariable' variable and value
$module.SessionState.Internal.ScriptScope.Variables['MyModuleVariable']

# Alter contents of variable
. $module {$host.EnterNestedPrompt()}
$MyModuleVariable = 'test'
# exit to return to console
Get-MyModuleVariable