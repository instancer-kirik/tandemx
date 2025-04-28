# Markdown Blog System

This is a simple markdown-based blog system for instance.select. It allows you to write blog posts in Markdown format and have them displayed on the website.

## Directory Structure

```
/blog
  /posts        # Markdown blog post files
  /images       # Images for blog posts
  index.json    # List of all blog posts (must be updated manually)
  markdown_parser.js  # JS for parsing markdown files
  blog_renderer.js    # JS for rendering blog posts in the UI
```

## How to Create a New Blog Post

### Option 1: Using the Blog Editor UI

1. Navigate to the blog page: `/blog`
2. Click the "Create New Post" button
3. Fill out the form with your post details:
   - Title
   - Post ID (used in the URL)
   - Date
   - Category
   - Excerpt (summary shown in listings)
   - Content (in Markdown format)
   - Featured Image URL (optional)
4. Click "Generate Markdown" to create the markdown content
5. Copy the generated markdown
6. Create a new file in the `/blog/posts/` directory with the filename `[post-id].md`
7. Paste the markdown content into the file and save

### Option 2: Creating a Post Manually

1. Create a new `.md` file in the `/blog/posts/` directory
2. Name the file using the post's URL slug (e.g., `my-new-post.md`)
3. Add frontmatter at the top of the file:

```markdown
---
title: Your Post Title
date: YYYY-MM-DD
author: Your Name
category: category-name
excerpt: A brief summary of your post
image: /blog/images/optional-image.jpg
---

# Your Post Title

The content of your post goes here...
```

4. Write your blog post content in Markdown format
5. Save the file

### Updating the Blog Index

After creating a new post, you need to add it to the blog index:

1. Open `blog/index.json`
2. Add a new entry to the `posts` array:

```json
{
  "posts": [
    // ... existing posts
    {
      "id": "your-post-id",
      "title": "Your Post Title",
      "date": "YYYY-MM-DD",
      "author": "Your Name",
      "category": "category-name",
      "excerpt": "A brief summary of your post"
    }
  ]
}
```

## Adding Images

1. Add your images to the `/blog/images/` directory
2. Reference them in your markdown using:

```markdown
![Alt text](/blog/images/your-image.jpg)
```

## Markdown Reference

### Basic Syntax

```markdown
# Heading 1
## Heading 2
### Heading 3

**Bold text**
*Italic text*

[Link text](https://example.com)

![Alt text](/path/to/image.jpg)

- Bullet point 1
- Bullet point 2

1. Numbered item 1
2. Numbered item 2

> Blockquote
```

### Code Blocks

```markdown
Inline `code` using backticks

```javascript
// Code block with language specification
function example() {
  return "Hello world";
}
```
```

## Categories

The default categories are:
- technology
- projects
- updates
- tutorials

To add a new category:
1. Add it to the category dropdown in `blog.html`
2. Use it in your post frontmatter

## Troubleshooting

### Post Not Showing Up
- Check that the post is correctly added to `index.json`
- Verify that the post ID in the index matches the filename
- Ensure the frontmatter is correctly formatted

### Images Not Displaying
- Check that the image path is correct
- Verify that the image file exists in the specified location
- Make sure the image format is supported (jpg, png, gif, webp) 