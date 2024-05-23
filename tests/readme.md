# Tests Suites

### Running
To run a testsuite manually, from the base folder run:
`scripts/run_testsuite.sh tests/{chosen suite}.yaml`

### Creation
To create a new test-suite, create a new file here named `*.testsuite.yaml`. When using the devcontainer, the schema at `.devcontainer/test_schema.json` is enforced. Each block describes a combination of the following to be run:
 - Collection
 - Folder
 - Collection Environment
 - Environment Override

#### Using Environment Overrides

Bruno handles the passing of additional variables from the command line like:
`bru run folder --env Local --env-var JWT_TOKEN=1234`
We expose this within the test suite to allow the passing of secrets or other more dynamic values from the host environment in a CI/CD system.

Given this example block:
```yaml
- collection: Demo-0
  folder: Valid
  environment: Demo-0
  env_override:
    JWT_TOKEN: SECRET_JWT_TOKEN
```
The test call would look like this:
`bru run Valid --env Demo-0 --env-var JWT_TOKEN=${SECRET_JWT_TOKEN}`
and the value for `JWT_TOKEN` would be pulled from the host environment from `SECRET_JWT_TOKEN` as is typical in CI runners.

Be aware: The test suite runner does not itself leak secrets that are passed via env in logs. However if you use a secret as the expcted value of an assertion that fails, bruno will output it in the test log for the failure.

### CI / CD
This demo repository is setup such that on Pull Request, all tests in `ci.testsuite.yaml` must pass before merges are approved. This is configurable in `.github/workflows`. Test-suites can be easily matrixed for more speed in parallel.
