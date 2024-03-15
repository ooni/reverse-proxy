#!/bin/bash
DOCS_ROOT=dist/docs/
REPO_NAME="ooni/devops"
COMMIT_HASH=$(git rev-parse --short HEAD)

mkdir -p $DOCS_ROOT

strip_title() {
    # Since the title is already present in the frontmatter, we need to remove
    # it to avoid duplicate titles
    local infile="$1"
    cat $infile | awk 'BEGIN{p=1} /^#/{if(p){p=0; next}} {print}'
}

cat <<EOF>$DOCS_ROOT/00-index.md
---
# Do not edit! This file is automatically generated
# to edit go to: https://github.com/$REPO_NAME/edit/main/README.md
# version: $REPO_NAME:$COMMIT_HASH
title: OONI Devops
description: OONI Devops
slug: devops
---
EOF
strip_title README.md >> $DOCS_ROOT/00-index.md

cat <<EOF>$DOCS_ROOT/01-iac.md
---
# Do not edit! This file is automatically generated
# to edit go to: https://github.com/$REPO_NAME/edit/main/tf/README.md
# version: $REPO_NAME:$COMMIT_HASH
title: OONI Devops IaC
description: OONI Devops IaC Documentation
slug: devops/iac
---
EOF
strip_title tf/README.md >> $DOCS_ROOT/01-iac.md

cat <<EOF>$DOCS_ROOT/02-configuration-management.md
---
# Do not edit! This file is automatically generated
# to edit go to: https://github.com/$REPO_NAME/edit/main/ansible/README.md
# version: $REPO_NAME:$COMMIT_HASH
title: OONI Devops Configuration Management
description: OONI Devops Configuration Management Documentation
slug: devops/configuration-management
---
EOF
strip_title ansible/README.md >> $DOCS_ROOT/02-configuration-management.md