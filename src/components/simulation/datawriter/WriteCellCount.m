classdef WriteCellCount < AbstractDataWriter
	% Stores the wiggle ratio

	properties

		% No special properties
		fileNames = {'CellCount'};

		subdirectoryStructure = ''
		
	end

	methods

		function obj = WriteCellCount(sm, simName)

			obj.subdirectoryStructure = simName;
			obj.samplingMultiple = sm;
			obj.multipleFiles = false;
			obj.timeStampNeeded = true;
			obj.data = {};

		end

		function GatherData(obj, t)

			% The simulation t must have a simulation data object
			% collating the complete spatial state

			% obj.data = {t.simData('cellCount').GetData(t)};
			obj.data = {length(t.cellList)};

		end
		
	end

end