# Visual upgrade evaluation — 2026-09-05

## Selected assets and implementation

- Poly Haven Brown Mud (Rob Tuytel), CC0: https://polyhaven.com/a/brown_mud. 1K colour, GL normal and AO/roughness/metal maps, downloaded from the official API's URLs and checked against its MD5 values. Source scale 1.3m. Blended with a rotated second sample to reduce visible repetition.
- Poly Haven Aerial Beach 01 (Rob Tuytel), CC0: https://polyhaven.com/a/aerial_beach_01. Same map set, 1K, source scale 30m. Used as secondary ground material; mud remains the dominant intertidal surface. License: https://polyhaven.com/license. Exact URLs/hashes in public/materials/sources.json.
- Supplied Mangrove Tree GLB: all 2,909 bark/root triangles and 1,231 leaf/branch/root-card triangles retained. Only the unrelated 128-triangle ground plane is omitted. This replaces the earlier upper-canopy extraction and generated sticks.
- Original leaf/card PNG from the supplied ZIP is used at 2K with its alpha channel. The downloaded GLB's material is OPAQUE and its embedded colour image has lost transparent coverage. An unchanged Blender GLB import reproduced the paper-like artifacts. The original source PNG retains alpha; its vertical orientation is aligned to glTF UVs. This repairs the asset's material rather than replacing its geometry.
- All model transforms are shared by visible geometry and root-field rasterization. Lower geometry follows the initial terrain slope with the same bounded ground alignment. Root projected surface samples include alpha-masked low root cards. The azimuth-averaged area is a subgrid closure, not a root-resolved flow solution. Original mesh/model files are unchanged.

## Rendering decision

Keep raw WebGPU because simulation buffers can be sampled directly by the renderer on the same GPUDevice. Inkwell's MIT dielectric Fresnel function is reused; its absorption/refraction and microfacet visibility approach are adapted. A full Inkwell FFT solver is not integrated because it would introduce an independent surface over the authoritative water calculation. Three.js is retained only as a local standard-GLTFLoader diagnostic reference, not a second runtime renderer.

Added: original textured meshes with normal mapping, mipmaps and shared instances; alpha-aware 2048px shadow map; half-resolution planar tree/terrain reflection; full-resolution scene colour/depth refraction with foreground rejection; Beer-Lambert extinction tied to water depth and suspended sediment; narrow wet-ground transition; calculated-slope sun glints; finite bed and water cutaway sides. Optical small-wave roughness is visual detail, not extra displaced fluid geometry.

The current natural scene is an improvement, but is not certified to match the supplied generated references' photorealism. Small morphodynamic differences remain millimetre-scale and need close observation or the bed-change mode. It would be misleading to inflate coastline retreat silently for visual impact. No real-site calibration or root-scale turbulence is added.

## Controls

Horizontal pointer orbit reverses the prior direction. Shift-drag (and right-drag) translates camera target and eye together, preserving angle. Shift-arrow keys pan. Wheel zoom remains bounded. Reset view and Inspect roots have explicit targets.

## Blender

Used connected Blender MCP to import the unchanged GLB into a separate scene and inspect its material appearance. The same opaque-card artifact was visible there. MCP later disconnected; source PNG inspection and reproducible local conversion completed the repair. No original .blend or GLB was overwritten. Blender is not a runtime dependency.

## Verification

See evidence/update-qa.json for the final surface-area resolution check, post-upgrade budget residuals, camera input assertions, and 4×/8× frame-rate measurements. Earlier evidence describes the replaced procedural-root version and must not be presented as current physics evidence. Model-derived resistance legitimately changes the A/B result.

## Observation pass

Two live canvases share the camera and simulation clock. Per-step passive GPU surface tracers move with computed velocity; they are explicitly enlarged diagnostic markers, not sediment particles or foam. Concentration extinction is sampled at eight points along the refracted underwater ray using the existing depth-averaged field. No vertical concentration solver is implied. Bed diagnostic colour uses a symmetric logarithmic magnitude scale (10 micrometre reference, saturation at 7mm) to reveal small changes without altering the geometry; the scale is labeled in the UI. Both sides use the same scale.

Tests and evidence: scripts/observation-qa.mjs / evidence/observation-qa.json. Tracers remain motionless in still water, match with roots disabled, and reset deterministically. Both canvas controls manipulate the shared camera. Recent dual-view checks achieved approximately 60fps at 4×/8×, with one earlier 4× run at 47fps; these are short runs, not thermal-soak guarantees.

## Surface history and planting experiment

Added per-cell observation memory: foam generated from computed Froude/surface slope/compression, advected with water and decaying over 3.5s; ground wetness retained locally and drying over 65s; squared speed averaged exponentially over 12s for the shelter overlay. These are optical/diagnostic closures, not new turbulence, moisture, or ecological solvers. They never feed back into hydro or sediment. GPU checks in `evidence/surface-qa.json` show zero physics difference with observations disabled, zero reset residue, and no foam in still water.

The arrangement selector resets both coasts together and rebuilds resistance from the same transformed GLB root surfaces used for rendering. Compare original 48 trees, 96 aligned trees, and 96 staggered trees. The default is now 96 staggered trees. At wave amplitude 0.18m and tide 0, measured RMS speed over the fixed x=53.1–59.1m strip during 72–143.7s was reduced by 4.62%, 8.72%, and 8.76%, respectively, relative to the same bare coast. Total cumulative erosion was 381.2, 350.4, and 350.5kg versus 418.9kg bare. These are one scenario's model results, not general field-effect estimates. Staggering did not materially outperform aligned planting; density explains the improvement. The staggered default avoids straight planted rows, not because the experiment proved a stronger physical advantage. Original arrangement remains selectable. Evidence and reproducible sampling: `scripts/layout-experiment.mjs`, `evidence/layout-experiment.json`.

The natural water's optical micro-slope and foam texture frequency were reduced after screenshot inspection showed excessive fine patterning. Default camera is elevated to reveal more of the water and forest belt. The numerical free surface and actual bed geometry remain authoritative.

## 2026-09-06: travelling-wave correction and shoreline inspection

Removed the independently travelling capillary normal layer and the time-times-local-velocity foam noise scroll. Visible wave normals now come from the solved free surface; foam coverage comes from the advected observation field. This deliberately reduces decorative detail to remove conflicting motion cues. Flow tracers are opt-in at startup. Increased diffuse sky fill slightly to retain root/leaf detail.

Added a 96-tree wide belt extending seaward from x=37m through 56.5m, compared with x=45m through 56.5m in the dense belt. This changes both belt width and submerged placement, not a pure width-only experiment. At the same forcing/time window, the fixed shoreward strip RMS reduction decreased from 8.76% to 7.41%, while cumulative erosion fell from 350.5kg to 344.2kg (bare:418.9kg). Keep dense staggered as default; expose wide belt for comparison. Evidence: `evidence/width-experiment.json`.

Added up-to-32× playback using unchanged physical timesteps; actual throughput is displayed (short test ~21.6× at 60fps). In 18 simulated minutes the paired mean reference-shoreline displacement differed by ~2.46cm. This is too small for full-basin perception. `Shore close-up` uses the same 3m camera distance and initial shoreline target for both basins, and zoom now permits 1.2m. Replaced the old 8mm-elevation-wide shoreline paint (roughly 28cm horizontal on this slope) with derivative-antialiased pixel-width reference lines, so the marker itself does not conceal centimetre-scale change. No bed scaling or morphodynamic acceleration was introduced. The close-up is an observation aid, not evidence of reference-image photorealism.

Longer run evidence: `scripts/long-observation.mjs`, `evidence/long-observation.json`; 1080s, finite states, zero positivity corrections, maximum final sediment residual below 0.004kg. Natural-view shoreline changes without guides remain hard to identify; centimetre-scale changes in a smooth muddy slope do not make a dramatic erosion scarp.

## Effective root diameter experiment

Added 1×/1.5×/2× effective diameter selector, retaining baseline at startup. It multiplies model-derived projected root area linearly (cylinder projected area scales with diameter), without changing drag coefficient, tree placement, source mesh, or raster support. This is an area-equivalent sensitivity experiment, not a geometric collider dilation or a resolved thicker-root model. The UI states the mesh is unchanged, and Root drag mode exposes the modified resistance field. Both coasts reset on selection; export records rootDiameter. A true geometric thickening would require a root centerline/radius representation, especially for alpha-masked root cards, and remains unimplemented.

Same 96-tree scenario and forcing: RMS speed reduction in the existing fixed strip was 8.76%, 12.35%, 15.58%; cumulative erosion 350.5, 323.2, 299.2kg vs bare418.9kg over143.7s. This is not field calibration. GPU field area ratios verified as1,1.5,2. Evidence: root-diameter-experiment.json and root-diameter-qa.json.
