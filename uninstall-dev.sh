#!/usr/bin/env bash

# ================================================================= #
# AzuraCast Developer Uninstall & Clean Script
# ================================================================= #

# Ensure the script exits if any command fails (except docker commands which might fail if docker is not running)
set -u

echo "========================================================="
echo "   AzuraCast Developer Uninstall & Deep Clean Script"
echo "========================================================="
echo "This script will completely remove all containers, volumes,"
echo "networks, images, untracked dependencies, and config files."
echo "========================================================="

# Move to the repository root directory (where this script is located)
cd "$( dirname "${BASH_SOURCE[0]}" )" || exit 1

# Check if Docker is installed and running
DOCKER_ACTIVE=0
if command -v docker &> /dev/null; then
    if docker info &> /dev/null; then
        DOCKER_ACTIVE=1
    else
        echo "⚠️ Docker is installed but it doesn't seem to be running."
    fi
else
    echo "⚠️ Docker is not installed on this system."
fi

if [ "$DOCKER_ACTIVE" -eq 1 ]; then
    echo "--- Stopping and removing AzuraCast Docker Resources ---"
    if docker compose version &> /dev/null; then
        docker compose down -v --rmi all --remove-orphans
    else
        docker-compose down -v --rmi all --remove-orphans
    fi

    echo "--- Performing Deep System Prune (Docker) ---"
    echo "Removing all unused containers, networks, images, and volumes..."
    docker system prune -a -f --volumes
else
    echo "Skipping Docker cleanup as Docker daemon is not active."
fi

echo "--- Cleaning Repository of Untracked Files & Folders ---"
echo "Removing vendor/, node_modules/, config files (.env, docker-compose.yml), and other untracked artifacts..."

# git clean -fdx deletes all untracked files and directories.
# We exclude 'uninstall-dev.sh' to prevent the script from deleting itself during execution.
if git rev-parse --is-inside-work-tree &> /dev/null; then
    git clean -fdx -e uninstall-dev.sh
    echo "✅ Git repository cleaned back to pristine state."
else
    echo "⚠️ Not inside a Git repository. Skipping git clean."
fi

# Remove the production installation folder (/var/azuracast) if it exists
if [ -d "/var/azuracast" ]; then
    echo "--- Removing Production Installation Directory (/var/azuracast) ---"
    if [ "$EUID" -ne 0 ] && command -v sudo &> /dev/null; then
        sudo rm -rf /var/azuracast
    else
        rm -rf /var/azuracast
    fi
    echo "✅ Production installation directory /var/azuracast removed."
fi

echo "========================================================="
echo "✅ Uninstall and Clean Complete!"
echo "========================================================="
