# Projectile Controller (Roblox / Luau)

A modular projectile framework for Roblox combat systems, built to support **linear**, **curved**, **multi-stage**, and **moving-target-tracked** projectiles.
[ProjectileTracked.lua]https://github.com/josh-ilano/projectile-controller/blob/main/src/shared/ProjectileWrapper/ProjectileLibrary/ProjectileTracked.lua#L265-L321
---
## Notable Algorithm
CalculateMagnitude — Recursive Arc-Length Approximation
The CalculateMagnitude method numerically approximates the arc length of a Bezier curve using recursive subdivision based on de Casteljau’s algorithm.

**Problem:** Bezier curves are parameterized by t, not arc length. This means uniformly increasing t does not produce uniform spatial motion. To move a projectile at constant speed, we must approximate the true distance along the curve.
  
**Approach:** Midpoint Subdivision (t = 0.5)
1) Uses de Casteljau’s algorithm to split the curve into two sub-curves.
2)  Generates left and right control point sets.
3) Piecewise Linear Approximation
4) Connects sampled points along the subdivided curve.
5) Computes total magnitude as the sum of linear segment distances.
  
**Recursive Refinement:**
- If recursion depth j > 0, each sub-curve is subdivided again.
- Results from both halves are summed.
- Greater depth increases precision at higher computational cost.

**Detailed Explanation:** Traditional Bezier sampling evaluates the curve at uniform parameter intervals (e.g., 0%, 10%, 20%, etc.). However, Bezier curves are not linear in parameter space, so equal t steps do not produce equal spatial distances. This can lead to clustered points in some regions and sparse coverage in others, especially in areas of high curvature.
This implementation instead uses recursive subdivision based on de Casteljau’s algorithm. Rather than relying on uniform parameter increments, it splits the curve geometrically using its control points. This produces more spatially consistent resolution, more stable arc-length approximation, and uniform motion regardless of curve shape.

---

## Features
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
