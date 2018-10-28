#!/bin/bash
echo "Building elm..."
echo "-._.-~-._.-~-._.->"
elm make frontend/Main.elm --output=static/elm.js

echo "-._.-~-._.-~-._.->"
echo "Running elixir..."
mix run --no-halt

