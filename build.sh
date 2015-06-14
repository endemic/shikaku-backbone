#!/bin/sh

# Remove previous build directory
rm -rf build

# Concatenate source
node tools/r.js -o build.js

# Optimize w/ Closure Compiler
java -jar tools/compiler.jar --js build/src/main.js --js_output_file build/src/main-compiled.js
# java -jar tools/compiler.jar --compilation_level ADVANCED_OPTIMIZATIONS --js build/src/main.js --js_output_file build/src/main-compiled.js

# Remove .svn directories from the build dir
echo "Removing .svn directories..."
rm -rf `find ./build -type d -name .svn`

echo "Removing .DS_Store files"
rm -rf `find ./build -type f -name .DS_Store`

echo "Copying to packaged Firefox OS app"
cp build/src/main-compiled.js firefox/src/main-compiled.js
cp -R build/assets firefox

# Copy to Mac app
# echo "Copying to Mac app..."
# cp build/src/main-compiled.js ~/ganbarugames/apps/shikaku-madness-mac/Shikaku\ Madness/www/src/main-compiled.js
# cp -R build/assets ~/ganbarugames/apps/shikaku-madness-mac/Shikaku\ Madness/www

# Copy to iOS app (full)
# echo "Copying to iOS app (full)..."
# cp build/src/main-compiled.js ~/ganbarugames/apps/shikaku-madness-ios/www/src/main-compiled.js
# cp -R build/assets ~/ganbarugames/apps/shikaku-madness-ios/www

# Copy to iOS app (free)
# echo "Copying to iOS app (free)..."
# cp build/src/main-compiled.js ~/ganbarugames/apps/shikaku-madness-free-ios/www/src/main-compiled.js
# cp -R build/assets ~/ganbarugames/apps/shikaku-madness-free-ios/www

echo "Copying to QNX app"
cp build/src/main-compiled.js blackberry/www/javascript/main-compiled.js
cp -R build/assets blackberry/www

echo "Copying to Android app..."
cp build/src/main-compiled.js android/assets/www/src/main-compiled.js
cp -R build/assets android/assets/www

echo 'Done!'