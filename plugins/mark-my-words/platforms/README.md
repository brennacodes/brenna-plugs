# Platform Templates

Each file in this directory defines the content format for a specific blogging platform. Skills load the appropriate template based on the `blog.platform` config value.

## Template Structure

Every template follows the same structure:

1. **Platform Info** - content directory, file naming, frontmatter format, draft behavior
2. **Frontmatter** - required fields, optional fields, full example
3. **Content Features** - callouts, code blocks, links, images, video, Mermaid, LaTeX
4. **Content Structure Best Practices** - platform-specific writing guidance

## Supported Platforms

| File | Platform |
|------|----------|
| `quartz.md` | Quartz v4 |
| `hugo.md` | Hugo |
| `jekyll.md` | Jekyll |
| `astro.md` | Astro |
| `eleventy.md` | Eleventy (11ty) |
| `docusaurus.md` | Docusaurus |
| `zola.md` | Zola |

## Adding a New Platform

To add support for a new platform:

1. Copy any existing template as a starting point
2. Replace all platform-specific details (frontmatter fields, syntax, features)
3. Document what the platform supports natively - no degradation or fallbacks
4. Add the platform name to the setup skill's platform selection list
