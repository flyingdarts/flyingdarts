# Context Map

Navigation index for the Flyingdarts product remote. Domain language lives in [CONTEXT.md](CONTEXT.md). IaC is **not** here — see the sibling CDK remote.

## Product language

| Path | Role |
|------|------|
| [CONTEXT.md](CONTEXT.md) | Glossary: Flyingdarts, X01, Game, Player, Signalling, Friends, Meeting, Authress |
| [AGENTS.md](AGENTS.md) | Read CONTEXT.md and this map first |

## Applications

| App | Path | Role |
|-----|------|------|
| fd-app | [apps/frontend/angular/fd-app](apps/frontend/angular/fd-app) | Angular 18 game table — live **X01** and **Meeting** |
| flyingdarts_mobile | [apps/frontend/flutter/flyingdarts_mobile](apps/frontend/flutter/flyingdarts_mobile) | Flutter companion score pad (speech, keyboard) |
| marketing | [apps/frontend/react/marketing](apps/frontend/react/marketing) | React + Vite marketing site |
| Game API | [apps/backend/dotnet/api](apps/backend/dotnet/api) | Handler `Flyingdarts.Backend.Api` — **X01** scoring |
| Signalling | [apps/backend/dotnet/signalling](apps/backend/dotnet/signalling) | Handler `Flyingdarts.Backend.Signalling.Api` |
| Friends | [apps/backend/dotnet/friends](apps/backend/dotnet/friends) | Handler `Flyingdarts.Backend.Friends.Api` |
| Authorizer | [apps/backend/dotnet/auth](apps/backend/dotnet/auth) | Handler `Flyingdarts.Backend.Auth` — C# Lambda authorizer |
| Rust authorizer | [apps/backend/rust/authorizer](apps/backend/rust/authorizer) | Replacement authorizer; CDK still wires the C# one |

## Packages

| Cluster | Path | Role |
|---------|------|------|
| Persistence | [packages/backend/dotnet/Flyingdarts.Persistence](packages/backend/dotnet/Flyingdarts.Persistence) | Single-table access patterns |
| Core / Lambda | [packages/backend/dotnet/Flyingdarts.Core](packages/backend/dotnet/Flyingdarts.Core), [Flyingdarts.Lambda.Core](packages/backend/dotnet/Flyingdarts.Lambda.Core) | Shared models and Lambda host |
| Connection / Dynamo / Meetings | [Flyingdarts.Connection.Services](packages/backend/dotnet/Flyingdarts.Connection.Services), [Flyingdarts.DynamoDb.Service](packages/backend/dotnet/Flyingdarts.DynamoDb.Service), [Flyingdarts.Meetings.Service](packages/backend/dotnet/Flyingdarts.Meetings.Service) | WebSocket, Dynamo, **Meeting** |
| Metadata / Notify | [Flyingdarts.Metadata.Services](packages/backend/dotnet/Flyingdarts.Metadata.Services), [Flyingdarts.NotifyRooms.Service](packages/backend/dotnet/Flyingdarts.NotifyRooms.Service) | Config and room notify |
| Rust auth | [packages/backend/rust/auth](packages/backend/rust/auth) | Auth utilities for the Rust authorizer |
| Flutter features | [packages/frontend/flutter/features](packages/frontend/flutter/features) | splash, profile, language, keyboard, speech |
| Flutter shared | [packages/frontend/flutter/api](packages/frontend/flutter/api), [authress](packages/frontend/flutter/authress), [core](packages/frontend/flutter/core), [shared](packages/frontend/flutter/shared) | API SDK, **Authress**, UI, config |
| TS config | [packages/tools/config](packages/tools/config) | Shared TypeScript config |

## IaC (other remote)

| Remote | Where in the umbrella | Role |
|--------|----------------------|------|
| [flyingdarts/flyingdarts.cdk](https://github.com/flyingdarts/flyingdarts.cdk) | `apps/flyingdarts/flyingdarts.cdk` | Domain, Frontend, Backend, Auth stacks |

Do not look for `packages/tools/dotnet/Flyingdarts.CDK.Constructs` or `apps/tools/dotnet/cdk` in this repo. Those trees are gone.

## Relationships

- **Product remote → CDK remote**: Lambdas and static sites in this tree; stacks and constructs in flyingdarts.cdk
- **fd-app → Game API + Signalling**: web table talks WebSocket; Flutter companion only scores
- **Signalling / Game API → Meeting**: Dyte credentials live on those Lambdas
- **Authorizer → Authress**: C# authorizer checks **Authress** tokens for WebSocket and Friends
