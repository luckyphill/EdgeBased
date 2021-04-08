classdef (Abstract) Analysis < matlab.mixin.SetGet
	% This is a class that controls all the details of a
	% particular analysis. It handles the generation and gathering
	% of data using the simpoint class, and collates it into useful
	% information, generally in the form of plots.
	% A given analysis can have one or many simpoints, but should only
	% produce one type of output. Different analyses can use the same data


	% There are two types of analysis, a single parameter that looks at how
	% a single instance of a simulation behaves
	% A parameter sweep, that takes average data from a bunch of simulations
	% and plots them in a grid

	properties (Abstract)

		analysisName
		parameterSet
		slurmTimeNeeded
		simulationDriverName
		simulationInputCount
		simulationRuns

	end

	properties

		result

		imageSaveLocation

		dataSaveLocation

		dataFile

		simulationFileLocation

		slurmJobArrayLimit = 10000

		seedIsInParameterSet = false

		seedHandledByScript = false

		usingHPC = false

	end

	methods (Abstract)

		% Produce a matrix where each row is a parameter set to be tested
		% This could include specific seeds if you like, but different seeds
		% can be handled in the sbatch file
		MakeParameterSet
		% Assemble the data for the analysis into its expected form. This will usually be
		% a matrix of some form. This function will be used in LoadSimulationData
		AssembleData

	end

	methods

		function ProduceSimulationFiles(obj)

			% This will make the parameter set file and the
			% shell script needed for sbatch

			obj.SetSaveDetails();

			command = '';

			if obj.seedIsInParameterSet
				% The seed in already part of obj. parameterset,so just need to dump the parameters to file
				parametersToWrite = obj.parameterSet;
			else
				% Seed is specified elsewhere
				if obj.seedHandledByScript
					% Sweeping over different seeds is handled by the job script so
					% just need to dump the parameters to file
					parametersToWrite = obj.parameterSet;
				else
					% The seed will be written in the parameter file, but is not part of
					% obj.parameterSet, so it needs to be added using the property obj.seed
					% specified in the sub class
					parametersToWrite = BuildParametersWithSeed(obj);
				end
				
			end

			if length(parametersToWrite) <= obj.slurmJobArrayLimit
				% If the parameter set is less than the job array limit, no need to
				% number the param files
				paramFile = [obj.analysisName, '.txt'];
				paramFilePath = [obj.simulationFileLocation, paramFile];
				dlmwrite( paramFilePath, parametersToWrite, 'precision','%g');

				command = obj.BuildCommand(length(parametersToWrite), paramFile);

			else
				% If it's at least obj.slurmJobArrayLimit + 1, then split it over
				% several files
				nFiles = ceil( length(parametersToWrite) / obj.slurmJobArrayLimit );
				for i = 1:nFiles-1
					paramFile = [obj.analysisName, '_', num2str(i), '.txt'];
					paramFilePath = [obj.simulationFileLocation, paramFile];
					
					iRange = (  (i-1) * obj.slurmJobArrayLimit + 1 ):( i * obj.slurmJobArrayLimit );
					dlmwrite( paramFilePath, parametersToWrite(iRange, :), 'precision','%g');
					
					command = [command, obj.BuildCommand(obj.slurmJobArrayLimit, paramFile), '\n'];

				end
				% The last chunk
				paramFile = [obj.analysisName, '_', num2str(nFiles), '.txt'];
				paramFilePath = [obj.simulationFileLocation, paramFile];
				
				iRange = (  (nFiles-1) * obj.slurmJobArrayLimit + 1 ):length(parametersToWrite);
				dlmwrite( paramFilePath, parametersToWrite(iRange, :),'precision','%g');

				command = [command, obj.BuildCommand(length(parametersToWrite) - i *obj.slurmJobArrayLimit, paramFile)];
			end

			% Now to make the shell file for sbatch  (...maybe do this later)
			fid = fopen([obj.simulationFileLocation, 'launcher.sh'],'w');
			fprintf(fid, command);
			fclose(fid);

		end

		function ProduceMissingDataSimulationFiles(obj)

			% This will make the parameter set file and the
			% shell script needed for sbatch

			obj.SetSaveDetails();

			command = '';

			if obj.seedHandledByScript
				fprintf('This functionality hasnt been implemented yet')
				parametersToWrite = [];
			else
				parametersToWrite = obj.missingParameterSet;
			end

			if length(parametersToWrite) <= obj.slurmJobArrayLimit
				% If the parameter set is less than the job array limit, no need to
				% number the param files
				paramFile = [obj.analysisName, '_missing.txt'];
				paramFilePath = [obj.simulationFileLocation, paramFile];
				dlmwrite( paramFilePath, parametersToWrite, 'precision','%g');

				command = obj.BuildCommand(length(parametersToWrite), paramFile);

			else
				% If it's at least obj.slurmJobArrayLimit + 1, then split it over
				% several files
				nFiles = ceil( length(parametersToWrite) / obj.slurmJobArrayLimit );
				for i = 1:nFiles-1
					paramFile = [obj.analysisName, '_missing_', num2str(i), '.txt'];
					paramFilePath = [obj.simulationFileLocation, paramFile];
					
					iRange = (  (i-1) * obj.slurmJobArrayLimit + 1 ):( i * obj.slurmJobArrayLimit );
					dlmwrite( paramFilePath, parametersToWrite(iRange, :), 'precision','%g');
					
					command = [command, obj.BuildCommand(obj.slurmJobArrayLimit, paramFile), '\n'];

				end
				% The last chunk
				paramFile = [obj.analysisName, '_missing_', num2str(nFiles), '.txt'];
				paramFilePath = [obj.simulationFileLocation, paramFile];
				
				iRange = (  (nFiles-1) * obj.slurmJobArrayLimit + 1 ):length(parametersToWrite);
				dlmwrite( paramFilePath, parametersToWrite(iRange, :),'precision','%g');

				command = [command, obj.BuildCommand(length(parametersToWrite) - i *obj.slurmJobArrayLimit, paramFile)];
			end

			% Now to make the shell file for sbatch  (...maybe do this later)
			fid = fopen([obj.simulationFileLocation, 'launcherMissing.sh'],'w');
			fprintf(fid, command);
			fclose(fid);

		end

		function LoadSimulationData(obj, varargin)

			% Handles the loading and storage of the aggregated data from a simulation
			% The abstract function AssembleData will run through the simulation
			% output and produce the data needed in the matrix "result". This function
			% will trigger AssembleData if no savefile exists, or if explicitly asked
			% to regenerate the data
			% The goal is to have the aggregated data all in a single file, which shouldn't
			% be too much of a stretch since the outcome of an analysis should be some
			% form of image which will most likely come from a data array. To make
			% this even easier, the data file will be saved as a .mat file to make it
			% a completely generic container

			obj.SetSaveDetails();
			obj.MakeParameterSet();

			% varargin is a flag to force reassembling
			if isempty(varargin)
				% Attempt to read data from file
				% If it doesn't exist, need to assemble the data
				if exist(obj.dataFile,'file') ~= 2
					if isempty(obj.result)
						obj.AssembleData();
					end
					result = obj.result;
					save(obj.dataFile, 'result');
				else
					try
						temp = load(obj.dataFile);
						obj.result = temp.result;
					catch err
						fprintf('Error loading file:\n%s', err.message);
					end
				end

			else
				% If anything exists in varargin, force reassemble
				obj.AssembleData();
				result = obj.result;
				save(obj.dataFile, 'result');

			end

		end

		function command = BuildCommand(obj,len,paramFile)

			% Build up the command to launch the sbatch

			% If we want each job to have a single seed, then set obj.specifySeedDirectly to true
			if ~obj.seedHandledByScript
				
				command = 'sbatch ';
				command = [command, sprintf('--array=0-%d ',len)];
				command = [command, sprintf('--time=%d:00:00 ',obj.slurmTimeNeeded)];
				command = [command, sprintf('../generalSbatch%dseed.sh ',obj.simulationInputCount)];
				command = [command, sprintf('%s ', obj.simulationDriverName)];
				command = [command, sprintf('%s ', paramFile)];

			else
				% If we want each job to handle looping through the seeds, then set obj.specifySeedDirectly to false
				command = 'sbatch ';
				command = [command, sprintf('--array=0-%d ',len)];
				command = [command, sprintf('--time=%d:00:00 ',obj.slurmTimeNeeded)];
				command = [command, sprintf('../generalSbatch%d.sh ',obj.simulationInputCount)];
				command = [command, sprintf('%s ', obj.simulationDriverName)];
				command = [command, sprintf('%s ', paramFile)];
				command = [command, sprintf('%d', obj.simulationRuns)];

			end

		end

		function params = BuildParametersWithSeed(obj)

			% This expects the seed property to be a vector of the seeds that will be applied
			% to each simulation. Each sim will have the same seeds. If different seeds
			% are required every time, this is not going to help you

			params = [];
			for i = 1:length(obj.parameterSet)
				for seed = obj.seed
					params(end+1,:) = [obj.parameterSet(i,:), seed];
				end
			end

		end

		function SetSaveDetails(obj)

			edgeBasedPath = getenv('EDGEDIR');
			if isempty(edgeBasedPath)
				error('EDGEDIR environment variable not set');
			end
			if ~strcmp(edgeBasedPath(end),'/')
				edgeBasedPath(end+1) = '/';
			end

			

			obj.imageSaveLocation = [edgeBasedPath, 'Images/', obj.analysisName, '/'];

			obj.dataSaveLocation = [edgeBasedPath, 'AnalysisOutput/', obj.analysisName, '/'];

			obj.dataFile = [obj.dataSaveLocation, 'data.mat'];

			if exist(obj.imageSaveLocation,'dir')~=7
				mkdir(obj.imageSaveLocation);
			end

			if exist(obj.dataSaveLocation,'dir')~=7
				mkdir(obj.dataSaveLocation);
			end

			% Only relevant when outputting HPC simulation files
			if obj.usingHPC
				obj.simulationFileLocation = [edgeBasedPath, 'HPC/', obj.analysisName, '/'];

				if exist(obj.simulationFileLocation,'dir')~=7
					mkdir(obj.simulationFileLocation);
				end
			end

		end

		function SavePlot(obj, h, name)
			% Necessary to save figures
			obj.SetSaveDetails();
			% Set the size of the output file
			set(h,'Units','Inches');
			pos = get(h,'Position');
			set(h,'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)]);
			
			print(h, [obj.imageSaveLocation,name],'-dpdf')

		end

		function A = Concatenate(obj, A, b)

			% Adds row vector b to the bottom of matrix A
			% If padding is needed, nans are added to the right
			% side of the matrix or vector as appropriate

			[Am,An] = size(A);
			[bm,bn] = size(b);

			if bn < An
				% pad vector
				d = An - bn;
				b = [b, nan(1,d)];
			end
			
			if bn > An
				% pad matrix
				d = bn - An;
				[m,n] = size(A);
				A = [A,nan(m,d)];
			end

			A = [A;b];

		end

	end

end
