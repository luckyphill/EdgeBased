% l = LayerOnStroma(20,10,5,10,0,10,10,2);
% l.dataWriters = AbstractDataWriter.empty();
% l.RunToTime(9.52);
% l.NTimeSteps(4)
% c = l.cellList(5);
% c_area = c.GetCellArea() 
c_perim = c.GetCellPerimeter()

l.GenerateCellBasedForces();
f1 = [c.nodeList.force];
l.cellBasedForces(1).AddTargetAreaForces(c);
f2 = [c.nodeList.force];
l.cellBasedForces(1).AddTargetPerimeterForces(c);
f3 = [c.nodeList.force];

% Forces on nodes from every cell
f_all = f1
% Forces on c from area
f_area = f2-f1
% Forces on c from perimeter
f_perim = f3-f2

% Start again so extra forces aren't carried through
l = LayerOnStroma(20,10,5,10,0,10,10,2);
l.dataWriters = AbstractDataWriter.empty();
l.RunToTime(9.52);
l.NTimeSteps(5); % Step past division

c1 = l.cellList(5);
c1_area = c1.GetCellArea() 
c1_perim = c1.GetCellPerimeter()

c2 = l.cellList(end);
c2_area = c2.GetCellArea() 
c2_perim = c2.GetCellPerimeter()

l.GenerateCellBasedForces();
f11 = [c1.nodeList.force];
f21 = [c2.nodeList.force];

l.cellBasedForces(1).AddTargetAreaForces(c1);
f12 = [c1.nodeList.force];
f22 = [c2.nodeList.force];

l.cellBasedForces(1).AddTargetPerimeterForces(c1);
f13 = [c1.nodeList.force];
f23 = [c2.nodeList.force];

l.cellBasedForces(1).AddTargetAreaForces(c2);
f14 = [c1.nodeList.force];
f24 = [c2.nodeList.force];

l.cellBasedForces(1).AddTargetPerimeterForces(c2);
f15 = [c1.nodeList.force];
f25 = [c2.nodeList.force];

% Forces on nodes from every cell
f1_all = f11
% Forces on c from area
f1_area = f12-f11
% Forces on c from perimeter
f1_perim = f13-f12

% Forces on nodes from every cell
f2_all = f21
% Forces on c from area
f2_area = f24-f23
% Forces on c from perimeter
f2_perim = f25-f24






