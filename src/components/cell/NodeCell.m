classdef NodeCell < AbstractCell
	% A cell that is represented by a single node
	
	properties

		divisionSeparation = 0.05;

	end

	methods
		
		function obj = NodeCell(n, cellCycleModel, id)


			obj.nodeList = n;

			obj.CellCycleModel = cellCycleModel;
			
			obj.id = id;

			obj.ancestorId = id;

			n.cellList = obj;

			obj.cellType = 1;

			cellDataArray = [CellArea()];

			obj.AddCellData(cellDataArray);

		end


		function [newCell, newNodeList, newElementList] = Divide(obj)
			
			% When a node cell divides, the two new cells are placed
			% at a set distance apart, and the interaction forces are
			% allowed to take over to push them apart
			% To control the separation process, the preferred separation
			% can be specified between sister cells in the force calculator

			centre = obj.nodeList.position;

			theta = 2*pi*rand;
			direction = [cos(theta), sin(theta)];

			newPos = centre + direction * obj.divisionSeparation/2;
			oldPos = centre - direction * obj.divisionSeparation/2;

			% Create the two new nodes for the edge
			n = Node(newPos(1), newPos(2), -1);

			obj.nodeList.AdjustPosition(oldPos);

			newCCM = obj.CellCycleModel.Duplicate();

			newCell = NodeCell(n, newCCM, -1);

			newCell.newCellTargetArea = obj.newCellTargetArea;
			newCell.grownCellTargetArea = obj.grownCellTargetArea;
			
			newNodeList = [n];
			newElementList = Element.empty();

			obj.CellCycleModel.SetAge(0);
			obj.age = 0;

			newCell.sisterCell = obj;
			obj.sisterCell = newCell;

			newCell.ancestorId = obj.id;

			% Transfer the cell data objects to the new cell
			% This is a quick hack way to do it and it won't work if the
			% classes become too complicated
			keys = obj.cellData.keys;
			for i=1:length(keys)
				cellDataArray(i) = copy(obj.cellData(keys{i}));
			end

			newCell.AddCellData(cellDataArray);
		
		end

		function inside = IsPointInsideCell(obj, point)

			% Assemble vertices in the correct order to produce a quadrilateral

			inside = false;

		end

	end

end