classdef CollectMissingSets < Analysis

	% Aborted: can get this functionality within the actual analysis of interest

	properties

		% STATIC: DO NOT CHANGE
		% IF CHANGE IS NEEDED, MAKE A NEW OBJECT

		targetTime = 500;

		analysisName = 'CollectMissingSets';

		avgGrid = {}
		timePoints = {}

		stabilityGrids = {};

		parameterSet = []

		simulationRuns = 50
		slurmTimeNeeded = 12

		% These are set in the properties, but must be set in the constructor
		simulationDriverName = 'ManageDynamicLayer'
		simulationInputCount = 7
		
		missingAnalysis

	end

	methods

		function obj = CollectMissingSets(missingAnalysis)

			obj.seedIsInParameterSet = true; % The seed not given in MakeParameterSet, it is set in properties
			obj.seedHandledByScript = false; % The seed will be in the parameter file, not the job script
			obj.usingHPC = true;

			% This must be an object of the analysis with missing parameter sets
			obj.missingAnalysis = missingAnalysis;

			obj.simulationDriverName = missingAnalysis.simulationDriverName;
			obj.simulationInputCount = missingAnalysis.simulationInputCount;

		end

		function MakeParameterSet(obj)

			% w, p, g, b, f, sae, spe, seed

			params = [];

			mA = obj.missingAnalysis;

			mA.SetSaveDetails(); % So we can get the path to the parameter files

			files = dir(mA.simulationFileLocation);

			paramFiles = {};

			if mA.seedHandledByScript
				error('Cant handle this just yet')
			end

			for i = 1:length(files)
				if length(files(i).name) > 4
					if strcmp('.txt', files(i).name(end-3:end) )
						paramFiles{end} = [mA.simulationFileLocation, files(i).name];
					end
				end
			end

			if isempty(paramFiles)
				error('No files found');
			end	

			for i = 1:length(paramFiles)

				% Read each parameter file, test each parameter set to see if
				% the results exist, and if they don't, add it to the params variable
				% We are reading as text because we have to create the manager object using feval
				pFile = paramFiles{i};

				fid = fopen(pFile);

				ps = textscan(fid, '%s');

				% textscan puts the cell array in a cell array
				ps = ps{1};

				n = length(ps);


				for j = 1:n
					p = ps{j};

					q = eval([obj.simulationDriverName, '(', p{j},')']);

					q.LoadSimulationData();

					if isnan(q.data.bottomWiggleData)
						% Doesn't exist



					

			obj.parameterSet = params;

		end

		

		function BuildSimulation(obj)

			obj.MakeParameterSet();
			obj.ProduceSimulationFiles();
			
		end

		function AssembleData(obj)

			buckleThreshold = 1.05;

			MakeParameterSet(obj);

			buckleOutcome = [];
			buckleTime = [];

			for i = 1:length(obj.parameterSet)
				s = obj.parameterSet(i,:);
				% w, p, g, b, f, sae, spe, seed
				w = s(1);
				p = s(2);
				g = s(3);
				b = s(4);
				f = s(5);
				sae = s(6);
				spe = s(7);


				bottom = [];
				for j = obj.seed

					a = ManageDynamicLayer(w,p,g,b,f,sae,spe,j);
					a.LoadSimulationData();
					if ~isnan(a.data.bottomWiggleData)
						if max(a.data.bottomWiggleData) >= buckleThreshold
							buckleOutcome(i,j) = true;
							buckleTime(i,j) = find(a.data.bottomWiggleData >= buckleThreshold,1) * 20 * a.dt;
						else
							buckleOutcome(i,j) = false;
							buckleTime(i,j) = obj.targetTime;
						end
					else
						% In case the simulation fails for some reason
						buckleOutcome(i,j) = nan;
						buckleTime(i,j) = nan;
					end


				end

				fprintf('Completed %3.2f%%\n', 100*i/length(obj.parameterSet));

			end


			obj.result = {buckleOutcome, buckleTime};

			

		end

		function PlotData(obj)

			% Nothing to do



		end

	end

end