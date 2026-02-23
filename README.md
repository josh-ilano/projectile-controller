# Projectile Controller (Roblox / Luau)

A modular projectile framework for Roblox combat systems, built to support **linear**, **curved**, **multi-stage**, and **moving-target-tracked** projectiles.

This repository demonstrates practical gameplay engineering skills in:
- Real-time simulation and interpolation
- Event-driven client/server architecture
- Reusable module design in Luau
- Extensible move/effect pipelines for game abilities

---

## Why this project matters (for recruiters)

This codebase is a strong example of gameplay systems engineering for multiplayer games:

- **Reusable architecture:** New abilities are integrated by adding move definitions and mapping them to projectile behaviors, rather than rewriting flight logic.
- **Live target tracking:** Curved and linear paths can adapt in real time to moving casters/targets.
- **Multi-stage projectile support:** A single move can chain multiple path segments and intermediate effects before impact.
- **Client/server coordination:** Client visualizes motion and only the casting player requests server-side application via remote event.
- **Clean separation of concerns:** Wrapper orchestration, invoker lifecycle, and path math are split into focused modules.

---

## Technical highlights

### 1) Projectile wrapper pipeline
`ProjectileWrapper` is the high-level orchestrator that packages move metadata and lifecycle hooks:
- `Cast` effect (on cast)
- Projectile generation and tracking
- Optional intermediate effects (for sub-path hits)
- Impact effect (on final hit)
- Optional end-cast stage

It also supports per-move initialization and optional caster substitution (e.g., casting from a summoned object).

### 2) Invocation + lifecycle handling
`ProjectileInvoker` executes projectile motion and controls sequencing:
- Handles single and multi-segment paths
- Waits for each segment’s completion before progressing
- Triggers server remote event (`ApplyMove`) from the casting client on final impact
- Supports trail-style projectiles for continuous visual effects

### 3) Motion/path modeling
`ProjectileTracked` handles runtime kinematics and path traversal:
- Supports **Linear**, **Quadratic**, **Cubic**, and **Quartic** Bézier variants
- Recomputes effective control points as endpoints move (dynamic tracking)
- Uses heartbeat-driven stepping and speed-based progression (`studs/sec` style movement)
- Includes recursive magnitude approximation (de Casteljau-based subdivision) for improved travel-length estimation

### 4) Move-specific projectile composition
`ProjectileLibrary` maps move names to projectile path objects and parameters (speed, curve type, chained phases). The project includes examples such as:
- Single linear travel
- Curved travel
- Chained segment travel (`PoisonArrow` style)
- Spread/spawned-origin variants (`Ayaka` style)
- Multi-target hop/chaining logic (`LightRay` style)

---

## Repository structure

```text
src/
  client/
    init.client.luau              # client entrypoint
  server/
    init.server.luau              # server entrypoint
  shared/
    ProjectileWrapper/
      init.lua                    # high-level move/projectile wrapper
      ProjectileInvoker.lua       # runtime invocation & sequencing
      ProjectileLibrary/
        init.lua                  # per-move projectile constructors
        ProjectileTracked.lua     # dynamic tracked projectile math + movement
        ProjectileFixed.lua       # fixed waypoint visualization utility
default.project.json              # Rojo project mapping
```

---

## Tools & stack

- **Language:** Luau
- **Engine:** Roblox
- **Project sync/build:** Rojo
- **Architecture:** ModuleScript-based shared gameplay system

---

## Running locally

### Prerequisites
- [Roblox Studio](https://create.roblox.com/)
- [Rojo 7.x](https://rojo.space/)

### Build place file
```bash
rojo build -o "Game.rbxlx"
```

### Open + sync
1. Open `Game.rbxlx` in Roblox Studio.
2. Start sync server:

```bash
rojo serve
```

---

## Extending the system (adding a new move)

Typical integration flow:

1. Add a move/effect module with `Cast`, `Projectile`, and optional `Intermediate`, `Impact`, `End`, `Initialize` hooks.
2. Register the move in `ProjectileWrapperLibrary` so it routes to the desired invocation mode.
3. Add move tuning in `TRACKED_MOVES` if it should repeat/iterate.
4. Add a constructor in `ProjectileLibrary` defining path type, control points, endpoints, and speed.

This enables feature growth without changing the core projectile runtime.

---

## Engineering takeaways

This project showcases:
- Gameplay systems design for multiplayer action experiences
- Strong modularity and extensibility patterns
- Practical math application (Bezier/path approximation)
- Real-time simulation concerns (moving references, deterministic sequencing)
- Roblox-specific production patterns (RunService heartbeat loops, RemoteEvents, Debris cleanup)

If you are evaluating for gameplay programmer roles, this repository reflects ability to design reusable combat/motion systems rather than one-off scripted effects.
