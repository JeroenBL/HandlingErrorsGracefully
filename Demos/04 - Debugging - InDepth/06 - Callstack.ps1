function GrandParent {
    'GrandParent called and calling Parent'
    Parent
}

function Parent {
    'Parent called and calling Child'
    Child
}

function Child {
    'Child called'
    # Set a breakpoint here to inspect the call stack
    $i = 42
}

# Entry point
GrandParent