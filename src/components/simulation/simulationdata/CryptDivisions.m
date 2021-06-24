classdef CryptDivisions < AbstractSimulationData
	% Returns the locations of divisions
	% The number stored is the centre point of the cell
	% immediately before division. For dynamic crypts
	% this is the 

	properties 

		name = 'divisions'
		data = []

	end

	methods

		function obj = CryptDivisions
			% No special initialisation
			
		end

		function CalculateData(obj, t)

			% Get the niche bottom and use this as the reference point
			base = t.simData('nicheBottom').GetData(t);
			data = [];
			for i = 1:length(t.cellList)

				c = t.cellList(i);
				if c.IsReadyToDivide()
					centre = c.GetCellCentre();
					data(end + 1) =  centre(2) - base;
				end

			end

			obj.data = data;


		end
		
	end


end