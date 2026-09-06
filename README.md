# Testing Artifactory as a source for github-released app usage via mise

On any System (Windows using GitBash)

The Compose file includes a fixed development-only Artifactory master key. Set
`JF_SHARED_SECURITY_MASTERKEY` before starting the stack to supply your own
stable 32-character key.

On a POSIX shell, generate and export one with:

```shell
export JF_SHARED_SECURITY_MASTERKEY="$(openssl rand -hex 16)"
```

Keep the generated value somewhere secure and reuse it whenever you start the
same Artifactory data volume.

Run `mise run proquint-fetch` before using the mirrored tool. If credentials
are missing or rejected, it prints the Artifactory "Set Me Up" token workflow
and a copyable heredoc command to create the dedicated
`~/.mise-artifactory.netrc` file. Bash is required and is provided by Git Bash
on Windows.

The project `mise.toml` redirects downloads for `github:iilei/proquint@0.2.8`
to the seeded Artifactory path. Version discovery still uses GitHub's release
metadata.

Artifactory is pinned to `7.104.12` because the current `latest` OSS image can
leave its web frontend retrying failed entitlement requests. Do not downgrade
an existing Artifactory database; use the cleanup commands below before
starting this test stack after the version change.

```shell
docker compose up -d
# Wait until the service is healthy, then seed it from Git Bash:
docker compose ps
bash ./seed.sh
```

Visit [JFrog Web UI](http://localhost:8082/ui/)

```
Username: admin
Password: password
```

Or Test using Curl

```
curl -u admin:password -O \
  http://localhost:8081/artifactory/example-repo-local/proquint/0.2.8/proquint_0.2.8_windows_amd64.zip
```

```shell
# Stop and remove containers + network
docker compose down

docker volume rm mise_test_artifactory_data  
docker volume rm mise_test_postgresql_data
```

```shell
mise run proquint-decode gabun
```

## Round-Trip

```shell
mise run proquint-encode $(mise run proquint-decode gabun)
```

## Verify Install location

```powershell
mise exec "github:iilei/proquint@0.2.8" -- where proquint
```
