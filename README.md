# ACMS config

Basic Git repo initialized with demo content for the [ACMS](https://github.com/artcom/acms-compose).

## Usage

```bash
docker build -t artcom/acms-config .
docker run artcom/acms-config
```

### Build Arguments

| Argument         | Default | Description                                                          |
| ---------------- | ------- | -------------------------------------------------------------------- |
| `DEFAULT_BRANCH` | `main`  | Name of the Git branch created in the bare repository at build time. |

```bash
docker build --build-arg DEFAULT_BRANCH=master -t artcom/acms-config .
```

## Default Branch

The bare Git repository is initialized at build time with a branch named after the `DEFAULT_BRANCH` build argument (default: `main`).

At container startup, the entrypoint script `50-set-default-branch.sh` reconciles the repository's branch name with the `DEFAULT_BRANCH` environment variable. If the names differ it renames the branch in-place (by moving the ref and updating `HEAD`) so that clients always see the configured name as the default branch, regardless of what was baked in at build time.

## Configuration Change Hook

When a push is accepted into the bare Git repository, a `post-receive` hook publishes an MQTT event to `<BASE_TOPIC>/onConfigurationChange`.

The hook is installed globally via `core.hooksPath` during the Docker build — no per-repository symlink is needed.

### Payload

One message is published per updated ref:

```json
{
  "refName": "refs/heads/master",
  "changedFiles": [
    "config/content/pages/page001/index.json",
    "config/content/pages/page002/index.json"
  ]
}
```

| Field          | Type       | Description                                                                                       |
| -------------- | ---------- | ------------------------------------------------------------------------------------------------- |
| `refName`      | `string`   | Fully-qualified Git ref that was updated (e.g. `refs/heads/master`).                              |
| `changedFiles` | `string[]` | Paths of files that differ between the old and new commit, as returned by `git diff --name-only`. |

### Environment Variables

| Variable         | Default | Description                                                                                                   |
| ---------------- | ------- | ------------------------------------------------------------------------------------------------------------- |
| `DEFAULT_BRANCH` | `main`  | Default Git branch name. Initialized at build time; reconciled at container startup if overridden at runtime. |
| `TCP_BROKER_URI` | `null`  | MQTT broker URI (e.g. `mqtt://10.0.0.1`). Set to `null` to disable the hook entirely.                         |
| `BASE_TOPIC`     | `root`  | Base MQTT topic. The change event is published to `<BASE_TOPIC>/onConfigurationChange`.                       |
