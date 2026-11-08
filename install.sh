set -e

zig build

echo "Installing klarc..."
cp zig-out/bin/* $HOME/.local/bin
echo "OK"
