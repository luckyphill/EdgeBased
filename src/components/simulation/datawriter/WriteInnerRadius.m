classdef WriteInnerRadius < AbstractDataWriter
	% Stores the inner radius for relevant simulations

	properties

		% No special properties
		fileNames = {'InnerRadius'};

		subdirectoryStructure = ''
		
	end

	methods

		function obj = WriteInnerRadius(sm, simName)

			obj.subdirectoryStructure = simName;
			obj.samplingMultiple = sm;
			obj.multipleFiles = false;
			obj.timeStampNeeded = true;
			obj.data = {};

		end

		function GatherData(obj, t)

			% The simulation t must have a simulation data object
			% collating the complete spatial state

			obj.data = {t.simData('innerRadius').GetData(t)};

		end
		
	end

end