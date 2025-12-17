#!/usr/bin/env python3

import os
import sys
import argparse
from pathlib import Path

def fix_symlink_target(symlink_path, dry_run=False):
    """
    Fix a symlink by removing ../ sequences and adding PWD as prefix
    """
    try:
        current_target = os.readlink(symlink_path)
        
        # Remove all ../ sequences
        new_target = current_target.replace('../', '')
        
        # Get current working directory
        pwd = os.getcwd()
        
        # Construct the new absolute path
        absolute_target = os.path.join(pwd, new_target)
        
        # Normalize the path to remove any redundant components
        absolute_target = os.path.normpath(absolute_target)
        
        if dry_run:
            print(f"Would fix: {symlink_path}")
            print(f"  Current: {current_target}")
            print(f"  New:     {absolute_target}")
            print()
        else:
            # Remove the old symlink and create a new one
            os.unlink(symlink_path)
            os.symlink(absolute_target, symlink_path)
            print(f"Fixed: {symlink_path} -> {absolute_target}")
            
        return True
        
    except Exception as e:
        print(f"Error processing {symlink_path}: {e}")
        return False

def find_and_fix_broken_symlinks(start_path='.', dry_run=False):
    """
    Find all broken symlinks and fix them
    """
    broken_count = 0
    fixed_count = 0
    
    for root, dirs, files in os.walk(start_path):
        for item in files + dirs:
            full_path = os.path.join(root, item)
            
            # Check if it's a symlink
            if os.path.islink(full_path):
                target_path = os.path.join(root, os.readlink(full_path))
                
                # Check if the symlink is broken (target doesn't exist)
                if not os.path.exists(target_path):
                    broken_count += 1
                    print(f"Found broken symlink: {full_path}")
                    print(f"  Target: {os.readlink(full_path)}")
                    
                    if fix_symlink_target(full_path, dry_run):
                        fixed_count += 1
                    print()
    
    print(f"Summary:")
    print(f"  Broken symlinks found: {broken_count}")
    print(f"  Fixed symlinks: {fixed_count}")

def main():
    parser = argparse.ArgumentParser(
        description='Find and fix broken symlinks by removing ../ and adding PWD prefix'
    )
    parser.add_argument(
        'path',
        nargs='?',
        default='.',
        help='Starting path to search for broken symlinks (default: current directory)'
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Show what would be fixed without making changes'
    )
    parser.add_argument(
        '--fix-single',
        help='Fix a single symlink (provide the symlink path)'
    )
    
    args = parser.parse_args()
    
    if args.fix_single:
        # Fix a single symlink
        if not os.path.islink(args.fix_single):
            print(f"Error: {args.fix_single} is not a symlink")
            sys.exit(1)
        
        fix_symlink_target(args.fix_single, args.dry_run)
    else:
        # Find and fix all broken symlinks in the directory tree
        if not os.path.exists(args.path):
            print(f"Error: Path {args.path} does not exist")
            sys.exit(1)
        
        find_and_fix_broken_symlinks(args.path, args.dry_run)

if __name__ == "__main__":
    main()
