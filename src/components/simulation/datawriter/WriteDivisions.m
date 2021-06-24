classdef WriteDivisions < AbstractDataWriter
	% Stores the wiggle ratio

	properties

		% No special properties
		fileNames = {'divisions'};

		subdirectoryStructure = ''
		
	end

	methods

		function obj = WriteDivisions(subDir)

			obj.subdirectoryStructure = subDir;
			obj.samplingMultiple = 1;
			obj.multipleFiles = false;
			obj.data = {};

			obj.timeStampNeeded = false;
		end

		function GatherData(obj, t)

			% The simulation t must have a simulation data object
			% collating the complete spatial state

			obj.data = {t.simData('divisions').GetData(t)};

		end
		
	end

end