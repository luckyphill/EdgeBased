classdef AbstractSimulationData < handle
	% This class sets out the required functions for working
	% out various types of data that can be extracted from the 
	% simulation

	% This will usually be a statistic that summarises the 
	% simulation state, like the wiggle ratio. Things
	% as simple as the number of cells could be implemented
	% here, but they are fundamental enough that they can
	% be implemented in the lowest level i.e. AbstractCellSimulation
	% Anything that has a limited scope of simulations where it is 
	% useful/defined should be implemented here, as well as anything
	% that might be stored 

	% This will often be closely linked to a DataStore object

	% The intention is that the data will only be calculated on demand
	% so, for instance, if we only calculate to store it, then
	% it will only be calculated at the sampling multiple (obviously
	% this is not suitable for data that depends on previous time steps)
	% If we put the calculate operation in the get operation,
	% then we might end up calculating multiple times per time step
	% if the data is used in multiple places. To avoid this, we add in
	% a time stamp for when the data was last calculated

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
		timeStamp = -1

		

	end


	methods (Abstract)

		% This method must return data
		CalculateData(obj, t)
		
	end

	methods

		function val = GetData(obj, t)

			if obj.timeStamp == t.t
				val = obj.data;
			else
				obj.timeStamp = t.t;
				obj.CalculateData(t);
				val = obj.data;
			end

		end

	end

end