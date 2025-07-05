#!/usr/bin/env python3
"""
Script to download packages from collection.json and switch to specified versions.
Reads the collection.json file, extracts package URLs and versions,
then clones each repository and switches to the specified version tag.
"""

import json
import os
import subprocess
import sys
from pathlib import Path
from urllib.parse import urlparse


def run_command(command, cwd=None, check=True, show_output=False):
    """Run a shell command and return the result."""
    try:
        # Set proxy environment variables
        env = os.environ.copy()
        env.update({
            'https_proxy': 'http://127.0.0.1:7890',
            'http_proxy': 'http://127.0.0.1:7890',
            'all_proxy': 'socks5://127.0.0.1:7890'
        })
        
        if show_output:
            # Run command with real-time output
            process = subprocess.Popen(
                command,
                shell=True,
                cwd=cwd,
                env=env,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
                universal_newlines=True
            )
            
            # Print output in real-time
            for line in process.stdout:
                print(line.rstrip())
            
            process.wait()
            return process
        else:
            result = subprocess.run(
                command,
                shell=True,
                cwd=cwd,
                check=check,
                capture_output=True,
                text=True,
                env=env
            )
            return result
    except subprocess.CalledProcessError as e:
        print(f"Error running command: {command}")
        print(f"Error: {e}")
        return e


def get_repo_name_from_url(url):
    """Extract repository name from git URL."""
    # Remove .git suffix if present
    if url.endswith('.git'):
        url = url[:-4]
    
    # Parse the URL to get the path
    parsed = urlparse(url)
    path_parts = parsed.path.strip('/').split('/')
    
    # Return the last part as the repo name
    return path_parts[-1] if path_parts else "unknown"


def clone_and_checkout_package(url, version, output_dir="packages", current_package=1, total_packages=1):
    """Clone a package and checkout the specified version."""
    # Create output directory if it doesn't exist
    Path(output_dir).mkdir(exist_ok=True)
    
    # Get repository name from URL
    repo_name = get_repo_name_from_url(url)
    repo_path = Path(output_dir) / repo_name
    
    print(f"\n{'='*60}")
    print(f"Progress: [{current_package}/{total_packages}]")
    print(f"Processing: {repo_name}")
    print(f"URL: {url}")
    print(f"Version: {version}")
    print(f"{'='*60}")
    
    # Check if repository already exists
    if repo_path.exists():
        print(f"📁 Repository {repo_name} already exists. Updating...")
        
        # Fetch latest changes
        print("🔄 Fetching latest changes...")
        result = run_command("git fetch --all --progress", cwd=repo_path, check=False, show_output=True)
        if result.returncode != 0:
            print(f"⚠️  Warning: Failed to fetch updates for {repo_name}")
    else:
        print(f"📥 Cloning {repo_name}...")
        # Use git clone with real-time progress display
        result = run_command(f"git clone --progress {url} {repo_name}", cwd=output_dir, show_output=True)
        if result.returncode != 0:
            print(f"❌ Error: Failed to clone {repo_name}")
            return False
        print(f"✅ Successfully cloned {repo_name}")
    
    # Checkout the specified version as a tag
    print(f"🏷️  Checking out tag: {version}")
    
    # First, fetch all tags to make sure we have the latest
    print("🔄 Fetching all tags...")
    result = run_command("git fetch --tags", cwd=repo_path, check=False, show_output=True)
    if result.returncode != 0:
        print(f"⚠️  Warning: Failed to fetch tags for {repo_name}")
    
    # Try to checkout the version as a tag
    result = run_command(f"git checkout {version}", cwd=repo_path, show_output=True)
    if result.returncode != 0:
        print(f"❌ Error: Failed to checkout tag {version} for {repo_name}")
        print(f"Trying alternative checkout methods...")
        
        # Try checking out with 'tags/' prefix
        result = run_command(f"git checkout tags/{version}", cwd=repo_path, show_output=True)
        if result.returncode != 0:
            # Try with 'v' prefix (common for version tags)
            v_version = f"v{version}"
            print(f"Trying with 'v' prefix: {v_version}")
            result = run_command(f"git checkout {v_version}", cwd=repo_path, show_output=True)
            if result.returncode != 0:
                result = run_command(f"git checkout tags/{v_version}", cwd=repo_path, show_output=True)
                if result.returncode != 0:
                    print(f"❌ Error: Failed to checkout tag {version} or {v_version} for {repo_name}")
                    return False
    
    # Verify the checkout
    result = run_command("git describe --tags --exact-match", cwd=repo_path, check=False)
    if result.returncode == 0:
        current_tag = result.stdout.strip()
        print(f"✅ Successfully checked out tag: {current_tag}")
    else:
        # Try to get current commit hash
        result = run_command("git rev-parse HEAD", cwd=repo_path, check=False)
        if result.returncode == 0:
            current_commit = result.stdout.strip()[:8]
            print(f"✅ Successfully checked out commit: {current_commit}")
        else:
            print(f"⚠️  Warning: Could not verify checkout for {repo_name}")
    
    print(f"✅ Package {repo_name} completed successfully!")
    return True


def main():
    """Main function to process the collection.json file."""
    # Check if collection.json exists
    if not Path("collection.json").exists():
        print("Error: collection.json not found in current directory")
        sys.exit(1)
    
    # Read the collection.json file
    try:
        with open("collection.json", "r", encoding="utf-8") as f:
            data = json.load(f)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON in collection.json: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"Error reading collection.json: {e}")
        sys.exit(1)
    
    # Extract packages
    packages = data.get("packages", [])
    if not packages:
        print("Error: No packages found in collection.json")
        sys.exit(1)
    
    print(f"Found {len(packages)} packages in collection.json")
    print(f"Starting download process...")
    print(f"{'='*60}")
    
    # Process each package
    successful = 0
    failed = 0
    
    for i, package in enumerate(packages, 1):
        # Extract package information
        url = package.get("url")
        versions = package.get("versions", [])
        
        if not url:
            print(f"⚠️  Warning: No URL found for package {i}")
            failed += 1
            continue
        
        if not versions:
            print(f"⚠️  Warning: No versions found for package {i}")
            failed += 1
            continue
        
        # Get the first version (you can modify this logic if needed)
        version_info = versions[0]
        version = version_info.get("version")
        
        if not version:
            print(f"⚠️  Warning: No version found for package {i}")
            failed += 1
            continue
        
        # Clone and checkout the package
        if clone_and_checkout_package(url, version, current_package=i, total_packages=len(packages)):
            successful += 1
        else:
            failed += 1
    
    # Summary
    print(f"\n{'='*60}")
    print("SUMMARY")
    print(f"{'='*60}")
    print(f"Total packages: {len(packages)}")
    print(f"Successful: {successful}")
    print(f"Failed: {failed}")
    print(f"Packages downloaded to: packages/")
    
    if failed > 0:
        print(f"\nWarning: {failed} packages failed to process")
        sys.exit(1)
    else:
        print(f"\nAll packages processed successfully!")


if __name__ == "__main__":
    main() 