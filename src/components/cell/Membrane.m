classdef Membrane < AbstractCell
	% A membrane represented by a string of edges
	% It does no divide since it is not a cell,
	% but the divide method can be used to increase the
	% number of edges it contains, which will be useful
	% if we want it to grow in any way
	
	methods
		
		function obj = Membrane(nodeList, elementList, id)

			obj.cellType = 6; % Magic number - need to deal with this systematically

			obj.nodeList = nodeList;
			obj.elementList = elementList;

			obj.CellCycleModel = NoCellCycle();
			
			obj.id = id;

			obj.ancestorId = id;

			for i = 1:length(nodeList)
				nodeList(i).cellList = obj;
			end

			for i = 1:length(elementList)
				elementList(i).cellList = obj;
			end

			cellDataArray = [CellPerimeter(), TargetPerimeter()];

			obj.AddCellData(cellDataArray);

		end


		function [newCell, newNodeList, newElementList] = Divide(obj)
			
			% The membrane doesn't divide, but in the future we may be able to use this
			% to allow the membrane to grow.

			newCell = Cell.empty();
			newNodeList = Node.empty();
			newElementList = Element.empty();
		
		end

		function inside = IsPointInsideCell(obj, point)

			% Assemble vertices in the correct order to produce a quadrilateral

			inside = false;

		end

	end

end