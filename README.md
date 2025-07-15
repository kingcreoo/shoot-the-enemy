# Shoot the Enemy!

A low‑poly, tactical war‑sim built on Roblox with performance in mind.

## Concept

Shoot the Enemy! drops the player onto a stylised straight‑line battlefield where they command a squad of soldiers against waves of AI foes. The focus is snappy gun‑play, cartoony explosions, and smooth performance across devices. Desktop users can toggle a high‑detail mode with beefier models and effects, while mobile players benefit from aggressive optimisation.

## Core gameplay loop

- Players choose a level from various universes
- Control your squad as endless waves and enemies approach you
- Collect rewards and upgrade your team over time

## Feature Highlights

Procedural Levels – Offensive & defensive templates picked at runtime by LevelSelector and orchestrated by LevelController.

Modular Architecture – Clean Luau modules, single‑responsibility, hot‑reload friendly with Rojo + VS Code.

Performance Tooling – Built‑in profiler overlay, tween pooling, connection throttling, and memory‑leak guards ensure a stable 60 FPS target.

## Art Direction

The game adopts a low‑poly minimalist aesthetic that is easy on performance and instantly readable, yet unafraid to drop a more intricate build when it adds wow‑factor. Simple shapes, bold colours, and clean silhouettes keep the action clear and satisfying.

## Code Style & Conventions

4‑space indent, no tabs.

Prefer task.spawn over coroutine.wrap.

Avoid wait(); use task.wait() with explicit delta for deterministic timing.

Modules never mutate globals—dependencies are injected through constructors.

## Roadmap

✅ Completed

Level Selector 🎯

🛠️ In Progress

Core Gameplay Loop

✅ Enemy spawning & animations

✅ Bullet system

✅ Bullet & explosion pooling

✅ Team controls & basics

⏳ Ending with rewards

⏳ Security checking

🔜 To Do

⚔️ Flesh out additional enemy types

👩‍✈️ Operators (hero units)

🛡️ In‑level upgrades, boosts & obstacles
