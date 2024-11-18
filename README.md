# synchronize-pointag
A reusable workflow which automatically creates and synchronizes pointer tags ("pointags") when tags are created, updated, or deleted.

## Installation
Add a new workflow under `.github/workflows/` with the following contents,
```yml
name: Synchronize Pointag

on:
  delete:

  push:
    tags:
      - '**'

jobs:
  synchronize-pointag:
    permissions:
      contents: write
    uses: Arthri/synchronize-pointag/.github/workflows/i.yml@v2
```

> [!NOTE]
> `on.push` is used over `on.create` primarily for two reasons:
> 1. `on.create` is noisier because it does not support filtering by tags or branches, and consequently, always triggers when new branches are pushed.
> 1. `on.create` is not triggered by tag updates.
> 
> Furthermore, `on.delete` is used because `on.push` is not triggered by tag deletions. Unfortunately, it does not support filtering similar to `on.create` and triggers even when branches are deleted.

## Usage
1. Create and push a new tag. For example, `v1.4.2`, `Test.App/v2.5.3`.
1. Expect the workflow to run and create a tag such as `v1` or `Test.App/v2` in a few moments.

A list of tags and their corresponding pointags are provided for reference below.
- `v1.12.0` → `v1`
- `v1.56.8` → `v1`
- `v2.11` → `v2`
- `TagDirectory/v3.4.0` → `TagDirectory/v3`
- `Tag/With/Path/v3.11.0` → `Tag/With/Path/v3`
- `Tag/With/Path/v3.56` → `Tag/With/Path/v3`

> [!WARNING]
> Although discouraged, pointags may be manually updated. The workflow will detect the update but will terminate and do nothing.
