## Shared resources

For every role that starts processes, when the item runs against real infrastructure (a database, a stand-in for an external system, a CI gate):

- Use your own database or schema and your own test identities, with random ids. Share no fixtures with other roles.
- Before a disruptive action on a shared resource (restart, reset, destroy, or deleting shared test data), write a question to the lead naming the resource and the action. Hold the action until a brief from the lead schedules it, for when the other roles are idle; go on with the rest of your work meanwhile.

