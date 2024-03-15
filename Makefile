#!/bin/bash
DOCS_ROOT=dist/docs/
REPO_NAME="ooni/backend"
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
# to edit go to: https://github.com/$REPO_NAME/edit/master/README.md
# version: $REPO_NAME:$COMMIT_HASH
title: My Documentation Title
description: My Documentation Description
slug: mydocs
---
EOF
strip_title README.md >> $DOCS_ROOT/00-index.md