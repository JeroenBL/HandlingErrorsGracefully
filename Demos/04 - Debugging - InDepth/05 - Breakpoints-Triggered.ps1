###########################################################
# Define a breakpoint on line 7 and a triggered breakpoint
# on line 19.
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
    try {
        1/0
    } catch {
        throw
    }
}


try {
    GrandParent
} catch {
    $ex = $PSItem
    Write-Warning "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
}