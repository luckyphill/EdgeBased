classdef (Abstract) AbstractCellData < handle & matlab.mixin.Heterogeneous
	% This class sets out the required functions for working
	% out various types of data that can be extracted from the 
	% a cell

	% This will usually be a statistic that summarises the 
	% cell state like the area. It shouldn't be used for things
	% that don't really need calculating

	% The intention is that the data will only be calculated on demand
	% so, for instance, if we only calculate to store it, then
	% it will only be calculated at the sampling multiple (obviously
	% this is not suitable for data that depends on previous time steps)
	% If we put the calculate operation in the get operation,
	% then we might end up calculating multiple times per time step
	% if the data is used in multiple places. To avoid this, we add in
	% an age stamp for when the data was last calculated

	properties (Abstract)

		% A unique identifier so the data can be accessed
		% in a way that has a meaningful interpretation
		% instead of an index
		name

		% A structure that holds the data within a timestep
		data

	end

	properties

		% The last time point when the data was calculated
		% saves calculating repeatedly in a single time step
		ageStamp = -1

	end


	methods (Abstract)

		% This method must return data
		CalculateData(obj, t)
		
	end

	methods

		function val = GetData(obj, c)

			if obj.ageStamp == c.GetAge()
				val = obj.data;
			else
				obj.ageStamp = c.GetAge();
				obj.CalculateData(c);
				val = obj.data;
			end

		end

	end

end