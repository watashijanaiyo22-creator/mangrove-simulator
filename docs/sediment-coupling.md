# Flow, sediment and visible morphology

## Existing implementation preserved

- `scenario.js`: initial `h`, `hC`, physical/initial bed, deterministic tree placement, GLB lower-surface projected areas in four height bands.
- `physics.wgsl` / `physics.js`: hydrostatic reconstruction, Rusanov water flux, donor-concentration `hC` flux, semi-implicit quadratic momentum drag, bed shear, erosion limited by hard-bottom stock, exponential deposition and accumulated exchange bed reconstruction.
- `gpu.js`: identical clock, boundary forcing and material uniforms for the two independent states. Only the vegetation switch differs.
- `render.wgsl` / `renderer.js`: physical free-surface mesh, GLB tree instancing, sand/mud PBR, shadows/reflections and Natural/diagnostic views.
- `tracers.js`: per-step GPU observation fields and local-flow tracers. CPU and GPU regression tests remain in use.

The runtime remains native JS + WebGPU/WGSL. A grid solver, instanced 3D roots and several thousand flow-following grains require GPU compute/rendering; ordinary controls remain accessible DOM elements. There is no Three.js migration or extra runtime dependency.

## Resistance

Default: 192 trees, 12 staggered rows, approximately 20 m between first/last centres, Cd 2 and `vegetationDragMultiplier = 8`. The multiplier is an explicit illustrative subgrid wake/interference correction to Cd. It does not change frontal geometry or create/remove water. It is not field-calibrated. The default effective diameter remains 1×.

Diameter options now stretch both GLB and root sample positions horizontally. Horizontal projected area scales linearly with horizontal stretch (vertical extent is unchanged). This widens the whole supplied root system and canopy, rather than reconstructing individual cylindrical roots. Mesh normals use inverse stretch; tangent directions use forward stretch. The initial terrain warp is shared. Physics still accounts for submergence/burial through the initial-root height bands.

`observations.js` defines matched area windows from forest centres: upstream 6–3 m ahead, inside first–last row, downstream 3–6 m beyond the last row; z 3–45 m. Dry cells contribute zero, and wet fraction is exported. Values are mean speed, not signed oscillatory velocity. The acceptance script samples four phases per 9 s wave and averages 90–180 s. It asserts >=50% downstream reduction for default forcing; the UI reports recent samples over 27 s. This is a basin-specific result, not a universal mangrove attenuation rate.

## Sediment and appearance

The physical source of truth remains `hC`. No particle can write to it or the bed. GPU emission compares new accumulated erosion against the previous state. A deterministic 12,288-slot pool per case samples bilinear local discharge/depth and uses midpoint advection, diffusion limited below 8% of local speed, shear-driven bounded vertical suspension, and settling gated by the same shear/settling coefficients. Sand/fine sizes and lifetimes are illustrative classifications of one physical sediment class. There is no independent sand/mud mass budget or resolved vertical turbulence. Particles fade at bed contact, expiry, drying or domain exit; these events never deposit physical mass.

Natural water optics integrate actual concentration along a refracted ray using Beer–Lambert absorption and sediment scattering, retaining floor visibility and Fresnel reflection. PBR sand/mud blending responds to physical bed change and wetness; textures remain fixed in world coordinates. Gold flow markers remain distinct from sediment grains and use actual velocity.

Rendered bed = initial bed + (physical bed − initial bed) × visualization multiplier. Options are 1, 3, 5, 10, 25 and 50; default 50 makes submillimetre changes visible at root scale after a few minutes. The multiplier never reaches compute uniforms. The free water surface and roots remain in physical world positions. Physical shoreline contours stay physical, including their initial reference. Thus the exaggerated bed's visible intersection with water is not a physical shoreline measurement. There is no accelerated morphology mode.

Both cases have identical optics, sediment particles, visualization multiplier, camera, lighting, forcing and material equations. The only rendering case branch draws vegetation and its diagnostic root field.

## Reproduce

```
npm start
npm run check
node scripts/sediment-qa.mjs
node scripts/sediment-regression.mjs
node scripts/observation-qa.mjs
node scripts/validate.mjs
```

Browser scripts use the existing bundled Playwright path. `LAB_URL=http://127.0.0.1:4183` supports a second local server (`PORT=4183 npm start`). Evidence is written under `evidence/` (locally ignored by Git). The new regression checks cover erosion-only emission, paired equality, local velocity advection, settling, pool reset, physical-state immutability, diameter-area monotonicity and CPU/GPU parity. Acceptance checks enforce finite/nonnegative state, zero water/sediment positivity repairs, water residual <0.01 m³ and sediment residual <0.05 kg, including boundary ledgers.

## Measured default result (2026-09-09)

Actual Chromium/Metal WebGPU execution, wave amplitude 0.18 m, tide 0 m, dt 0.018 s. Four samples per wave, 40 samples from 92.25 through 180 s. Downstream mean: without 0.191448 m/s, with 0.073270 m/s, reduction 61.728%. At 180 s, forest-interior cumulative erosion: without 641.508 kg, with 51.411 kg; suspended mass: without 607.427 kg, with 86.042 kg. Downstream net bed mass change: without −59.735 kg, with +1.657 kg. Gross deposition need not be larger with vegetation: the unprotected case has much more available suspended sediment.

180 s water ledger residuals with/without: 0.0000594 / 0.0002499 m³; sediment: 0.0006803 / 0.0005444 kg. Water and sediment positivity repairs were zero through 360 s and all three existing low-wave/high-wave/water-level-bound scenarios. Existing observation QA measured about 60 fps at 4× and 8× playback. The final recorded close view also ran at 60 fps. CPU/GPU maximum absolute state discrepancy was 6.41e-7.

Evidence: `sediment-qa.json`, `sediment-regression.json`, `sediment-visual-qa.json`, `final-natural.png`, `final-grains-before.png`, `final-grains-after.png`, `final-terrain-1.png`, `final-terrain-50.png`, `final-mobile.png` and `final-natural-motion.webm` under `evidence/`.
