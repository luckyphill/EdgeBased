classdef CellAreaSquare < AbstractCellData
	% Calculates the wiggle ratio

	properties 

		name = 'cellArea'
		data = []

	end

	methods

		function obj = CellAreaSquare
			% No special initialisation
			
		end

		function CalculateData(obj, c)
			% Use the shoelace formula to calculate the cellArea of the cell
			% See: https://en.wikipedia.org/wiki/Shoelace_formula
			
			tl = c.nodeTopLeft.position;
			tr = c.nodeTopRight.position;
			br = c.nodeBottomRight.position;
			bl = c.nodeBottomLeft.position;
			

			obj.data = 0.5 * abs( tl(1) * tr(2) + tr(1) * br(2) + br(1) * bl(2) + bl(1) * tl(2)...
								-  tl(2) * tr(1) - tr(2) * br(1) - br(2) * bl(1) - bl(2) * tl(1));

		end
		
	end

end