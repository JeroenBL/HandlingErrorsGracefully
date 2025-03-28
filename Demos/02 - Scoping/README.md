At its most fundamental level, scoping is nothing more then a mechanism to resolve variables and functions, where a scope is just a region where we define those variables and functions.

- **Global**
  Available as soon as a new shell or runspace (e.g., PowerShell console) is started.

- **Script**
  Contains all scopeable entities defined _at the script level_.

- **Local**
  The currently active scope.

- **Function**
  Contains all scopeable entities defined _at the function level_.