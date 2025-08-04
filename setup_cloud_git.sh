#!/bin/bash

# LED Pixel Map Cloud Service - Git Repository Setup
# This script helps you set up a Git repository for deploying to Render.com

echo "🚀 LED Pixel Map Cloud Service - Git Setup"
echo "==========================================="

# Check if we're in the right directory
if [ ! -f "cloud_pixel_service/app.py" ]; then
    echo "❌ Error: Please run this script from the project root directory"
    echo "   Expected to find: cloud_pixel_service/app.py"
    exit 1
fi

echo "✅ Found cloud service files"

# Initialize git if not already done
if [ ! -d ".git" ]; then
    echo "📝 Initializing Git repository..."
    git init
    echo "✅ Git repository initialized"
else
    echo "✅ Git repository already exists"
fi

# Create .gitignore if it doesn't exist
if [ ! -f ".gitignore" ]; then
    echo "📝 Creating .gitignore..."
    cat > .gitignore << EOL
# Flutter/Dart
.dart_tool/
.packages
.pub/
build/
.flutter-plugins
.flutter-plugins-dependencies
.pub-cache/

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
ENV/
env.bak/
venv.bak/
.env

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Logs
*.log
logs/

# Local test files
test_*.dart
EOL
    echo "✅ Created .gitignore"
else
    echo "✅ .gitignore already exists"
fi

# Add all files
echo "📝 Adding files to Git..."
git add .
git add cloud_pixel_service/

# Commit
echo "📝 Creating initial commit..."
git commit -m "Initial commit: LED Pixel Map Cloud Service

- Python Flask service for unlimited pixel map generation
- Removes browser Canvas API limitations
- Supports actual LED panel pixel dimensions
- Ready for Render.com deployment"

echo ""
echo "🎉 Git repository is ready!"
echo ""
echo "Next steps:"
echo "1. Create a GitHub repository"
echo "2. Push this code to GitHub:"
echo "   git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git"
echo "   git branch -M main"
echo "   git push -u origin main"
echo ""
echo "3. Deploy to Render.com:"
echo "   - Go to https://render.com"
echo "   - Click 'New +' → 'Web Service'"
echo "   - Connect your GitHub repository"
echo "   - Select the 'cloud_pixel_service' folder as root"
echo "   - Set build command: pip install -r requirements.txt"
echo "   - Set start command: gunicorn app:app"
echo "   - Deploy!"
echo ""
echo "4. Update Flutter app with your service URL"
echo ""
echo "📚 See cloud_pixel_service/README.md for detailed instructions"
