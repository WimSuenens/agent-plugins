## Processes and ports

For every role that starts processes (all but architect and product-owner):

- Stop only processes you started. Keep track of each one you start, and stop it by the end of your work at the latest. A process you did not start is never yours to stop or kill.
- Let the OS pick a port (port 0), or probe for a free one. Never free a port by stopping its owner.
- When a fixed port you need is taken, write a result with `Status: blocked`, naming the port and the process that holds it under `Missing`. The lead asks the person.

