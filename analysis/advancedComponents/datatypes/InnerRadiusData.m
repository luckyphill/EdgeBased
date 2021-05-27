classdef InnerRadiusData < dataType
	% This grabs the membrane data

	properties (Constant = true)
		name = 'innerRadiusData';

		fileNames = 'InnerRadius'
	end

	methods

		function correct = verifyData(obj, data, sp)
			% All the check we're interested in to make sure the data is correct
			% Perhaps, check that there are sufficient time steps taken?

			% Check nothing yet
			correct = true;


		end

		function found = exists(obj, sp)
			% Checks if the file exists
			found = exist(obj.getFullFileName(sp), 'file');

		end
	end

	methods (Access = protected)

		function file = getFullFileName(obj,sp)
			
			file = [sp.saveLocation, obj.fileNames, '.csv'];

		end

		function data = retrieveData(obj, sp)
			% Loads the data from the file and puts it in the expected format

			data = csvread(obj.getFullFileName(sp));

		end

		function processOutput(obj, sp)
			
			% Do nothing, simulation already puts it in the right spot

		end

	end

end