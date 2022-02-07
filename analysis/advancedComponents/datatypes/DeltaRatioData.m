classdef DeltaRatioData < dataType
	% This grabs the behaviour data for a healthy crypt simulation

	properties (Constant = true)
		name = 'deltaRatioData';

		fileNames = 'deltaRatioData'
	end

	methods

		function correct = verifyData(obj, data, sp)
			% All the check we're interested in to make sure the data is correct
			% Perhaps, check that there are sufficient time steps taken?

			if data > 0
				correct = true;
			else
				correct = false;
			end

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
			% Implements the abstract method to process the output
			% and put it in the expected location, in the expected format
			
			% Do nothing, already in the correct format

		end

	end

end