$variableFromGlobalScope #Defined in global scope

$variableInScriptScope = 'Hello from Script Scope'

function foo {
    $variableInScriptScope
    $variableInFunctionScope = 'Hello from Function Scope'
    $variableInFunctionScope
}
foo