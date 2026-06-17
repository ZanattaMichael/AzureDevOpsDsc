# Developer scripts

Convenience scripts for working on this repository locally. They are **not** part of
the build or CI pipeline (use [`build.ps1`](../build.ps1) and `Invoke-Pester` for
that — see the [tests README](../tests/README.md)).

Each script derives the repository root from its own location, so they can be run
from anywhere.

| Script | Purpose |
|--------|---------|
| `run-tests.ps1` | Run the unit tests. |
| `run-tests-quick.ps1` | Run a focused subset of unit tests for faster iteration. |
| `run-tests-detailed.ps1` | Run the unit tests with detailed/verbose output. |
