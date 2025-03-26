$variableInScriptScope = 'Hi from scriptScope'

function foo {
    $variableInFunctionScope = 'Hi from functionScope'

    $variableInFunctionScope
    $variableInScriptScope
    $variableFromGlobalScope
}
foo