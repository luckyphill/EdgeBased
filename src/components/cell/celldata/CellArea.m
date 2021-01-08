classdef CellArea < AbstractCellData
	% Calculates the wiggle ratio

	properties 

		name = 'cellArea'
		data = []

	end

	methods

		function obj = CellArea
			% No special initialisation
			
		end

		function CalculateData(obj, c)
			% Node list must be in order around the cell

			x = [c.nodeList.x];
			y = [c.nodeList.y];
			obj.data = polyarea(x,y);

		end
		
	end

end