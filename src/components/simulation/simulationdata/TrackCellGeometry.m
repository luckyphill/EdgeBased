classdef TrackCellGeometry < AbstractSimulationData
	% Tracks the area and perimeter of the cells

	properties 

		name = 'cellGeometry'
		data = []

	end

	methods

		function obj = TrackCellGeometry()
			% No special initialisation
		end

		function CalculateData(obj, t)

			data = [];
			for i = 1:length(t.cellList)
				
				c = t.cellList(i);

				 data(i,:) = [c.id, c.GetAge(), c.GetCellArea(), c.GetCellPerimeter(), c.GetCellTargetArea(), c.GetCellTargetPerimeter()];

			end

			obj.data = data;

		end
		
	end


end