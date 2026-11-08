set -e

zig build 
zig build test

echo "Installing klarc..."
cp zig-out/bin/* $HOME/.local/bin
echo "OK"
