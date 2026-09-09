# Third-party notices and scientific references

## Mangrove Tree

Nice2meetU2 — https://sketchfab.com/3d-models/mangrove-tree-5d4542431caa46f0b6f1feb089fc19dd
CC BY 4.0: https://creativecommons.org/licenses/by/4.0/
The derived canopy selects upper geometry, changes scale, and bakes texture colours to vertices. Lower trunk and roots are replaced by shared procedural geometry. Original files are unchanged.

## Numerical references

The solver is a new compact hydrostatic-reconstruction/Rusanov implementation, informed by the inspected Inkwell reference and Celeris shallow-water architecture. It is not a validated port of the full Celeris solver. The following notices are retained conservatively for the consulted implementations.

### inkwell-webgpu-water-main

MIT License

Copyright (c) 2026 James Addison

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.


### plynett.github.io-main

MIT License

Copyright (c) 2023 plynett

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.


## Scientific sources

- Celeris: https://arxiv.org/abs/1611.05984
- Mangrove root structure and flow: https://gmd.copernicus.org/articles/16/5847/2023/
- Cohesive deposition: https://www.hec.usace.army.mil/confluence/rasdocs/d2sd/ras2dsedtr/6.6/model-description/deposition
- Model assumptions and inspected source provenance: ARCHITECTURE-RESEARCH.md and RESEARCH-INPUTS.json.

## Visual upgrade

Ground materials: Brown Mud and Aerial Beach 01 by Rob Tuytel / Poly Haven, CC0. https://polyhaven.com/a/brown_mud and https://polyhaven.com/a/aerial_beach_01 . Exact downloaded maps and verified checksums: public/materials/sources.json.

Updated tree usage: complete bark/root and leaf/card geometry from the provided GLB, excluding its unrelated ground plane. Original UVs/normals/tangents retained; uniform scale and bounded ground alignment applied. Original source PNG alpha restored and colour texture resized to 2K. The earlier canopy-only modification note is superseded.

Inkwell dielectricFresnel reused and microfacet/absorption/refraction adapted in shaders/render.wgsl under the MIT notice above. The independent FFT wave displacement is not used.

Three.js 0.183.2 is included for a standalone diagnostic GLB comparison only. MIT license retained at public/vendor/three/LICENSE. Repository: https://github.com/mrdoob/three.js . It is not imported by the simulator.
