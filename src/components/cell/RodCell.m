classdef RodCell < AbstractCell
	% A cell that is represented by a single edge
	properties

		preferredSeperation = 0.1
	end
	
	methods
		
		function obj = RodCell(e, cellCycleModel, id)


			obj.nodeList = e.nodeList;
			obj.elementList = e;

			obj.CellCycleModel = cellCycleModel;
			
			obj.id = id;

			obj.ancestorId = id;

			cellDataArray = [RodCellArea(), CellCentre(), TargetArea()];

			obj.AddCellData(cellDataArray);

		end


		function [newCell, newNodeList, newElementList] = Divide(obj)
			
			% When a rod cell divides, is splits at its middle point

			% It is easiest to keep the nodes attached to the same edge object
			% so a completely new edge is built

			centre = GetCellCentre(obj);

			e = obj.elementList;
			direction1to2 = e.GetVector1to2();

			newPos = centre + direction1to2 * 0.5*obj.preferredSeperation;
			oldPos = centre - direction1to2 * 0.5*obj.preferredSeperation;

			% Create the two new nodes for the edge
			n1 = Node(newPos(1), newPos(2), -1);
			n2 = Node(e.Node2.x, e.Node2.y, -1);

			e1 = Element(n1,n2,-1);

			e.Node2.AdjustPosition(oldPos);

			newCCM = obj.CellCycleModel.Duplicate();

			newCell = RodCell(e1, newCCM, -1);

			newCell.newCellTargetArea = obj.newCellTargetArea;
			newCell.grownCellTargetArea = obj.grownCellTargetArea;
			newCell.preferredSeperation = obj.preferredSeperation;
			newNodeList = [n1,n2];
			newElementList = e1;

			obj.CellCycleModel.SetAge(0);
			obj.age = 0;

			newCell.sisterCell = obj;
			obj.sisterCell = newCell;

			newCell.ancestorId = obj.id;
		
		end

		function inside = IsPointInsideCell(obj, point)

			% Assemble vertices in the correct order to produce a quadrilateral

			inside = false;

		end

	end

end