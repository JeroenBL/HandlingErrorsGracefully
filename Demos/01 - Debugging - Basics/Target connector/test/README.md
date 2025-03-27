## CustomList class

The `CustomList`  class is a wrapper class around the `outputContext.Auditlogs`. Its responsible for displaying GUI messages within VSCode.

## .Source
Everytime the `debugStart.ps1` is being executed. The variables within become available in the _global_ scope.
The _global_ scope is the scope available when you start a new PowerShell console or; runspace. A _runspace_ is a
fancy word for the place where our code will executed.

On this runspace, we have a `$executionContext`. This object is an object that also has a state. Or; _SessionState_.
The _SessionState_ contains a dictionary for all the scoped entities.

__DEMO in Windows PowerShell with reflection enabled__

- . source the `debugStart.ps1`.
- Get-Variable - to demonstrate the variables are there.
- $ExecutionContext.SessionState.sessionState.GlobalScope.Variables['actionContext']