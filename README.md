# Mangrove Coastal Laboratory

Run `npm start`, then open http://127.0.0.1:4173 in a WebGPU-capable Chromium browser. Node 22+ is required. No npm install, runtime CDN or network service is needed. Original archive files are not served by the local server.

The full-screen basin runs two independent GPU simulations with identical initial conditions and wave forcing. Switch between **With mangroves** and **Without mangroves**; both continue at the same simulation time. Wave/water-level changes take effect when restarting both coasts. Observation modes show flow, suspended sediment, bed difference, potential hydraulic shelter and root resistance. Inspect roots hides the canopy and moves the camera closer. Export saves the experiment conditions and latest diagnostics locally.

`npm run check` runs syntax checks and CPU conservation/reference tests. Browser evidence is in `evidence/`; browser scripts use the Codex bundled Playwright installation on the development Mac.

## Scope and numerical limits

This is an educational depth-averaged NLSW model, not a calibrated real-coast forecast. The 72 × 48 m domain uses 120 × 80 cells and a fixed 0.018 s step. Root segments are distributed into four vertical frontal-area bands. Both root rendering and resistance derive from those segments. Fine root wakes, vertical velocity, root-generated turbulence, underground reinforcement and animal behaviour are omitted. The shelter overlay is instantaneous; the readout averages recent samples.

Water and suspended mass are transported by hydrostatic-reconstructed finite-volume fluxes. Erosion/deposition exchange mass with an erodible bed above a hard layer. Very small bed changes are reconstructed from accumulated exchanged mass. Boundary relaxation has an explicit water/sediment ledger. The offshore relaxation strip is excluded from morphological updates. The remaining boundaries reflect; the domain is an experimental basin, not an unbounded ocean. Reflections are shared by both cases.

The fixed timestep is limited to the exposed condition range, not arbitrary forcing. Negative-state repairs are monitored; this initial solver does not claim a general positivity-preserving flux limiter for arbitrary user inputs. Long-run and parameter-bound tests must accompany any expansion of ranges. No morphological multiplier is applied. The UI may achieve less than the requested speed if the GPU is busy.

## Architecture decisions made during implementation

To keep a reproducible offline runtime with no dependency installation, the initial implementation uses native JavaScript modules and a Node localhost server rather than TypeScript/Vite. Raw WebGPU owns both compute and rendering. The compact hydrostatic/Rusanov solver was implemented against a CPU reference, rather than extracting Celeris's tightly coupled pass sequence. This is a change from the preliminary Celeris-first plan and does not inherit Celeris's validation.

The tree asset is used for the upper geometry only. Shared generated trunk/root segments replace lower geometry so the visible roots correspond to resistance. See THIRD-PARTY-NOTICES.md for attribution and scripts/prepare-canopy.py for reproducible conversion.

## Visual update

The current renderer uses the supplied complete tree geometry with original maps and restored source alpha, plus verified CC0 mud/sand maps. The previous canopy-only representation and generated root sticks are superseded. Root resistance now comes from projected areas of the original lower meshes, including alpha-masked root cards. See docs/visual-upgrade.md and evidence/update-qa.json.

Horizontal orbit direction is reversed from the first version. Hold Shift while dragging to pan without changing angle. Right-drag and Shift-arrow keys also pan. All runtime materials are local. `scripts/prepare-tree.py` reads the original GLB and ZIP to reproduce the derived runtime meshes/materials; it requires NumPy and Pillow, but these are not needed to run the simulator.

## Synchronized observation update

The default is now two simultaneous, synchronized close views. **Side by side** returns to comparison after selecting a single coast. Camera orbit/pan/zoom from either canvas controls both; **Whole basin** restores a wide view. **Numbers** hides the bottom metrics, while **Flow tracers** toggles enlarged gold markers transported by the actual per-step water velocity. Tracers are not sediment grains and never alter the mass balance. Still-water motion, paired equality with roots disabled, and deterministic reset are checked in scripts/observation-qa.mjs.

Underwater attenuation integrates depth-averaged sediment concentration along a refracted viewing ray. It does not resolve a vertical sediment distribution. Bed change and hydraulic shelter modes show diagnostic fields directly so water reflections cannot conceal them. White dashed shoreline is the initial fixed-datum contour; gold is the current contour. Millimetre-scale shoreline changes are not magnified in geometry.

Evidence: evidence/observation-qa.json and observation-*.png. These changes improve observation; they do not establish photorealistic equivalence to the reference images or independent scientific validation.
