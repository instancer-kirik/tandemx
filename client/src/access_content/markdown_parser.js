/**
 * Markdown parser for blog posts
 * Uses marked.js for Markdown conversion
 */

// Initialize the markdown parser with global scope
window.markdownParser = {
  // Async function to fetch and parse a markdown file
  fetchMarkdownPost: function(postPath) {
    return new Promise((resolve, reject) => {
      fetch(postPath)
        .then(response => {
          if (!response.ok) {
            throw new Error(`Failed to fetch post: ${response.status} ${response.statusText}`);
          }
          return response.text();
        })
        .then(markdown => {
          resolve(this.parseMarkdown(markdown));
        })
        .catch(error => {
          console.error('Error fetching markdown post:', error);
          reject(error);
        });
    });
  },

  // Parse markdown content and extract frontmatter and content
  parseMarkdown: function(markdown) {
    // Extract frontmatter (metadata at the top of the markdown file)
    const frontmatterRegex = /^---\s*\n([\s\S]*?)\n---\s*\n/;
    const frontmatterMatch = markdown.match(frontmatterRegex);

    let frontmatter = {};
    let content = markdown;

    if (frontmatterMatch) {
      // Remove frontmatter from content
      content = markdown.slice(frontmatterMatch[0].length);
      
      // Parse frontmatter into key-value pairs
      const frontmatterLines = frontmatterMatch[1].split('\n');
      frontmatterLines.forEach(line => {
        if (!line.trim()) return;
        
        // Find the first colon to split key and value
        const colonIndex = line.indexOf(':');
        if (colonIndex === -1) return;
        
        const key = line.slice(0, colonIndex).trim();
        const value = line.slice(colonIndex + 1).trim();
        
        frontmatter[key] = value;
      });
    }

    return {
      frontmatter,
      content: this.markdownToHtml(content)
    };
  },

  // Convert markdown content to HTML
  markdownToHtml: function(markdown) {
    try {
      return marked.parse(markdown, {
        gfm: true, // GitHub Flavored Markdown
        breaks: true, // Convert line breaks to <br>
        sanitize: true, // Sanitize HTML input
        smartLists: true,
        smartypants: true
      });
    } catch (error) {
      console.error('Error parsing markdown:', error);
      return this.basicMarkdownToHtml(markdown);
    }
  },

  // Basic fallback markdown parser for headings, paragraphs, and links
  basicMarkdownToHtml: function(markdown) {
    return markdown
      // Convert headers
      .replace(/^# (.*$)/gm, '<h1>$1</h1>')
      .replace(/^## (.*$)/gm, '<h2>$1</h2>')
      .replace(/^### (.*$)/gm, '<h3>$1</h3>')
      .replace(/^#### (.*$)/gm, '<h4>$1</h4>')
      
      // Convert bold and italic
      .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
      .replace(/\*(.*?)\*/g, '<em>$1</em>')
      
      // Convert links
      .replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2">$1</a>')
      
      // Convert images
      .replace(/!\[([^\]]*)\]\(([^)]+)\)/g, '<img src="$2" alt="$1">')
      
      // Convert code blocks
      .replace(/```([\s\S]*?)```/g, '<pre><code>$1</code></pre>')
      
      // Convert inline code
      .replace(/`([^`]+)`/g, '<code>$1</code>')
      
      // Convert paragraphs (any line not starting with <)
      .replace(/^(?!<)(.+)$/gm, '<p>$1</p>');
  },

  // Convert a blog post object to markdown
  postToMarkdown: function(post) {
    if (!post) return '';
    
    const frontmatter = [
      '---',
      `title: ${post.title || ''}`,
      `date: ${post.date || new Date().toISOString().split('T')[0]}`,
      `author: ${post.author || 'instance.select'}`,
      `category: ${post.category || 'uncategorized'}`,
      post.excerpt ? `excerpt: ${post.excerpt}` : '',
      post.image ? `image: ${post.image}` : '',
      '---',
      '',
      post.content || ''
    ].filter(line => line !== '').join('\n');
    
    return frontmatter;
  }
}; 