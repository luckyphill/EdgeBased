classdef MembraneMultiAnalysis < Analysis

	properties

		
		r = 5;
		t0 = 9;
		tg = 9;

		mpe = [10:10:200];

		f = 0.9;

		dF = 0.5;

		seed = 1:10;

		analysisName = 'MembraneMultiAnalysis';

		parameterSet = []

		simulationRuns = 1
		slurmTimeNeeded = 24
		simulationDriverName = 'ManageTumourInMembrane'
		simulationInputCount = 6
		

	end

	methods

		function obj = MembraneMultiAnalysis()

			obj.seedIsInParameterSet = false; % The seed not given in MakeParameterSet, it is set in properties
			obj.seedHandledByScript = false; % The seed will be in the parameter file, not the job script

			obj.usingHPC = true;

		end

		function MakeParameterSet(obj)

			% radius, t0, tg, mpe, f, dF

			params = [];

			for r = obj.r
				for t0 = obj.t0
					for tg = obj.tg
						for mpe = obj.mpe
							for f = obj.f
								for dF = obj.dF

									params(end+1,:) = [r, t0, tg, mpe, f, dF];

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

		function AssembleData(obj)

			
		end

		function PlotData(obj)


		end

	end

end