classdef Circularity < AbstractSimulationData
	% Calculates the circularity for a Ring Simulation

	properties 

		name = 'circularity'
		data = []

	end

	methods

		function obj = Circularity
			% No special initialisation
			
		end

		function CalculateData(obj, t)

			nodeList = Node.empty();
			% Collect the nodes around the inner of the organoid
			perimeter = 0;
			c = t.cellList(1);
			nodeList(end+1) = c.nodeBottomLeft;
			perimeter = perimeter + c.elementBottom.GetLength();

			c = c.GetAdjacentCellLeft();

			while c ~= t.cellList(1)
				nodeList(end+1) = c.nodeBottomLeft;
				perimeter = perimeter + c.elementBottom.GetLength();
				c = c.GetAdjacentCellLeft();
			end


			x = [nodeList.x];
			y = [nodeList.y];

			currentArea = polyarea(x,y);

			obj.data = 4*pi*currentArea / perimeter^2;

		end
		
	end


end