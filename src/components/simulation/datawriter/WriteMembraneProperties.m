classdef WriteMembraneProperties < AbstractDataWriter
	% Stores the wiggle ratio

	properties

		% No special properties
		fileNames = {'MembraneProperties'};

		subdirectoryStructure = ''
		
	end

	methods

		function obj = WriteMembraneProperties(sm, simName)

			obj.subdirectoryStructure = simName;
			obj.samplingMultiple = sm;
			obj.multipleFiles = false;
			obj.timeStampNeeded = true;
			obj.data = {};

		end

		function GatherData(obj, t)

			% The simulation t must have a simulation data object
			% collating the complete spatial state

			obj.data = {t.simData('membraneProperties').GetData(t)};

		end
		
	end

end