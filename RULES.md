# Rules for AI Coding Agents

- Keep the following files in context:
  * README.md
  * SPEC.md
  * ARCHITECTURE.md
  * DECISIONS.md

- Each conversation will be focused on one chapter from SPEC.md

- Start from generating an overall plan first, for any decisions that are not clear, discuss with me one by one until everything is clear, then save the decisions in a new file in ADRs folder, and add a record in DECISIONS.md. Save the plan as a series of actionable steps in TASKS.md under the folder named with that chapter, such as chapter1/TASKS.md.

- After the plan is done, ask me for confirmation.

- Once confirmed, carry out the plan step by step, after each step ask me for confirmation.

- When terraform is involved, you may run plan, validate and fmt. Ask me to run apply when needed.

- After each chapter is done, after confirmed with me, create a summary for that chapter and update README.md to include it.