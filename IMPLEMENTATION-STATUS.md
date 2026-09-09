# Latest: coupled sediment and restoration belt

The current implementation and reproduction commands are in [docs/sediment-coupling.md](docs/sediment-coupling.md). Older observations below describe prior defaults.

# Visual/model update — 2026-09-05

The initial canopy-only implementation below is superseded. Current runtime retains the supplied full root/trunk/leaf meshes and original maps, restores source leaf alpha, adds verified Poly Haven CC0 ground materials, Inkwell-derived water optics, alpha-aware shadows, reflection/refraction, and finite basin sides. Horizontal orbit is reversed; Shift-drag pans.

Verification: evidence/update-qa.json. 4× and 8× each maintained 60fps over 15-second checks. 360 simulated seconds passed water/sediment residual gates (water <0.001m³; sediment <0.001kg) without positivity correction. Model root projected area changes by 0.0068% under grid refinement. This tests geometric rasterization, not hydrodynamic grid convergence. Full photorealistic equivalence to the reference images is not claimed.

A complete corrected source-scene GLB is available at public/tree/mangrove-restored.glb. It preserves original geometry/accessors and restores only leaf colour/alpha; original assets remain unchanged. Runtime omits the asset ground plane to use the simulated terrain.

Details: docs/visual-upgrade.md. Earlier results below are historical and use the replaced procedural roots.

---

# Initial implementation — 2026-09-05

A runnable first version is available at localhost:4173 (`npm start`). Original assets and archives are unchanged. Production runtime: native JavaScript modules, raw WebGPU compute/rendering, no npm dependencies. This narrows and changes the preliminary Celeris/TypeScript/Vite recommendation; see README.md.

Implemented: independent synchronized A/B basins; long-period waves; wet/dry shallow water; submerged segment-derived root drag; one-class suspended sediment; finite erodible bed; conservative erosion/deposition exchange; fixed-datum shoreline; low-flow refuge visualization; observation modes, two experiment presets, pause/speed/reset, camera/keyboard, canopy inspection, local JSON export, explanatory limits/credits.

Verified on this Mac's Apple Metal adapter in Playwright Chromium:

- 8 CPU reference/physics tests pass.
- 50-step GPU/CPU maximum absolute difference: 6.26e-7.
- Standard forcing, 612 simulated seconds: no nonfinite state, negative water or sediment, or water positivity repair.
- Water budget residual A/B: 0.000043 / 0.000263 m³. Sediment residual: -0.000099 / -0.001893 kg, including boundary exchange.
- Same experiment: erosion 1886 / 2002 kg; reference shoreline retreat 13.3 / 18.7 mm. These are uncalibrated model results.
- Calm 0.06m amplitude, 180 simulated seconds: net deposition 11.36 / 10.94 kg.
- 0.35m amplitude at -0.2m and +0.3m levels: 180 simulated seconds each, finite and nonnegative.
- 60 seconds continuous wall-clock rendering: 60fps, approximately 4× physical speed. This is not a 10-minute thermal soak.
- A/B controls, presets, dialog escape, keyboard camera, 390px overflow and reduced-motion layout checked. Final images inspected; mobile legend overlap repaired. No browser errors in final runs.

Evidence: evidence/final-qa.json, latest-physics.json, scenarios.json and final-*.png. The early latest-physics/scenarios total sediment field omitted the constant initial erodible stock; final-qa includes that stock. Flux residuals and mass exchanges are unchanged by this accounting offset.

Still required before claiming scientific/assignment-ready completion:

- Hydrodynamic and morphodynamic grid/time-step convergence, and independent wave-transmission benchmark; CPU/GPU parity alone is not physical validation.
- A 10-minute wall-clock thermal soak and a full presentation rehearsal.
- More realistic optical/asset refinement; current rendering prioritizes inspectable computed state.
- Root wake turbulence, underground reinforcement, biological behaviour and real-site calibration remain intentionally outside model scope.

The initial solver relies on restricted CFL-safe forcing and monitors positivity repairs; it is not a general positivity-preserving solver for arbitrary configurations. Side boundaries are reflecting basin walls. Measurements describe this basin, not open-coast predictions.

## Synchronized observation update

Added paired live canvases with one clock and shared camera; numbers-hidden observation; per-physics-step GPU flow tracers; viewing-ray integration of suspended concentration; initial/current fixed-datum shoreline; direct diagnostic colour through water. No modification to sediment exchange or bed displacement magnitude. Tracer checks: zero still-water movement, zero disabled-root A/B mismatch, zero deterministic-reset error. CPU checks still pass. Camera input from either viewport, visibility toggles and budget residuals are browser-tested in evidence/observation-qa.json. Performance runs preserve requested 4×/8× speeds; observed frame rates vary with load and are recorded per run.

Remaining limitation: natural rendering alone does not reliably communicate millimetre-scale shoreline evolution. Bed-change mode and close inspection are needed; no claim of reference-image photorealism or all-four-phenomena natural-view readability is made.

### Latest visual/arrangement update
- Added advected foam observation memory, locally persistent ground wetness, and 12s RMS hydraulic shelter visualization; verified no feedback into scientific state (`evidence/surface-qa.json`).
- Added 48-tree original / 96-tree aligned / 96-tree staggered arrangements; default staggered. Every change resets both cases and rebuilds GLB-derived root resistance.
- Controlled layout experiment found 4.6% vs 8.8% RMS flow reduction for original vs dense staggered, in the specified fixed strip/time window; aligned and staggered were effectively equivalent. Full measurements in `evidence/layout-experiment.json`.
- Dual-view observation QA covers still-water tracers, identical disabled-root tracers, reset, mass budgets, shared camera, toggles, and 4×/8× throughput. Still not a calibrated coastal prediction or reference-image photorealism guarantee.

### 2026-09-06 follow-up
- Removed independent travelling optical waves and scrolling foam noise; surface motion follows calculated water.
- Added wide-belt comparison; measured weaker shoreward RMS attenuation than existing dense layout, so retained existing default.
- Added up-to-32× playback and paired shoreline close-up with pixel-width initial/current guides. Geometry and physical dt are unchanged.
- Completed 1080s paired GPU run; shoreline position difference ~2.46cm, sediment residual <0.004kg, no positivity corrections. See long-observation and width-experiment evidence.
