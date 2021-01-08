classdef TargetPerimeterSquare < AbstractCellData
	% Returns the target area of a square/rectangular cell
	% The cell will start off with an area of 0.5 and perimeter of 3
	% and end with an area of 1 and perimeter of 4

	properties 

		name = 'targetPerimeter'
		data = []

	end

	methods

		function obj = TargetPerimeterSquare
			% No special initialisation
			
		end

		function CalculateData(obj, c)
			% Node list must be in order around the cell

			targetArea = c.cellData('targetArea').GetData(c);

			obj.data = 2 * (1 + targetArea);

		end
		
	end

end