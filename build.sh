#!/bin/bash

# Programming Tools Suite - Mobile Build Script
# This script automates the build process for native mobile deployment

set -e  # Exit on any error

echo "🚀 Programming Tools Suite - Mobile Build Script"
echo "=============================================="

# Function to print colored output
print_status() {
    echo -e "\033[1;34m$1\033[0m"
}

print_success() {
    echo -e "\033[1;32m✅ $1\033[0m"
}

print_error() {
    echo -e "\033[1;31m❌ $1\033[0m"
}

print_warning() {
    echo -e "\033[1;33m⚠️  $1\033[0m"
}

# Check if we're in the right directory
if [ ! -f "package.json" ] || [ ! -f "capacitor.config.ts" ]; then
    print_error "Error: Not in the correct directory. Please run this script from the Web app directory."
    exit 1
fi

# Function to install dependencies
install_dependencies() {
    print_status "Installing Node.js dependencies..."
    if npm install; then
        print_success "Dependencies installed successfully"
    else
        print_error "Failed to install dependencies"
        exit 1
    fi
}

# Function to add mobile platforms
add_platforms() {
    print_status "Adding mobile platforms..."

    # Add Android platform
    if [ -d "android" ]; then
        print_warning "Android platform already exists"
    else
        print_status "Adding Android platform..."
        if npx cap add android; then
            print_success "Android platform added"
        else
            print_error "Failed to add Android platform"
            exit 1
        fi
    fi

    # Add iOS platform (if on macOS)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if [ -d "ios" ]; then
            print_warning "iOS platform already exists"
        else
            print_status "Adding iOS platform..."
            if npx cap add ios; then
                print_success "iOS platform added"
            else
                print_warning "Failed to add iOS platform (may require Xcode setup)"
            fi
        fi
    else
        print_warning "iOS platform not available (requires macOS)"
    fi
}

# Function to sync web assets
sync_assets() {
    print_status "Syncing web assets to native projects..."

    if npx cap sync; then
        print_success "Web assets synced successfully"
    else
        print_error "Failed to sync web assets"
        exit 1
    fi
}

# Function to build for Android
build_android() {
    if [ ! -d "android" ]; then
        print_error "Android platform not found. Run platform setup first."
        return 1
    fi

    print_status "Building for Android..."

    # Check if device/emulator is available
    if adb devices | grep -q "device$"; then
        print_status "Android device detected. Deploying..."
        if npx cap run android; then
            print_success "Android app deployed successfully"
        else
            print_error "Failed to deploy Android app"
            return 1
        fi
    else
        print_warning "No Android device detected. Opening in Android Studio..."
        if npx cap open android; then
            print_success "Android Studio opened. Please build and run manually."
        else
            print_error "Failed to open Android Studio"
            return 1
        fi
    fi
}

# Function to build for iOS
build_ios() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_warning "iOS build only available on macOS"
        return 0
    fi

    if [ ! -d "ios" ]; then
        print_error "iOS platform not found. Run platform setup first."
        return 1
    fi

    print_status "Building for iOS..."

    # Check if simulator is available
    if xcodebuild -workspace ios/App/App.xcworkspace -scheme "App" -destination "platform=iOS Simulator,name=iPhone 14" build > /dev/null 2>&1; then
        print_status "iOS simulator detected. Deploying..."
        if npx cap run ios; then
            print_success "iOS app deployed successfully"
        else
            print_error "Failed to deploy iOS app"
            return 1
        fi
    else
        print_warning "iOS simulator not available. Opening in Xcode..."
        if npx cap open ios; then
            print_success "Xcode opened. Please build and run manually."
        else
            print_error "Failed to open Xcode"
            return 1
        fi
    fi
}

# Function to create app icons (placeholder)
create_icons() {
    print_status "Checking for app icons..."

    if [ ! -d "icons" ]; then
        print_warning "Icons directory not found"
        print_status "Creating icons directory..."
        mkdir -p icons
    fi

    # Check if icons exist
    if [ -f "icons/icon-192x192.png" ] && [ -f "icons/icon-512x512.png" ]; then
        print_success "App icons found"
    else
        print_warning "App icons not found. Please create the following PNG files in the icons/ directory:"
        echo "  - icon-72x72.png, icon-96x96.png, icon-128x128.png"
        echo "  - icon-144x144.png, icon-152x152.png, icon-192x192.png"
        echo "  - icon-384x384.png, icon-512x512.png"
        echo ""
        echo "Use online tools like:"
        echo "  - https://realfavicongenerator.net/"
        echo "  - https://favicon.io/"
    fi
}

# Main build process
main() {
    print_status "Starting build process..."

    # Step 1: Install dependencies
    install_dependencies

    # Step 2: Create/check icons
    create_icons

    # Step 3: Add platforms
    add_platforms

    # Step 4: Sync assets
    sync_assets

    # Step 5: Build options
    echo ""
    print_status "Build Options:"
    echo "1) Build for Android only"
    echo "2) Build for iOS only (macOS required)"
    echo "3) Build for both platforms"
    echo "4) Skip building (setup only)"
    echo ""
    read -p "Enter your choice (1-4): " choice

    case $choice in
        1)
            build_android
            ;;
        2)
            build_ios
            ;;
        3)
            build_android && build_ios
            ;;
        4)
            print_success "Setup complete! You can now build manually using:"
            echo "  npx cap run android  # For Android"
            echo "  npx cap run ios     # For iOS"
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac

    echo ""
    print_success "Build process completed!"
    echo ""
    print_status "Next steps:"
    echo "📱 Test your apps on devices/emulators"
    echo "🎨 Customize app icons in the icons/ directory"
    echo "📦 Prepare for app store submission (if needed)"
    echo "🔄 Run 'npm run build' to rebuild after code changes"
}

# Run the main function
main
