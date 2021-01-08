classdef TargetPerimeter < AbstractCellData
	% Target perimeter for the general case with CellFree etc.

	properties 

		name = 'targetPerimeter'
		data = []

	end

	methods

		function obj = TargetPerimeter
			% No special initialisation
			
		end

		function CalculateData(obj, c)
			% Node list must be in order around the cell

			targetArea = c.cellData('targetArea').GetData(c);

			% Assume the cell wants to be a regular polygon
			% Use the number of elements to decide what type

			% From https://en.wikipedia.org/wiki/Regular_polygon#Area the perimeter
			% of a regular polygon for a given area is
			% p * a = 2A
			% Where A is the area, and a is the apothem (the line from the centre to 
			% the mid point of an edge)
			% The formula for a = p / 2ntan(pi/n)
			% 2A = p^2/2ntan(pi/n)
			% p = sqrt(4Antan(pi/n))

			n = length(c.elementList);

			obj.data = sqrt(4 * targetArea * n * tan(pi/n) );

		end
		
	end

end