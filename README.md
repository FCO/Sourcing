# Sourcing - Event Sourcing Framework for Raku

Sourcing is an event sourcing framework for Raku that provides structured constructs for handling events, projections, aggregations, and processes. It is designed to facilitate building robust and scalable event-driven applications, aligning closely with the principles of CQRS (Command Query Responsibility Segregation).

## What Is Event Sourcing?
Event sourcing is a pattern where state changes in a system are captured as a sequence of events. Rather than storing the current state of an entity, event sourcing persists all the events that led to the current state. This approach:

- Makes it easier to maintain a full audit log of everything that happened in the system.
- Simplifies debugging and troubleshooting by replaying events.
- Enables more flexible updates to derived data, such as read models and projections.

## What Is CQRS?
Command Query Responsibility Segregation (CQRS) is a pattern that separates reads from writes. In a CQRS-based system, write operations (commands) and read operations (queries) are handled differently, often backed by different models or data stores. This separation:

- Allows for scaling read and write workloads independently.
- Simplifies complex business logic by isolating command processing.
- Improves performance by optimizing each side (queries vs. commands) for different needs.

### Commands
Commands represent **intent to change state**. In Sourcing, commands are implemented in **Aggregations** using methods marked with `is command`. When a command is issued, it is validated against the current state, and if valid, it emits one or more events representing the state change.

### Queries
Queries represent **data retrieval**. In Sourcing, queries are typically implemented in **Projections** using methods marked with `is query`. These methods provide consistent and up-to-date data derived from events.

## What Is a Saga?
A Saga (or Process Manager) is a pattern used to maintain data consistency across microservices or bounded contexts by coordinating multiple distributed transactions. Each transaction updates data within a single service, publishing events or invoking commands that trigger subsequent transactions in other services. If any transaction fails, compensating actions are taken (if possible) to undo or mitigate the changes.

In Sourcing, a **Process** is a specialization of an **Aggregation** that implements saga-like behavior. It can call commands on multiple aggregations, handle compensation commands in case of errors, and automatically run commands if a timeout is reached.

## Features

- **Events**: Store and represent state changes.
- **Projections**: Consume events, update themselves, and provide atomic query methods (marked as `is query`).
- **Aggregations**: Special types of projections that can have atomic command methods (marked as `is command`). They ensure that the most recent event has been processed before executing a command.
- **Processes (Saga)**: Special aggregations that can manage transactions across multiple aggregations, handle compensating commands in case of failures, and automatically trigger commands based on timeouts.

## Example

A basic example can be found in the repository: [Account Example](https://github.com/FCO/Sourcing/tree/main/examples/Account).

### Components in the Example

- **Aggregation: `Account`**
  - Handles commands (withdraw, receive) for updating the account balance.
  - Emits events representing the performed operations.
- **Projections: `AccountTotalReceived` and `AccountTotalSent`**
  - Track total received and sent amounts for an account.
  - Provide query methods for retrieving these totals.
- **Process: `Transaction`**
  - Moves funds between accounts using saga-like orchestration.
  - Rolls back operations in case of failure.

## Status

This project is in its early development stage. Feedback and contributions are welcome!

## Get Involved

If you're interested, check out the repository and share your thoughts:
[GitHub Repository](https://github.com/FCO/Sourcing)

Any feedback or suggestions would be highly appreciated!

