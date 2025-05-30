import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

pub type ProjectInfo {
  ProjectInfo(
    name: String,
    emoji: String,
    description: String,
    status: String,
    path: String,
    features: List(String),
    tech_stack: List(String),
    domain: String,
    source_url: Option(String),
    screenshots: List(String),
  )
}

// Helper function to generate GitHub URLs
fn github_url(project_name: String) -> String {
  "https://github.com/instancer-kirik/" <> string.lowercase(project_name)
}

pub fn get_domains() -> List(#(String, String)) {
  [
    #("Development Tools & Environments", ""),
    #(
      "Creative Tools",
      "Tools for creative workflows, multimedia, and content creation",
    ),
    #("Project Management", "Tools for managing projects, time, and resources"),
    #("Data & Search", "Tools for data management, search, and organization"),
    #("System Tools", "System utilities and infrastructure tools"),
    #("Language Tools", "Programming language tools and environments"),
    #("Gaming & Entertainment", "Games and entertainment software"),
    #("Business & Contracts", "Business operations and contract management"),
  ]
}

pub fn get_projects() -> List(ProjectInfo) {
  [
    // Development Tools & Environments
    ProjectInfo(
      name: "Sledge",
      emoji: "🌐",
      description: "A modern web browser built with a hammer",
      status: "Active",
      path: "/sledge",
      features: [
        "made by developer, for developer",
        "Privacy-focused architecture with sandboxing",
        "QWebEngine - (Qt WebEngine) - Chromium",
        "Supports V3 extensions and Manifest V2 new handling",
        "Group-based, memory-state fantastic tab management",
        "Anti-fffffflashbang, force dark mode",
        "Desktop first; possible mobile, since qt supports it",
      ],
      tech_stack: ["pyqt6"],
      domain: "Development Tools & Environments",
      source_url: Some(github_url("sledge")),
      screenshots: [],
    ),
    ProjectInfo(
      name: "D.d",
      emoji: "🖥️",
      description: "A 3D tiling window manager and desktop environment for developers",
      status: "Shelved",
      path: "/ddew",
      features: [
        "Hardware integration basis for Hunter Exam software",
        "Custom tiling window manager", "Gesture and keyboard-driven controls",
        "3D box layout for application organization",
        "Immersive desktop environment", "Spatial organization of workspaces",
      ],
      tech_stack: ["D", "dlangui with modular backends"],
      domain: "Development Tools & Environments",
      source_url: Some(github_url("ddew")),
      screenshots: [],
    ),
    ProjectInfo(
      name: "Shiny",
      emoji: "✨",
      description: "Modern development environment with tooling and extensible architecture",
      status: "Active",
      path: "/shiny",
      features: ["Labyrinth navigation", "Notes and Strategies", ""],
      tech_stack: ["Gleam", "JavaScript", "Erlang"],
      domain: "Development Tools & Environments",
      source_url: Some(github_url("shiny")),
      screenshots: [],
    ),
    ProjectInfo(
      name: "Typer",
      emoji: "🖩",
      description: "Typing game -  blog, with custom phrases and code snippets",
      status: "Active",
      path: "/typer",
      features: ["Typing game", "Typing test", "Typing practice"],
      tech_stack: ["Gleam", "JavaScript", "Erlang"],
      domain: "Development Tools & Environments",
      source_url: Some(github_url("typer")),
      screenshots: [],
    ),
    ProjectInfo(
      name: "BigLinks",
      emoji: "🔗",
      description: "Symbolic links manager",
      status: "Active",
      path: "/biglinks",
      features: [
        "Visual symlink management", "Path visualization", "Link validation",
      ],
      tech_stack: ["pyqt"],
      domain: "Development Tools & Environments",
      source_url: Some(github_url("biglinks")),
      screenshots: [],
    ),
    ProjectInfo(
      name: "Compyutinator Code",
      emoji: "💻",
      description: "CompSci and AI workspace and project/spaceship dashboards",
      status: "Active",
      path: "/compyutinator",
      features: [
        "AI workspace integration", "Project dashboards", "Spaceship interface",
        "Custom diff/merge tools", "Computer Science platform IDE",
      ],
      tech_stack: ["pyqt"],
      domain: "Development Tools & Environments",
      source_url: Some(github_url("compyutinator")),
      screenshots: [],
    ),
    ProjectInfo(
      name: "Compyutinator Keyboard",
      emoji: "⌨️",
      description: "Software toolkit for keyboard customization and programming",
      status: "Active",
      path: "/compyutinator-keyboard",
      features: [
        "Custom keyboard layouts", "Macro programming interface",
        "Hardware integration", "Key mapping visualization",
        "Profile management system",
      ],
      tech_stack: ["PyQt", "Python"],
      domain: "Development Tools & Environments",
      source_url: Some(github_url("compyutinator-keyboard")),
      screenshots: [],
    ),
    ProjectInfo(
      name: "Explorinator",
      emoji: "🔍",
      description: "Sort by last modified (slow)",
      status: "Stable",
      path: "/explorinator",
      features: [
        "VSCode extension", "Sort by modified time", "Performance improvements",
      ],
      tech_stack: ["C#"],
      domain: "Development Tools & Environments",
      source_url: Some(github_url("explorinator")),
      screenshots: [],
    ),
    ProjectInfo(
      name: "SAPDAS",
      emoji: "🔍",
      description: "Sketchfab auto preferred format downloader and attribution saver script",
      status: "Beta",
      path: "/sapdas",
      features: [],
      tech_stack: ["JavaScript", "Violentmonkey"],
      domain: "Development Tools & Environments",
      source_url: Some(github_url("sapdas")),
      screenshots: [],
    ),
    ProjectInfo(
      name: "Eepy Explorer",
      emoji: "🌙",
      description: "File explorer with sleep mode and power management",
      status: "Releasable",
      path: "/eepy-explorer",
      features: [
        "ease of use, e lang tool gui, background tasks, power-efficient indexing",
        "file/archive previews", "file/archive operations",
        "Sleep mode for background operations",
      ],
      tech_stack: ["PyQt"],
      domain: "System Tools",
      source_url: Some(github_url("eepy-explorer")),
      screenshots: [],
    ),
    ProjectInfo(
      name: "DeepScape",
      emoji: "🌌",
      description: "vast chartspace with specialized file/operations nodes and drawing",
      status: "Shelved",
      path: "/deepscape",
      features: [
        "Pannable chartspace with editor nodes", "Visual data flows",
        "Drawing tools", "Node-based operations",
      ],
      tech_stack: ["Elixir first, pending remake"],
      domain: "Development Tools & Environments",
      source_url: Some(github_url("deepscape")),
      screenshots: [],
    ),
    // Gaming & Entertainment
    ProjectInfo(
      name: "Space Captain Operations Software",
      emoji: "🚀",
      description: "Platform (game) and various tools for managing spacecrafts, cargo, crew and asteroid mining",
      status: "Prototype",
      path: "/spaceos",
      features: [
        "3D Bridge Command for various functions",
        "Command & control system inspired by starship captain interfaces, providing strategic oversight and decision support during the Hunter exam.",
        "Advanced crew management", "Real-time space combat",
        "Complex trading mechanics", "Procedural mission system",
        "Cross-platform multiplayer",
      ],
      tech_stack: [
        "D", "Custom game framework", "zig?", "E", "gleam", "Custom networking",
        "Physics simulation", "AI systems",
      ],
      domain: "Gaming & Entertainment",
      source_url: Some(github_url("spaceos")),
      screenshots: [],
    ),
    ProjectInfo(
      name: "Pause || Effect",
      emoji: "🎮",
      description: "Dynamic multiplayer quests, maps, stats",
      status: "Shelved",
      path: "/pause-effect",
      features: ["Dynamic quests", "Multiplayer maps", "Stats tracking"],
      tech_stack: ["Elixir"],
      domain: "Gaming & Entertainment",
      source_url: Some(github_url("pause-effect")),
      screenshots: [],
    ),
    ProjectInfo(
      name: "Dream Journal",
      emoji: "🎮",
      description: "Dream journal with transcription and AI analysis",
      status: "Shelved",
      path: "/dream-journal",
      features: ["Dream journal", "AI analysis", "Dream interpretation"],
      tech_stack: ["Kotlin"],
      domain: "Language Tools",
      source_url: Some(github_url("dream-journal")),
      screenshots: [],
    ),
    ProjectInfo(
      name: "Portfolia",
      emoji: "🎲",
      description: "Web-based game portfolio with interactive showcases",
      status: "Active",
      path: "/portfolia",
      features: [
        "Interactive game demos", "Portfolio showcase", "Game development blog",
        "Asset browser", "Performance metrics visualization",
      ],
      tech_stack: ["TypeScript", "React", "WebGL", "Game engines"],
      domain: "Gaming & Entertainment",
      source_url: Some(github_url("portfolia")),
      screenshots: [],
    ),
    // Creative Tools
    ProjectInfo(
      name: "Bonify",
      emoji: "🚂",
      description: "rigging a train or arrangement along curves",
      status: "Prototype",
      path: "/bonify",
      features: ["Bones", "Tape", "Quaternions", "Rigging along curves"],
      tech_stack: ["Blender Python"],
      domain: "Creative Tools",
      source_url: Some(github_url("bonify")),
      screenshots: [],
    ),
    ProjectInfo(
      name: "Nomine",
      emoji: "🧰",
      description: "Blender Python utilities",
      status: "Prototype",
      path: "/nomine",
      features: [
        "Utility functions for Blender", "Python plugins", "3D modeling tools",
        "Asset management",
      ],
      tech_stack: ["Blender Python"],
      domain: "Creative Tools",
      source_url: Some(github_url("nomine")),
      screenshots: [],
    ),
    ProjectInfo(
      name: "Candy Generator",
      emoji: "🍬",
      description: "Procedural candy and confection generator for Blender",
      status: "Prototype",
      path: "/candy-generator",
      features: [
        "Procedural candy generation", "Custom materials and textures",
        "Batch processing capability", "Exportable assets",
        "Animation-ready models",
      ],
      tech_stack: ["Blender Python"],
      domain: "Creative Tools",
      source_url: Some(github_url("candy-generator")),
      screenshots: [],
    ),
    ProjectInfo(
      name: "Lifegem Medallion Generator",
      emoji: "🏅",
      description: "Custom medallion and gem generator for Blender",
      status: "Prototype",
      path: "/lifegem",
      features: [
        "Procedural medallion generation", "Custom gem cutting and faceting",
        "Physically based materials", "Engraving and detail system",
        "Export for 3D printing",
      ],
      tech_stack: ["Blender Python"],
      domain: "Creative Tools",
      source_url: Some(github_url("lifegem")),
      screenshots: [],
    ),
    ProjectInfo(
      name: "Mediata",
      emoji: "🎨",
      description: "Manages multimedia and posting with creative organizational workflows",
      status: "Shelved",
      path: "/mediata",
      features: [
        "Multimedia management", "Creative workflows", "Posting automation",
      ],
      tech_stack: ["Elixir"],
      domain: "Creative Tools",
      source_url: Some(github_url("mediata")),
      screenshots: [],
    ),
    // C Tools
    ProjectInfo(
      name: "Cround",
      emoji: "💍",
      description: "Bracelet Maker",
      status: "Releasable",
      path: "/cround",
      features: [
        "Custom bracelet design tools", "Pattern generation",
        "Size customization", "Material optimization",
      ],
      tech_stack: ["C"],
      domain: "Creative Tools",
      source_url: Some(github_url("cround")),
      screenshots: [],
    ),
    // System Tools
    ProjectInfo(
      name: "varchiver",
      emoji: "📦",
      description: "Archives with skip patterns and gitconfig and aur releases",
      status: "New",
      path: "/varchiver",
      features: ["Skip patterns", "Git integration", "AUR releases"],
      tech_stack: ["pyqt"],
      domain: "System Tools",
      source_url: Some(github_url("varchiver")),
      screenshots: [],
    ),
    ProjectInfo(
      name: "clipdirstructor",
      emoji: "🌳",
      description: "Visual tree layouts converted into directories",
      status: "Releasable",
      path: "/clipdirstructor",
      features: ["Visual tree layouts", "Directory generation"],
      tech_stack: ["C"],
      domain: "System Tools",
      source_url: Some(github_url("clipdirstructor")),
      screenshots: [],
    ),
    ProjectInfo(
      name: "clipdirstructer",
      emoji: "📂",
      description: "CLI structures from visual hierarchies",
      status: "Releasable",
      path: "/clipdirstructer",
      features: [
        "Command-line interface", "Visual hierarchy parsing",
        "Automatic structure generation", "Batch processing",
      ],
      tech_stack: ["CLI", "Bash"],
      domain: "System Tools",
      source_url: Some(github_url("clipdirstructer")),
      screenshots: [],
    ),
    ProjectInfo(
      name: "Glitters",
      emoji: "📅",
      description: "My 3rd custom calendar",
      status: "Prototype",
      path: "/glitters",
      features: [
        "Multi-timezone meeting scheduling", "Working hours management",
        "Email notifications", "Custom week lengths", "Meeting coordination",
        "Moon phases and astrology",
      ],
      tech_stack: ["Gleam", "JavaScript"],
      domain: "Project Management",
      source_url: Some(github_url("glitters")),
      screenshots: [],
    ),
    // Language Tools
    ProjectInfo(
      name: "enzige",
      emoji: "⚡",
      description: "e lang tool",
      status: "Prototype",
      path: "/enzige",
      features: ["E language support", "Development tools"],
      tech_stack: ["zig"],
      domain: "Language Tools",
      source_url: Some(github_url("enzige")),
      screenshots: [],
    ),
    ProjectInfo(
      name: "translinator",
      emoji: "🌍",
      description: "Translation tool with rag context",
      status: "Prototype",
      path: "/translinator",
      features: [
        "RAG context", "Translation support", "Context-aware translations",
        "Multiple language support", "API integration",
      ],
      tech_stack: ["Python", "C"],
      domain: "Language Tools",
      source_url: Some(github_url("translinator")),
      screenshots: [],
    ),
    // Fonce was missing
    ProjectInfo(
      name: "Fonce",
      emoji: "🛡️",
      description: "D agent and Elixir multisecurity defense system",
      status: "Prototype",
      path: "/fonce",
      features: [
        "D language agent system", "Multi-layered security", "Defense in depth",
        "Threat detection", "Elixir-based processing",
      ],
      tech_stack: ["D", "Elixir"],
      domain: "System Tools",
      source_url: Some(github_url("fonce")),
      screenshots: [],
    ),
    // Veix was missing
    ProjectInfo(
      name: "Veix",
      emoji: "🧩",
      description: "The Elixir container and DAO LLC framework",
      status: "Prototype",
      path: "/veix",
      features: [
        "Containerized Elixir applications", "DAO organization tools",
        "LLC frameworks", "Decentralized governance",
        "Smart contract integration",
      ],
      tech_stack: ["Elixir", "Blockchain"],
      domain: "Business & Contracts",
      source_url: Some(github_url("veix")),
      screenshots: [],
    ),
    // Zig tools were missing
    ProjectInfo(
      name: "Combocounter",
      emoji: "🔢",
      description: "Tracks variables and combination patterns",
      status: "Prototype",
      path: "/combocounter",
      features: [
        "Pattern tracking", "Variable monitoring", "Combination analysis",
        "Optimization tools",
      ],
      tech_stack: ["Zig"],
      domain: "Development Tools & Environments",
      source_url: Some(github_url("combocounter")),
      screenshots: [],
    ),
    ProjectInfo(
      name: "Video Editor",
      emoji: "🎬",
      description: "Zig to WASM video editing tool",
      status: "Prototype",
      path: "/video-editor",
      features: [
        "WebAssembly compilation", "Video processing", "Editing toolkit",
        "Browser-based interface",
      ],
      tech_stack: ["Zig", "WebAssembly"],
      domain: "Creative Tools",
      source_url: Some(github_url("video-editor")),
      screenshots: [],
    ),
    ProjectInfo(
      name: "Trout/Grouper",
      emoji: "🐟",
      description: "Group management tool",
      status: "Prototype",
      path: "/grouper",
      features: [
        "Group organization", "Member management", "Permission systems",
        "Activity tracking",
      ],
      tech_stack: ["Zig"],
      domain: "Project Management",
      source_url: Some(github_url("grouper")),
      screenshots: [],
    ),
    // Data & Search
    ProjectInfo(
      name: "Resolvinator",
      emoji: "🗄️",
      description: "Data backend and for data management",
      status: "Shelved",
      path: "/resolvinator",
      features: ["Data management", "Backend services"],
      tech_stack: ["Elixir"],
      domain: "Data & Search",
      source_url: Some(github_url("resolvinator")),
      screenshots: [],
    ),
    ProjectInfo(
      name: "seek",
      emoji: "🔎",
      description: "searching and indexing links and resources",
      status: "Active",
      path: "/seek",
      features: ["Resource indexing", "Link management"],
      tech_stack: ["Elixir"],
      domain: "Data & Search",
      source_url: Some(github_url("seek")),
      screenshots: [],
    ),
    // Project Management
    ProjectInfo(
      name: "TimeTracker",
      emoji: "⏱️",
      description: "Custom calenders and events, blocks, duration tracking and review",
      status: "Shelved",
      path: "/timetracker",
      features: ["Custom calendars", "Event tracking", "Duration tracking"],
      tech_stack: ["Elixir"],
      domain: "Project Management",
      source_url: Some(github_url("timetracker")),
      screenshots: [],
    ),
    ProjectInfo(
      name: "Mancala 2",
      emoji: "🎮",
      description: "Mancala game",
      status: "Shelved",
      path: "/mancala2",
      features: ["Cheating + Callouts", "AI opponent", "Multiplayer"],
      tech_stack: ["Elixir"],
      domain: "Gaming & Entertainment",
      source_url: Some(github_url("mancala2")),
      screenshots: [],
    ),
    ProjectInfo(
      name: "Cooking Simulator",
      emoji: "��",
      description: "Cooking game",
      status: "Prohibited",
      path: "/cooking-simulator",
      features: ["Cooking", "Multiplayer"],
      tech_stack: ["Elixir"],
      domain: "Gaming & Entertainment",
      source_url: Some(github_url("cooking-simulator")),
      screenshots: [],
    ),
    ProjectInfo(
      name: "Walking the dog",
      emoji: "��",
      description: "Walking the dog",
      status: "Prohibited",
      path: "/walking-the-dog",
      features: ["Walking the dog", "Multiplayer"],
      tech_stack: ["Elixir"],
      domain: "Gaming & Entertainment",
      source_url: Some(github_url("walking-the-dog")),
      screenshots: [],
    ),
    // Business & Contracts
    ProjectInfo(
      name: "DivvyQueue",
      emoji: "📊",
      description: "Corporeal-Incorporation agreement managment",
      status: "Shelved",
      path: "/divvyqueue",
      features: [
        "multiparty agreements with documents, and support",
        "timeline tracking, contact options, breach handling",
        "Smart contracts?", "Cross-discipline project tools",
      ],
      tech_stack: ["Gleam", "maybe E, zig"],
      domain: "Business & Contracts",
      source_url: Some(github_url("divvyqueue")),
      screenshots: [],
    ),
    ProjectInfo(
      name: "findry",
      emoji: "🎨",
      description: "Art/Resource Discovery",
      status: "Active",
      path: "/findry",
      features: [
        "Artist/Offerer Discovery", "Space/Equipment offerings and marketplace",
        "Interactive virtual space tour?", "Chat and availability system",
        "PostGIS-powered location search", "Integrated payment processing",
        "Smart access control", "Event Scheduling and organizing",
        "Brand-managed events",
      ],
      tech_stack: [
        "Gleam/Elixir on BEAM VM", "PostgreSQL with PostGIS",
        "WebSocket real-time", "ElecticSQL or Supabase or Squirrel idk",
      ],
      domain: "Creative Tools",
      source_url: Some(github_url("findry")),
      screenshots: [],
    ),
    ProjectInfo(
      name: "tandemx",
      emoji: "🤝",
      description: "partner situation browsership, shared inventory",
      status: "Active",
      path: "/tandemx",
      features: ["Partner management", "Shared inventory", "Resource tracking"],
      tech_stack: ["Gleam", "Elixir"],
      domain: "Business & Contracts",
      source_url: Some(github_url("tandemx")),
      screenshots: [],
    ),
    // MT Clipboards from projects_page.html
    ProjectInfo(
      name: "MT Clipboards",
      emoji: "📋",
      description: "Professional clipboard solutions for businesses and individuals",
      status: "Active",
      path: "/mt-clipboards",
      features: [
        "Premium quality materials", "Custom branding options",
        "Bulk ordering available", "Corporate gift solutions",
        "Eco-friendly options",
      ],
      tech_stack: ["E-commerce", "Physical products"],
      domain: "Business & Contracts",
      source_url: None,
      screenshots: [],
    ),
  ]
}

pub fn get_projects_by_domain(domain: String) -> List(ProjectInfo) {
  get_projects()
  |> list.filter(fn(p) { p.domain == domain })
}
