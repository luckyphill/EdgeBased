classdef DynamicCryptWobbleWatch < Analysis

	% Set up a coarse sweep of parameter values to see what is stable
	% and see if the crypt moves from vertical with any degree of regularity
	% If it does, then reinforcement might be necessary

	properties

		analysisName = 'DynamicCryptWobbleWatch';

		parameterSet = []


		% Cell cycle phase lengths
		p 	= [5,10,15];
		g 	= [5,10,15];

		% growthTriggerFraction
		f	= 0.8;

		% Force parameters
		b	= 10;
		sae	= 50;
		spe	= [10,20,30];


		% Crypt parameters
		nh	= 3;
		ch	= 8;
		wnt	= 4;

		seed = 1:2;

		%p, g, b, f, sae, spe, nh, ch, wnt, seed

		simulationRuns = 1
		slurmTimeNeeded = 72
		simulationDriverName = 'ManageDynamicCrypt'
		simulationInputCount = 9

	end

	methods

		function obj = DynamicCryptWobbleWatch()

			obj.seedIsInParameterSet = false; % The seed not given in MakeParameterSet, it is set in properties
			obj.seedHandledByScript = false; % The seed will be in the parameter file, not the job script
  			obj.usingHPC = true;

		end

		function MakeParameterSet(obj)

			params = [];

			for p = obj.p
				for g = obj.g
					for b = obj.b
						for f = obj.f
							for sae = obj.sae
								for spe = obj.spe
									for nh = obj.nh
										for ch = obj.ch
											for wnt = obj.wnt

												params(end+1,:) = [p, g, b, f, sae, spe, nh, ch, wnt];
											end
										end
									end
								end
							end
						end
					end
				end
			end

			

			obj.parameterSet = params;

		end

		function BuildSimulation(obj)

			obj.MakeParameterSet();
			obj.ProduceSimulationFiles();
			
		end

		function MakeVisualiserCommands(obj)

			% The point of this analysis is to manage the investigation
			% crypt behavior and an important part of that is inspecting
			% the videos. This creates a file that contains the commands
			% for starting a video of each parameter set

			obj.MakeParameterSet();
			obj.SetSaveDetails();

			params = obj.parameterSet;

			saveFile = [obj.dataSaveLocation, 'VisualiserCommands.txt'];

			fid = fopen(saveFile,'w');

			for i = 1:length(params)

				for j = obj.seed

					p = params(i,1);
					g = params(i,2);
					b = params(i,3);
					f = params(i,4);
					sae = params(i,5);
					spe = params(i,6);
					nh = params(i,7);
					ch = params(i,8);
					wnt = params(i,9);

					a = ManageDynamicCrypt(p, g, b, f, sae, spe, nh, ch, wnt,j);

					directory = a.simObj.pathName;
					v = Visualiser(directory);
					v.VisualiseCells;


					% fprintf(fid,"v = Visualiser('%s');\n",directory);

				end

			end

		end

	

		function AssembleData(obj)

			% No assembling yet

		end

		function PlotData(obj, varargin)

			% No plotting yet


		end

	end

end