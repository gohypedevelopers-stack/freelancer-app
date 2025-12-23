
class ProjectTask {
  final String id;
  final String title;
  final String phaseId;

  const ProjectTask({
    required this.id,
    required this.title,
    required this.phaseId,
  });
}

class ProjectPhase {
  final String id;
  final String title;
  final String description;
  final List<ProjectTask> tasks;

  const ProjectPhase({
    required this.id,
    required this.title,
    required this.description,
    required this.tasks,
  });
}

final List<ProjectPhase> kProjectPhases = [
  ProjectPhase(
    id: 'phase_1',
    title: 'Requirement Gathering',
    description: 'Understand project goals, deliverables, timeline, and key stakeholders',
    tasks: [
      ProjectTask(id: 'p1_t1', title: 'Understand project goals, deliverables, timeline, and key stakeholders', phaseId: 'phase_1'),
      ProjectTask(id: 'p1_t2', title: 'Define project scope: phases, tasks, milestones, and responsibilities', phaseId: 'phase_1'),
      ProjectTask(id: 'p1_t3', title: 'Collect all relevant documents, tools, and team details', phaseId: 'phase_1'),
      ProjectTask(id: 'p1_t4', title: 'Finalize project plan, deliverables, reporting workflow, and approval process', phaseId: 'phase_1'),
      ProjectTask(id: 'p1_t5', title: 'Conduct stakeholder interviews', phaseId: 'phase_1'),
      ProjectTask(id: 'p1_t6', title: 'Analyze competitor websites', phaseId: 'phase_1'),
    ],
  ),
  ProjectPhase(
    id: 'phase_2',
    title: 'Planning & Scheduling',
    description: 'Create site map, wireframes, and verify content strategy',
    tasks: [
      ProjectTask(id: 'p2_t1', title: 'Create sitemap and user flow', phaseId: 'phase_2'),
      ProjectTask(id: 'p2_t2', title: 'Design low-fidelity wireframes', phaseId: 'phase_2'),
      ProjectTask(id: 'p2_t3', title: 'Select technology stack', phaseId: 'phase_2'),
      ProjectTask(id: 'p2_t4', title: 'Define database schema', phaseId: 'phase_2'),
    ],
  ),
  ProjectPhase(
    id: 'phase_3',
    title: 'Execution & Monitoring',
    description: 'Development and ongoing testing',
    tasks: [
      ProjectTask(id: 'p3_t1', title: 'Setup development environment', phaseId: 'phase_3'),
      ProjectTask(id: 'p3_t2', title: 'Frontend development - Home Page', phaseId: 'phase_3'),
      ProjectTask(id: 'p3_t3', title: 'Frontend development - Dashboard', phaseId: 'phase_3'),
      ProjectTask(id: 'p3_t4', title: 'Backend API implementation', phaseId: 'phase_3'),
      ProjectTask(id: 'p3_t5', title: 'Database integration', phaseId: 'phase_3'),
      ProjectTask(id: 'p3_t6', title: 'Integration testing', phaseId: 'phase_3'),
    ],
  ),
  ProjectPhase(
    id: 'phase_4',
    title: 'Reporting & Project Closure',
    description: 'Final delivery and handoff',
    tasks: [
      ProjectTask(id: 'p4_t1', title: 'User Acceptance Testing (UAT)', phaseId: 'phase_4'),
      ProjectTask(id: 'p4_t2', title: 'Fix reported bugs', phaseId: 'phase_4'),
      ProjectTask(id: 'p4_t3', title: 'Deploy to production', phaseId: 'phase_4'),
      ProjectTask(id: 'p4_t4', title: 'Hand over source code and documentation', phaseId: 'phase_4'),
    ],
  ),
];
