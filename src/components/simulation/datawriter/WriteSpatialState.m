classdef WriteSpatialState < AbstractDataWriter
	% Stores the wiggle ratio

	properties

		% No special properties
		fileNames = {'nodes', 'elements', 'cells'};

		subdirectoryStructure = ''
		
	end

	methods

		function obj = WriteSpatialState(sm, subDir)

			obj.subdirectoryStructure = [subDir, 'SpatialState/'];;
			obj.samplingMultiple = sm;
			obj.multipleFiles = false;
			obj.data = {};

		end

		function GatherData(obj, t)

			% The simulation t must have a simulation data object
			% collating the complete spatial state

			obj.data = t.simData('spatialState').GetData(t);

		end
		
	end

end