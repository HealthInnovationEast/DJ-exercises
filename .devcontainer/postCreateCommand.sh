#!/bin/bash

set -ue
set -o pipefail

pip install --upgrade pip

## global install of pre-commit
pip install pre-commit
pre-commit install --install-hooks
