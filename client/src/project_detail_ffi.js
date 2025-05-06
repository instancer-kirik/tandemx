// FFI implementations for project_detail.gleam

// Placeholder function to simulate fetching a single project by ID
// In a real app, this would fetch from an API (e.g., Supabase)
export function fetchProjectById(id) {
  console.log(`FFI: fetchProjectById called for ID: ${id} (simulating fetch)`);

  // Simulate async fetch
  return new Promise(resolve => {
    setTimeout(() => {
      // Sample data - normally you'd find the project with the matching 'id'
      // For this placeholder, we'll return a detailed mock project if id is 'proj_001'
      // or an error for any other ID.

      if (id === "proj_001") {
        const sample_task1 = {
          id: "task_001_detail",
          title: "Design Integration Architecture (Detailed)",
          description: "Create system architecture for platform integration, focusing on modularity and scalability.",
          status: { type: 'InProgress' },
          project_id: "proj_001",
          assignee: { type: 'Some', 0: "user1@example.com" },
          due_date: { type: 'Some', 0: "2024-07-15" },
          priority: { type: 'High' },
          tags: ["design", "architecture"],
          dependencies: [],
          work_hours: 40.0,
          progress: 65,
        };
        const sample_task2 = {
          id: "task_002_detail",
          title: "Develop API Endpoints (Detailed)",
          description: "Implement RESTful API endpoints for core project features.",
          status: { type: 'Todo' },
          project_id: "proj_001",
          assignee: { type: 'Some', 0: "user2@example.com" },
          due_date: { type: 'Some', 0: "2024-07-30" },
          priority: { type: 'High' },
          tags: ["development", "api"],
          dependencies: ["task_001_detail"],
          work_hours: 60.0,
          progress: 0,
        };

        const sample_chart1 = {
            id: "chart_001_detail",
            title: "Project Timeline (Gantt)",
            description: "Detailed Gantt chart showing all project phases and tasks.",
            project_id: "proj_001",
            chart_type: { type: 'Gantt' }, // Or { type: 'Custom', 0: 'MySpecialChart' }
            data_source: "project_data_source_001.json",
            created_at: "2024-06-01",
            last_updated: "2024-06-15",
            creator: "admin@example.com",
            shared_with: ["user1", "user2"],
        };

        const sample_artifact1 = {
            id: "art_001_detail",
            name: "architecture_diagram_v2.png",
            file_type: "png",
            url: "/artifacts/proj_001/architecture_v2.png",
            created_at: "2024-06-10",
            creator: "user1@example.com",
        };

        const sample_work1 = {
            id: "work_001_detail",
            title: "Architecture Specification Document",
            description: "Comprehensive document detailing the project architecture.",
            project_id: "proj_001",
            work_type: { type: 'Documentation' },
            status: { type: 'InReview' },
            creator: "user1@example.com",
            assignees: ["user2@example.com"],
            dependencies: [],
            artifacts: [sample_artifact1],
        };

        const project_detail_data = {
          id: "proj_001",
          name: "Platform Integration (Detailed View)", 
          description: "This is a detailed description of the Platform Integration project, focusing on its goals, scope, and deliverables. We aim to integrate various internal and external services to streamline operations.", 
          status: { type: 'Active' }, 
          category: { type: 'WebApplication' },
          created_at: "2024-06-01", 
          due_date: { type: 'Some', 0: "2024-12-31" }, 
          owner: "admin@example.com", 
          collaborators: ["user1@example.com", "user3@example.com"], 
          tasks: [sample_task1, sample_task2],
          charts: [sample_chart1],
          works: [sample_work1],
          tags: ["integration", "platform", "api", "backend"], 
          priority: { type: 'High' },
          system_environment_info: { type: 'Some', 0: { os: "Linux", runtime: "Gleam v1.0", database: "PostgreSQL 15" } },
          source_control_details: { type: 'Some', 0: { branch: "develop", repo_url: "https://github.com/your_org/your_project", last_commit: "a1b2c3d4" } },
          documentation_references: { type: 'Some', 0: { readme: "README.md", api_docs: "/docs/api", wiki: "https://wiki.example.com/project" } }
        };
        // Wrap in Gleam's Ok constructor format
        resolve({ type: 'Ok', 0: project_detail_data });
      } else {
        // Wrap in Gleam's Error constructor format
        resolve({ type: 'Error', 0: `Project with ID '${id}' not found (placeholder FFI).` });
      }
    }, 300); // Simulate 300ms delay
  });
} 