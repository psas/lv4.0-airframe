# Notes
Using OpenVSP (openvsp.org) to model the parametric geometry after exhausting all options with Gmsh.
Recommend using OpenVSP 3.19.0

# Model Revision History
* LV4 DAC0 Baseline
Based on Erin Schmidts initial MDO analysis
  * Assumes LV3 nosecone length to diameter
  * Wedge shaped airfoils

* LV4 DAC0 chamfered fins
Same as LV4 DAC0 Baseline, with exception to the airfoils are the same as LV3/3.1. This model is to
be used to determine differences in stability.
  * Assumes 10 deg chamfer angle machined on leading/trailing edges (see chamfered_rectangle_geometry_calc.ods) 
