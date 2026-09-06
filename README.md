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

## Internal mise Backend

For company-owned tools, GitLab is used for source control and release tags, while Artifactory is the internal distribution point for the actual binaries.

The intended architecture is:

```text
                         Internal GitLab
                              │
                              │ Git tags
                              │ v1.2.3
                              ▼
                    Company mise backend
                              │
                              │ version discovery
                              │ platform selection
                              ▼
                         Artifactory
                              │
                              │ GoReleaser artifacts
                              ▼
                         Developer
                              │
                              ▼
                            mise
```

### Repository and release convention

Each application follows standard GoReleaser conventions:

```text
<gitlab-host>/<group>/<repo-name>
```

Releases are created by pushing a SemVer tag prefixed with `v`:

```text
v1.2.3
```

GoReleaser publishes the resulting archives, checksums, and signatures to Artifactory.

For example:

```text
<artifactory-host>/<artifactory-repo>/<repo-name>/<app-name>/1.2.3/
    <app-name>_1.2.3_Linux_x86_64.tar.gz
    <app-name>_1.2.3_Linux_arm64.tar.gz
    <app-name>_1.2.3_Darwin_arm64.tar.gz
    ...
    checksums.txt
    *.sig
```

Multiple applications can be published from the same repository and share the same release version.

### Internal mise plugin

A company-specific mise backend/plugin can encapsulate these conventions:

```text
GitLab
  │
  └── tag v1.2.3
        │
        ▼
  company mise backend
        │
        ├── version = 1.2.3
        ├── app = <app-name>
        ├── OS = Linux
        └── architecture = x86_64
              │
              ▼
  Artifactory
        │
        └── <repo-name>/<app-name>/1.2.3/
              <app-name>_1.2.3_Linux_x86_64.tar.gz
```

The backend can therefore translate the company's GitLab and GoReleaser conventions into the corresponding Artifactory artifact URL.

### Distributing the backend

Because the network is restricted, the plugin does not need to be published to the public mise plugin ecosystem.

It can live in a private company GitLab repository:

```text
<gitlab-host>/<group>/mise-backend-company-tools
```

and be referenced directly from `mise.toml`:

```toml
[plugins]
company = "git@<gitlab-host>:<group>/mise-backend-company-tools.git#<commit-sha>"

[tools]
"company:<app-name>" = "1.2.3"
```

The plugin itself is therefore distributed through the company's existing internal Git infrastructure, while the actual application binaries continue to be distributed through Artifactory.

```text
Private GitLab
     │
     │ company mise backend
     ▼
   mise
     │
     │ artifact download
     ▼
 Artifactory
     │
     │ GoReleaser binaries
     ▼
 developer machine
```

This keeps GitLab responsible for **source code and versioning**, the mise backend responsible for **company-specific resolution**, and Artifactory responsible for **binary distribution**.
