classdef CellCentre < AbstractCellData
	% Calculates the geometric centre of the cell

	properties 

		name = 'cellCentre'
		data = []

	end

	methods

		function obj = CellCentre
			% No special initialisation
			
		end

		function CalculateData(obj, c)
			% Node list must be in order around the cell

			x = [c.nodeList.x];
			y = [c.nodeList.y];
			obj.data = [mean(x), mean(y)];

		end
		
	end

end