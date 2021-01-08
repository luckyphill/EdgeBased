classdef WriteNodeSpatialState < AbstractDataWriter
	% Stores the wiggle ratio

	properties

		% No special properties
		fileNames = {'nodes', 'cells'};

		subdirectoryStructure = ''
		
	end

	methods

		function obj = WriteNodeSpatialState(sm, simName)

			obj.subdirectoryStructure = [simName, 'NodeSpatialState/'];
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