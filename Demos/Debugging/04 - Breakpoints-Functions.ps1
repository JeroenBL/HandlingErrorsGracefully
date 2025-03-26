###########################################################
# Define a function breakpoint on: Child and debug the code
###########################################################
function GrandParent(){
    'Calling parent'
    Parent
}

function Parent(){
    'Being called by GrandParent'
    'Calling Child'
    Child
}

function Child(){
    'Being called by Parent'
}


try {
    GrandParent
} catch {
    $ex = $PSItem
    Write-Warning "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
}