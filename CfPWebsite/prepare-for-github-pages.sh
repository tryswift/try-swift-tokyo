#!/bin/bash

# Script to prepare CfP website for deployment to GitHub Pages under /cfp path
# This adds /cfp prefix to all internal absolute paths

set -e

echo "Preparing CfP website for GitHub Pages deployment under /cfp..."

# Navigate to CfPWebsite directory
cd "$(dirname "$0")"

# Build the site
echo "Building site..."
swift run

# Process all HTML files in Build directory
echo "Processing HTML files..."
find Build -name "*.html" -type f | while read file; do
    # Create temporary file
    tmp_file="${file}.tmp"

    # Update CSS/JS asset paths
    sed -e 's|href="/css/|href="/cfp/css/|g' \
        -e 's|href="/js/|href="/cfp/js/|g' \
        -e 's|src="/js/|src="/cfp/js/|g' \
        -e 's|href="/fonts/|href="/cfp/fonts/|g' \
        "$file" > "$tmp_file"

    # Update internal page links (but not the ones that already have /cfp)
    sed -e 's|href="/cf-p-home"|href="/cfp/cf-p-home"|g' \
        -e 's|href="/guidelines-page"|href="/cfp/guidelines-page"|g' \
        -e 's|href="/submit-page"|href="/cfp/submit-page"|g' \
        -e 's|href="/login-page"|href="/cfp/login-page"|g' \
        -e 's|href="/my-proposals-page"|href="/cfp/my-proposals-page"|g' \
        "$tmp_file" > "${tmp_file}.2"

    # Update canonical URLs
    sed -e 's|<link href="https://tryswift.jp/" rel="canonical"|<link href="https://tryswift.jp/cfp/" rel="canonical"|g' \
        -e 's|<meta property="og:url" content="https://tryswift.jp/"|<meta property="og:url" content="https://tryswift.jp/cfp/"|g' \
        "${tmp_file}.2" > "$file"

    # Clean up temp files
    rm "$tmp_file" "${tmp_file}.2"
done

# Process sitemap.xml if it exists
if [ -f "Build/sitemap.xml" ]; then
    echo "Processing sitemap.xml..."
    sed -e 's|<loc>https://tryswift.jp/|<loc>https://tryswift.jp/cfp/|g' \
        "Build/sitemap.xml" > "Build/sitemap.xml.tmp"
    mv "Build/sitemap.xml.tmp" "Build/sitemap.xml"
fi

# Process feed.rss if it exists
if [ -f "Build/feed.rss" ]; then
    echo "Processing feed.rss..."
    sed -e 's|<link>https://tryswift.jp/|<link>https://tryswift.jp/cfp/|g' \
        -e 's|<guid>https://tryswift.jp/|<guid>https://tryswift.jp/cfp/|g' \
        "Build/feed.rss" > "Build/feed.rss.tmp"
    mv "Build/feed.rss.tmp" "Build/feed.rss"
fi

echo "Done! The Build directory is ready for deployment to /cfp path."
echo ""
echo "To deploy to GitHub Pages:"
echo "1. Copy the Build directory contents to the main Website Build directory under /cfp"
echo "2. Or use this command:"
echo "   mkdir -p ../Website/Build/cfp && cp -r Build/* ../Website/Build/cfp/"
