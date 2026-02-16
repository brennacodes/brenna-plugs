# brenna-plugs

![installs](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2Fbrennacodes%2Fbrenna-plugs%2Fmain%2F.github%2Fdata%2Fclones.json&query=%24.total&label=installs&color=brightgreen)

Claude Code plugins by [brennacodes](https://github.com/brennacodes).

## Plugins

| Plugin | What it does |
|--------|-------------|
| [**i-did-a-thing**](#i-did-a-thing) | Log professionally-relevant experiences, build a searchable evidence arsenal, generate tailored resumes |
| [**what-did-you-do**](#what-did-you-do) | Practice interviews with persona-driven coaching, powered by your logged evidence |
| [**what-do-you-know**](#what-do-you-know) | Deepen understanding through concept quizzing, gap analysis, and learning plans |
| [**mark-my-words**](#mark-my-words) | Write and publish Quartz blog posts — standalone or from your evidence logs |
| [**screenshotr**](#screenshotr) | Precise macOS screenshots with crop, resize, and format control |

## The Quartet

All four career plugins share a single config and data layer — including a shared arsenal, personas, and company profiles. Log an experience once, and it flows into interview prep, knowledge reinforcement, resume building, and blog posts without re-telling the story.

```
Log it                     Practice it                 Learn from it              Write about it
/i-did-a-thing:thing-i-did → /what-did-you-do:practice → /what-do-you-know:explore → /mark-my-words:from-things
         ↓                          ↓                          ↓                          ↓
   evidence arsenal          coached feedback            concept maps              published post
   resume bullets            readiness scores            gap analysis              first-person story
   interview talking points  gap identification          learning plans            blog with metrics
```

All four read from `<things_path>/config.yml` (git-tracked) with a machine-local bootstrap at `~/.claude/things.local.md`. Set up once with `/i-did-a-thing:setup`, then configure each plugin's section with its own setup skill.

## Installation

```bash
# Add the marketplace
/plugin marketplace add brennacodes/brenna-plugs

# Install what you need
/plugin install i-did-a-thing@brenna-plugs
/plugin install what-did-you-do@brenna-plugs
/plugin install mark-my-words@brenna-plugs
/plugin install what-do-you-know@brenna-plugs
/plugin install screenshotr@brenna-plugs
```

---

### i-did-a-thing

Log professionally-relevant experiences — accomplishments, lessons, expertise, decisions, influence, and insights — through guided deep-dives. Every entry auto-generates resume bullets, interview talking points, and a blog seed. A PostToolUse hook rebuilds the JSON index and skill arsenal after every log.

| Skill | Description |
|-------|-------------|
| `/i-did-a-thing:setup` | Configure .things directory, git remote, professional profile |
| `/i-did-a-thing:thing-i-did` | Log an experience (context-aware — extracts from conversation or runs full interview) |
| `/i-did-a-thing:construct-resume` | Match your evidence against a job listing and build a tailored resume |
| `/i-did-a-thing:migrate-things` | Migrate from v2.x per-plugin configs to centralized shared config |

Six evidence types: accomplishment, lesson, expertise, decision, influence, insight. Each gets tailored interview questions, resume bullet formats, and body section structures.

---

### what-did-you-do

Interview prep that knows what you've actually done. Cross-references your arsenal when coaching answers — matching question themes to evidence types (lessons for failure questions, decisions for tradeoff questions, expertise for depth questions). Spaced repetition targets weak areas over time.

| Skill | Description |
|-------|-------------|
| `/what-did-you-do:setup` | Set follow-up depth, default stage, trusted question sources |
| `/what-did-you-do:practice` | Drill a single question with persona-driven feedback |
| `/what-did-you-do:mock` | Full interview round simulation (Amazon, Google, Meta, custom) |
| `/what-did-you-do:review` | Readiness assessment with trends, gaps, and anti-pattern tracking |
| `/what-did-you-do:prep-for` | Company-specific prep plan with value mapping and timeline |
| `/what-did-you-do:update-questions` | Add questions from trusted sources or manual entry |

7 interviewer personas. 45 built-in questions. 5 scoring dimensions. Company profiles for Amazon (14 LPs), Google, and Meta.

---

### mark-my-words

Write, edit, and publish blog posts on Quartz static sites. Supports voice profiles (teach it how you write), Mermaid diagrams, images, and video embeds. The `from-things` skill finds high-potential evidence logs via the JSON index and transforms them into first-person stories.

| Skill | Description |
|-------|-------------|
| `/mark-my-words:setup` | Configure blog source, content directory, media, git workflow |
| `/mark-my-words:new-post` | Write a new post via guided interview |
| `/mark-my-words:update-post` | Edit sections, append, rewrite, or update metadata |
| `/mark-my-words:manage-post` | List posts, manage drafts, organize tags |
| `/mark-my-words:from-things` | Turn evidence logs into blog posts |
| `/mark-my-words:create-voice` | Build a voice profile from writing samples |
| `/mark-my-words:update-voice` | Refine a voice profile |
| `/mark-my-words:add-media` | Add images, diagrams, video embeds to a post |

---

### what-do-you-know

Knowledge reinforcement that draws from your actual experience. Explore topics with probing dialogue grounded in your arsenal, quiz yourself with dynamically generated questions referencing your real projects, identify knowledge gaps by cross-referencing skills against evidence, and build personalized learning plans that bridge from what you know to what you need.

| Skill | Description |
|-------|-------------|
| `/what-do-you-know:setup` | Set learning depth, session length, default persona, focus areas |
| `/what-do-you-know:explore` | Topic-driven deep dive with persona-driven probing and concept mapping |
| `/what-do-you-know:quiz` | Dynamic concept questions from your index.json with spaced repetition |
| `/what-do-you-know:gaps` | Knowledge gap analysis across building and aspirational skills |
| `/what-do-you-know:bridge` | Personalized learning plan from existing knowledge to gap topics |

5 learning dimensions: Depth, Accuracy, Connections, Application, Articulation. Same 7 personas shared with what-did-you-do. Questions generated dynamically — no static question bank.

---

### screenshotr

Precise screenshot capabilities for macOS — capture screens, windows, regions, or URLs with resize, crop, delay, and format control. Built on macOS-native `screencapture` and `sips`.

| Skill | Description |
|-------|-------------|
| `/screenshotr:setup` | Configure output directory, format, naming preferences |
| `/screenshotr:capture` | Full-control screenshot (fullscreen, window, region, URL, display) |
| `/screenshotr:list-windows` | List open windows with app names and IDs |
