set -e

zig build -Doptimize=ReleaseFast
zig build test

echo "Installing klarc..."
cp zig-out/bin/* $HOME/.local/bin
echo "OK"
