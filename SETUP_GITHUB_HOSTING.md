# 🚀 GitHub Hosting Setup Guide for Dynamic Toolbox

This guide will help you set up GitHub hosting for your Dynamic Toolbox app with automatic releases and a beautiful landing page.

## 📋 Prerequisites

- [ ] GitHub account
- [ ] Your Dynamic Toolbox project in a local git repository
- [ ] macOS with Xcode installed

## 🏗️ Step 1: Push Your Repository to GitHub

1. **Create a new repository on GitHub:**
   - Go to https://github.com/new
   - Repository name: `dynamic-toolbox` (or your preferred name)
   - Description: "🧰 Dynamic Toolbox - Your all-in-one productivity hub for macOS"
   - Make it **Public** (so GitHub Pages works for free)
   - Don't initialize with README (you already have one)

2. **Connect your local repository to GitHub:**
   ```bash
   # Add GitHub as remote origin (replace YOUR_USERNAME and YOUR_REPO)
   git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
   
   # Push your code
   git add .
   git commit -m "Initial commit - Dynamic Toolbox v2.0.0"
   git push -u origin main
   ```

## 🌐 Step 2: Enable GitHub Pages

1. **Go to your repository settings:**
   - Navigate to: `https://github.com/YOUR_USERNAME/YOUR_REPO/settings`

2. **Enable GitHub Pages:**
   - Scroll down to "Pages" in the left sidebar
   - Source: "Deploy from a branch"
   - Branch: `main` 
   - Folder: `/docs`
   - Click "Save"

3. **Update the website links:**
   - Edit `docs/index.html`
   - Replace `YOUR_USERNAME/YOUR_REPO` with your actual GitHub username and repository name
   - Example: `steve-doe/dynamic-toolbox`

## 🏷️ Step 3: Create Your First Release

1. **Build the app locally:**
   ```bash
   # Run the build script
   ./build-release.sh
   ```

2. **Create a git tag and push:**
   ```bash
   # Create and push a version tag (this triggers automatic release)
   git tag v2.0.0
   git push origin v2.0.0
   ```

3. **GitHub Actions will automatically:**
   - ✅ Build your app on macOS
   - ✅ Create a DMG file
   - ✅ Create a GitHub Release
   - ✅ Upload the DMG as a download asset

## 📱 Step 4: Verify Everything Works

1. **Check GitHub Pages site:**
   - Visit: `https://YOUR_USERNAME.github.io/YOUR_REPO`
   - Should show your beautiful landing page

2. **Check the release:**
   - Go to: `https://github.com/YOUR_USERNAME/YOUR_REPO/releases`
   - Should see "Dynamic Toolbox v2.0.0" with DMG download

3. **Test the download:**
   - Click the DMG file to download
   - Install and test the app

## 🎯 Step 5: Customize Your Website

1. **Add screenshots:**
   - Take screenshots of your app
   - Add them to `docs/screenshots/` folder
   - Update `docs/index.html` to display them

2. **Update social media previews:**
   - Replace the Open Graph image URL in `docs/index.html`
   - Use: `https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/icon.png`

3. **Customize the content:**
   - Update features, descriptions, and any other content in `docs/index.html`

## 🔄 Step 6: Future Releases

For future releases, just:

1. **Make your changes**
2. **Update version numbers**
3. **Create and push a new tag:**
   ```bash
   git add .
   git commit -m "Version 2.1.0 - New features and improvements"
   git tag v2.1.0
   git push origin main
   git push origin v2.1.0
   ```

GitHub Actions will automatically build and release the new version!

## 📊 Analytics & Monitoring

**Track downloads and usage:**
- GitHub provides release download statistics
- GitHub Pages provides basic traffic analytics
- Consider adding Google Analytics to your website

## 🎨 Advanced Customizations

### Custom Domain (Optional)
1. Buy a domain (e.g., `dynamictoolbox.app`)
2. Add a `CNAME` file to `docs/` folder with your domain
3. Configure DNS settings to point to GitHub Pages

### App Notarization (Optional)
For wider distribution, consider:
1. Getting an Apple Developer account ($99/year)
2. Code signing your app
3. Notarizing with Apple
4. Updating GitHub Actions to include notarization

## 🛠️ Troubleshooting

### GitHub Actions Build Fails
- Check the Actions tab for error details
- Ensure your Xcode project builds locally first
- Verify scheme names match in the workflow

### Website Not Loading
- Check that GitHub Pages is enabled in repository settings
- Verify the `docs/` folder exists and contains `index.html`
- Wait a few minutes for GitHub to deploy changes

### Download Link Not Working
- Ensure you've created at least one release
- Check that the JavaScript in `index.html` can fetch release info
- Verify the repository is public (for API access)

## 🎉 You're All Set!

Your Dynamic Toolbox app is now:
- ✅ **Hosted on GitHub** with automatic releases
- ✅ **Available for public download** via beautiful website
- ✅ **Automatically built** whenever you push a new version tag
- ✅ **Professional presentation** with landing page and documentation

**Your website:** `https://YOUR_USERNAME.github.io/YOUR_REPO`  
**Download page:** `https://github.com/YOUR_USERNAME/YOUR_REPO/releases`

Share the website link with users - they can easily download and install your app!

---

Need help? Open an issue in your repository or check the GitHub Pages and Actions documentation. 