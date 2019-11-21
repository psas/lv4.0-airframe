# Conceptual Design Notes
Goal is to provide a toolchain for a high fidelity end-to-end concpetual design process.
The steps are broken out as follows:

1. Parametric Geometry - OpenVSP
  * Outputs structure models
  * CFD surface mesh
2. Grid Generation - Gmsh
  * Generates a volume grid for CFD simulations 
3. Computational Fluid Dynamics 
  * Provides Aero Coefficients (Drag, Pitching Moment, etc.) 
