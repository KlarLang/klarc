set -e

PATH_=$HOME/.local/bin

zig build #-Doptimize=ReleaseFast
zig build test

echo "Installing klarc..."
cp zig-out/bin/* $PATH_
echo "OK"
echo "Put $PATH_ in your PATH if you want to run klarc from anywhere"
