[![Actions Status](https://github.com/FCO/Sourcing/actions/workflows/test.yml/badge.svg)](https://github.com/FCO/Sourcing/actions)

# Sourcing - Event Sourcing Framework for Raku

Sourcing is an event sourcing framework for Raku that provides structured constructs for handling events, projections, aggregations, and processes. It is designed to facilitate building robust and scalable event-driven applications.

## Features

- **Events**: Store and represent state changes.
- **Projections**: Consume events, update themselves, and provide atomic query methods (marked as `is query`).
- **Aggregations**: Special types of projections that can have atomic command methods (marked as `is command`). They ensure that the most recent event has been processed before executing a command.
- **Processes (Saga)**: Special aggregations that can manage transactions across multiple aggregations, handle compensating commands in case of failures, and automatically trigger commands based on timeouts.

## Example

A basic example can be found in the repository: [Account Example](https://github.com/FCO/Sourcing/tree/main/examples/Account).

### Components in the Example

- **Aggregation: `Account`**
  - Handles commands for withdrawing and receiving amounts.
  - Emits events representing the performed operations.
- **Projections: `AccountTotalReceived` and `AccountTotalSent`**
  - Track total received and sent amounts for an account.
- **Process: `Transaction`**
  - Moves funds between accounts.
  - Rolls back operations in case of failure.

## Status

This project is in its early development stage. Feedback and contributions are welcome!

## Get Involved

If you're interested, check out the repository and share your thoughts:
[GitHub Repository](https://github.com/FCO/Sourcing)

Any feedback or suggestions would be highly appreciated!
