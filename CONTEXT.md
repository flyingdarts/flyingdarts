# Flyingdarts

Open-source, community-driven real-time darts platform. **Players** play **X01** against each other with live scoring, **Friends**, and a video **Meeting**. Domain language for this product remote — IaC lives in the sibling CDK remote.

## Language

**Flyingdarts**:
The product and GitHub org; live on `flyingdarts.net`.
_Avoid_: Flying Dart; Flying Darts; FD as the product name (`fd-app` is the Angular app only)

**X01**:
The darts game format this platform scores (301, 501, and the rest of the X01 family).
_Avoid_: darts (the sport in general); 501 as the only mode

**Game**:
One live **X01** session between **Players**.
_Avoid_: match; room; lobby (unless you mean the waiting UI)

**Player**:
A person signed in to play or score a **Game**.
_Avoid_: user; account; member

**Signalling**:
The WebSocket microservice that orchestrates connections for a live **Game**.
_Avoid_: websocket (the transport); Backend (the game-logic Lambda)

**Friends**:
The REST social graph of **Player** relationships.
_Avoid_: contacts; followers

**Meeting**:
The Dyte-backed video session attached to a **Game**.
_Avoid_: call; Zoom; video room

**Authress**:
The identity provider for **Player** sign-in.
_Avoid_: Cognito as the product IdP; treating the C# authorizer as identity

## Features

- Real-time **X01** over API Gateway WebSocket (`Signalling` + game API)
- **Friends** over API Gateway REST
- **Meeting** video via Dyte
- **Authress** identity; C# Lambda authorizer is live; Rust authorizer is a TODO in CDK
- Angular web app is the game table; Flutter companion is the on-device score pad (speech-to-text)
- React + Vite marketing site on the Marketing hostnames
- Community Discord: https://discord.gg/BqQxwfdDhC

## How it is built

Turborepo + Beachball monorepo: Angular 18 `fd-app`, Flutter `flyingdarts_mobile`, React marketing, .NET 8 Lambdas, Rust authorizer. See [CONTEXT-MAP.md](CONTEXT-MAP.md) for paths.

## Boundaries

- Owns product code in this remote (frontends, Lambdas, shared packages).
- Does **not** own IaC. CDK is [flyingdarts/flyingdarts.cdk](https://github.com/flyingdarts/flyingdarts.cdk). In the mikepattyn umbrella that checkout is the sibling gitlink `apps/flyingdarts/flyingdarts.cdk` ([CONTEXT](../flyingdarts.cdk/CONTEXT.md)).
- Root README and `docs/README.md` still mention `packages/tools/dotnet/Flyingdarts.CDK.Constructs` and `apps/tools/dotnet/cdk`. Those trees are gone — do not hunt for them here and do not copy stacks into mikepattyn `infra/cdk/`.
- Not a mikepattyn **Application**: no `AppSlug` under `mikepattyn.nl`, no `make deploy-*` from that umbrella.

## Relationships

- A **Game** is one **X01** session for one or more **Players**
- **Signalling** connects **Players** to a **Game**; the game API owns scoring
- A **Meeting** belongs to a **Game**
- **Friends** relates **Players**; it is not a **Game**
- **Authress** authenticates a **Player**; the authorizer Lambda only checks that token

## Example dialogue

> **Dev:** "The Flutter app is the main Flying Darts client, and CDK is under `packages/tools/dotnet`, right?"
> **Domain expert:** "No — the product is **Flyingdarts**. Angular `fd-app` is the game table; Flutter is the companion score pad. IaC is the sibling **flyingdarts.cdk** remote, not this tree."

## Flagged ambiguities

- "FD" meant both the product and the Angular app — resolved: product is **Flyingdarts**; `fd-app` is the Angular app
- "Backend" meant both the game-logic Lambda and all of AWS — resolved: game API vs **Signalling** vs **Friends** vs CDK
- "User" vs **Player** — resolved: signed-in people in this product are **Players**
