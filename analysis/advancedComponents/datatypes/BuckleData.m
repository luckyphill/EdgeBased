classdef BuckleData < dataType
	% This grabs the behaviour data for a healthy crypt simulation

	properties (Constant = true)
		name = 'buckleData';

		fileNames = 'buckleData'
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
			folder = [sp.saveLocation, obj.name, '/'];

			if exist(folder,'dir')~=7
				mkdir(folder);
			end

			file = [folder, obj.fileNames, '_', num2str(sp.rngSeed), '.txt'];
		end

		function data = retrieveData(obj, sp)
			% Loads the data from the file and puts it in the expected format

			data = csvread(obj.getFullFileName(sp));

		end

		function processOutput(obj, sp)
			% Implements the abstract method to process the output
			% and put it in the expected location, in the expected format
			w = sp.simObj.centreLine(end,1) - sp.simObj.centreLine(1,1);
			data = [sp.simObj.t; sp.simObj.GetNumCells; w];

			try
				csvwrite(obj.getFullFileName(sp), data);
			catch
				error('bD:WriteError','Error writing to file');
			end

		end

	end

end