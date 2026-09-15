#!/bin/sh

# Install helper for Z3 used by the baseline reimplementation.
# This script copies the Z3 binaries and libraries into system locations
# and updates the user's environment so `z3` can be invoked from the shell.

# Path to the Z3 build shipped with the repo (adjust if you move files).
Z3_DIR="$(pwd)/baselines/accessanalyzer-reimpl/lib/z3-4.14.1/bin"

# Expected version string from `z3 -version` for sanity check.
EXPECTED_VERSION="Z3 version 4.14.1 - 64 bit"

# Copy shared libraries to a system library folder so programs can link.
sudo cp "$Z3_DIR/libz3.so" "$Z3_DIR/libz3java.so" /usr/lib/

# Install the `z3` executable into a system-wide bin directory.
sudo cp "$Z3_DIR/z3" /usr/bin/

# Ensure the user's local bin exists, then copy `z3` there as well
# so it's available without sudo for that user.
if [ ! -d "$HOME/.local/bin" ]; then
	sudo mkdir -p "$HOME/.local/bin"
fi
sudo cp "$Z3_DIR/z3" "$HOME/.local/bin/"

# Refresh the dynamic linker cache so the new libraries are found.
sudo ldconfig

echo "Copied Z3 files to:"
echo "- /usr/lib"
echo "- /usr/bin"
echo "- $HOME/.local/bin"

# Make sure the system z3 is executable.
sudo chmod +x /usr/bin/z3

# Add the Z3 lib directory to LD_LIBRARY_PATH in the user's shell profile
# if it's not already present. This helps native code find `libz3.so`.
LD_EXPORT_LINE="export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:$Z3_DIR"
if ! grep -Fq "$LD_EXPORT_LINE" "$HOME/.bashrc"; then
	echo "$LD_EXPORT_LINE" >> "$HOME/.bashrc"
fi

# Export for current shell so subsequent commands in this script can use it.
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$Z3_DIR"
echo "Added LD_LIBRARY_PATH to ~/.bashrc"

# Verify installation by checking `z3` version string.
version_output="$(z3 -version 2>/dev/null | head -n1)"

if [ "$version_output" = "$EXPECTED_VERSION" ]; then
	echo "$version_output"
	echo "Z3 installation is correct."
else
	echo "Z3 version check failed."
	echo "Expected: $EXPECTED_VERSION"
	echo "Actual: ${version_output:-<empty>}"
	exit 1
fi