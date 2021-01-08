classdef WriteQFactor < AbstractDataWriter
	% Stores the wiggle ratio

	properties

		% No special properties
		fileNames = {'QFactor'};

		subdirectoryStructure = ''
		
	end

	methods

		function obj = WriteQFactor(sm, simName)

			obj.subdirectoryStructure = simName;
			obj.samplingMultiple = sm;
			obj.multipleFiles = false;
			obj.timeStampNeeded = false;
			obj.data = {};

		end

		function GatherData(obj, t)

			% The simulation t must have a simulation data object
			% collating the complete spatial state

			obj.data = {t.simData('QFactor').GetData(t)};

		end
		
	end

end