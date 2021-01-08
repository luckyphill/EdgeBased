classdef CellPerimeter < AbstractCellData
	% Calculates the wiggle ratio

	properties 

		name = 'cellPerimeter'
		data = []

	end

	methods

		function obj = CellPerimeter
			% No special initialisation
			
		end

		function CalculateData(obj, c)
			% Node list must be in order around the cell

			p = 0;

			for i = 1:length(c.elementList)

				p = p + c.elementList(i).GetLength();
			end

			obj.data = p;

		end
		
	end

end