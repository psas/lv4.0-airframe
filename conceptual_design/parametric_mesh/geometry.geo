// LV4 Parametric Geometry and Grid Generation Script
// All Dimensions are in Meters
Printf("Script Start") > "output.txt";
SetFactory("OpenCASCADE");

// Geometry Inputs 
diameter = 11.33*0.0254;
body_ld = 11.62; // Body Length to Diameter
nose_cone_ld = 4.0; // Nose Length to Diameter
nozzle_radius = 0.05156;
aft_ld = 0.5;  // Aft Length to Diameter

// Fin Inputs
// Assumes symmetric trapazoidal design
fin_outboard_length = 0.2;
fin_taper_angle = 15.0/180.0*3.14159; //rad
fin_span = 0.2;
fin_thickness = 0.25*0.0254;

// Farfield Inputs
farfield_type = 0;  // 0 - None, 1 - Sphere

// Mesh Spacing Inputs
nose_tip_lc = 0.01;
body_lc = 0.02;
aft_lc = 0.005;
fin_lc = 0.005;
farfield_lc = 1.0;
circum_layers = 10;

// Intermediate Body Parameters
radius = diameter*0.5;
nose_cone_length = diameter*nose_cone_ld;
ogive_radius = (radius^2 + nose_cone_length^2)/(2*radius); 
body_length = diameter*body_ld; 
body_aft_x = nose_cone_length + body_length; 
aft_length = diameter*aft_ld;
nozzle_x = body_aft_x + aft_length;

// Intermediate Fin Paramters
//fin_center_chord_x = body_aft_x-fin_inboard_length/2;
fin_center_chord_x = body_aft_x - (fin_outboard_length/2 + fin_span*Cos(fin_taper_angle));
fin_outboard_distance = radius+fin_span;

Printf("Nose Cone Length: ’%g’", nose_cone_length) >> "output.txt";
Printf("Ogive Radius: ’%g’", ogive_radius) >> "output.txt";
Printf("Fin Center Chord: ’%g’", fin_center_chord_x) >> "output.txt";
Printf("test: ’%g’", Sin(fin_taper_angle)) >> "output.txt";

// Main Body
// Points
body_p1 = newp; Point(body_p1) = {0,0,0,nose_tip_lc};  // Nose Cone Tip
body_p2 = newp; Point(body_p2) = {nose_cone_length,0,radius,body_lc}; // Cone-Cylinder Interface
body_p3 = newp; Point(body_p3) = {nose_cone_length,0,(radius-ogive_radius),body_lc}; // Ogive Radius Center
body_p4 = newp; Point(body_p4) = {body_aft_x,0,radius,aft_lc}; // End of Body
body_p5 = newp; Point(body_p5) = {nozzle_x,0,nozzle_radius,aft_lc}; // End of Nozzle 
body_p6 = newp; Point(body_p6) = {nozzle_x,0,0,aft_lc}; // Center of Nozzle 

// Lines
body_l1 = newreg; Circle(body_l1) = {body_p1,body_p3,body_p2};
body_l2 = newreg; Line(body_l2) = {body_p2,body_p4};
body_l3 = newreg; Line(body_l3) = {body_p4,body_p5};
body_l4 = newreg; Line(body_l4) = {body_p5,body_p6};

// Extrude Surfs
// Axis, Point, Angle 
Extrude { {1,0,0} , {0,0,0} , -Pi/3 } {
  Curve{body_l1,body_l2,body_l3,body_l4}; Layers{circum_layers}; Recombine;
}
Extrude { {1,0,0} , {0,0,0} , Pi/3 } {
  Curve{body_l1,body_l2,body_l3,body_l4}; Layers{circum_layers}; Recombine;
}

// Fin
// Points
Point(50) = {fin_center_chord_x-fin_outboard_length/2,0,fin_span+radius,fin_lc};
Point(51) = {fin_center_chord_x+fin_outboard_length/2,0,fin_span+radius,fin_lc};
Point(52) = {fin_center_chord_x+(fin_span+radius)*Cos(fin_taper_angle),0,0,fin_lc};
Point(53) = {fin_center_chord_x-(fin_span+radius)*Cos(fin_taper_angle),0,0,fin_lc};

// Lines
Line(50) = {50,51};
Line(51) = {51,52};
Line(52) = {52,53};
Line(53) = {53,50};

// Create Lines
starboard_lines[] = Dilate {{fin_center_chord_x,0,0}, 0.95} { Duplicata{ Line{50,51,52,53}; } };
Translate{0,fin_thickness/2,0} { Line{starboard_lines[]}; }
port_lines[] = Translate{0,-fin_thickness,0} { Duplicata { Line{starboard_lines[]}; } };

// Create Surfaces
Curve Loop(50) = {50,51,52,53};
Curve Loop(51) = {starboard_lines[]};
Plane Surface(51) = {51};
Curve Loop(52) = {port_lines[]};
Plane Surface(52) = {52};

edge_1() = ThruSections {50,51};
edge_2() = ThruSections {50,52};

// Create Volume to Trim Body
Surface Loop(100) = {51,52,53,54,55,56,57,58,59,60};
Volume(100) = {100};
new_body_surfs() = BooleanDifference { Surface{3,4}; Delete; } { Volume{100}; };
Delete{ Volume{100}; }; // Note using delete here, presevers the underline objects

// Create Cutter to Trim Fin
Cylinder(101) = { 0,0,0,body_aft_x*1.2,0,0,radius};
new_fin_surfs() = BooleanDifference { Surface{51,52,53,54,55,56,57,58,59,60}; Delete; }  { Volume{101}; Delete; };
Delete{ Line{port_lines[]}; };
Delete{ Line{starboard_lines[]}; };

// Apply Spacings
new_body_points() = PointsOf{ Surface{new_body_surfs()}; }; 
Characteristic Length{ new_body_points() } = body_lc;

// Join
new_surfs() = BooleanUnion { Surface{new_body_surfs()}; Delete;} { Surface{new_fin_surfs()}; Delete;};

// Apply Spacings
//new_fin_points() = PointsOf{ Surface{new_fins_surfs()}; }; 
new_fin_points() = PointsOf{ Surface{51,52,53,54,56,57,58,60}; }; 
Characteristic Length{ new_fin_points() } = fin_lc;
Characteristic Length{4} = fin_lc;


// Create farfield
If ( farfield_type == 1)
  Printf("Farfield Type: Sphere") >> "output.txt";
  farfield_p1 = newp; Point(farfield_p1) = {-5*body_length+body_aft_x,0,0,farfield_lc};
  farfield_p2 = newp; Point(farfield_p2) = {body_aft_x,0,0,farfield_lc};
  farfield_p3 = newp; Point(farfield_p3) = {body_aft_x,0,5*body_length,farfield_lc};
  farfield_p4 = newp; Point(farfield_p4) = {5*body_length+body_aft_x,0,0,farfield_lc};
  c1 = newreg; Circle(c1) = {farfield_p1,farfield_p2,farfield_p3};
  c2 = newreg; Circle(c2) = {farfield_p3,farfield_p2,farfield_p4};

  // Create Axis Lines
  farfield_l1 = newreg; Line(farfield_l1) = {farfield_p1,body_p1};
  farfield_l2 = newreg; Line(farfield_l2) = {body_p6,farfield_p4};

  // Create outer surface
  // Axis, Point, Angle 
  Extrude { {1,0,0} , {0,0,0} , -Pi/3 } {
    Curve{c1,c2}; Layers{circum_layers}; Recombine;
  }
  Extrude { {1,0,0} , {0,0,0} , Pi/3 } {
    Curve{c1,c2}; Layers{circum_layers}; Recombine;
  }


EndIf
