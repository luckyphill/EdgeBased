classdef CellCount < AbstractSimulationData
	% Gets the number of cells

	properties 

		name = 'cellCount'
		data = []
	end

	methods

		function obj = CellCount
			% No special initialisation
		end

		function CalculateData(obj, t)


			obj.data = length(t.cellList);


		end
		
	end


end