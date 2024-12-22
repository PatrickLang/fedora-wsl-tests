# End to end tests for Fedora in WSL

This is a simple set of end to end tests that aim to:

- Install a Fedora build using a .tar.xz or .wsl file
- Verify the user was set up as expected
- Test some basic functionality (sudo, dnf)

## Running the tests

```
Set-ExecutionPolicy -scope Process -ExecutionPolicy bypass
Invoke-Pester -Script .\test-fedora-wsl.ps1 -OutputFormat NUnitXml -OutputFile results.xml
```

## Contributing

This script was written for the least-common-denominator of Windows 10 10.0.22631 and WSL 2.3.26.0, or higher.

It depends on the [pester](https://pester.dev) framework for organizing test cases and assertions, and it is capable of producing NUnit-style output. Windows 10 shipped with Pester 3.4.0 built-in so the test cases have been written to use that version instead of the latest. The assertions are much more limited than the current version, so look at the [Should-v3](https://github.com/pester/Pester/wiki/Should-v3) page instead to see what is supported.
