classdef WriteBottomWiggleRatio < AbstractDataWriter
	% Stores the wiggle ratio

	properties

		% No special properties
		fileNames = {'bottomwiggleratio'};

		subdirectoryStructure = ''
		
	end

	methods

		function obj = WriteBottomWiggleRatio(sm, simName)

			obj.subdirectoryStructure = simName;
			obj.samplingMultiple = sm;
			obj.multipleFiles = false;
			obj.timeStampNeeded = false;
			obj.data = {};

		end

		function GatherData(obj, t)

			% The simulation t must have a simulation data object
			% collating the complete spatial state

			obj.data = {t.simData('bottomWiggleRatio').GetData(t)};

		end
		
	end

end