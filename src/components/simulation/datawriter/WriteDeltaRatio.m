classdef WriteDeltaRatio < AbstractDataWriter
	% Stores the wiggle ratio

	properties

		% No special properties
		fileNames = {'DeltaRatio'};

		subdirectoryStructure = ''
		
	end

	methods

		function obj = WriteDeltaRatio(sm, simName)

			obj.subdirectoryStructure = simName;
			obj.samplingMultiple = sm;
			obj.multipleFiles = false;
			obj.timeStampNeeded = true;
			obj.data = {};

		end

		function GatherData(obj, t)

			% The simulation t must have a simulation data object
			% collating the complete spatial state

			obj.data = {t.simData('deltaRatio').GetData(t)};

		end
		
	end

end