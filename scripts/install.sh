#!/bin/bash
# ===========================================================================
# install.sh — Install system dependencies and configure language runtimes.
#
# Usage:
#   cd scripts && bash install.sh
# ===========================================================================

set -e

sudo apt-get update
sudo apt-get install -y python3 unzip zip git
pip install numpy deepdiff

python3 configureLocalEnvironment.py
