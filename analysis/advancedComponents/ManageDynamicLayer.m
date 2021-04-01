classdef ManageDynamicLayer < MatlabSimulation
	% Manages the running and data handling of the DynamicLayer simulation
	% for the various analyses around buckling


	properties (SetAccess = immutable)

		matlabTest = 'DynamicLayer'

	end

	properties (SetAccess = private)

		% Number of cells
		w 			double {mustBeNonnegative}

		% Cell cycle phase lengths
		p 			double {mustBeNonnegative}
		g 			double {mustBeNonnegative}

		% growthTriggerFraction
		f			double {mustBeNonnegative}

		% Force parameters
		b			double {mustBeNonnegative}
		sae			double {mustBeNonnegative}
		spe			double {mustBeNonnegative}

		% These are solver parameters
		t 			double {mustBeNonnegative}
		dt 	= 0.002

		% This is the RNG seed parameter
		rngSeed 	double {mustBeNumeric}

		outputLocation
	end

	properties

		buckledWiggleRatio = 1.1

	end

	methods
		function obj = ManageDynamicLayer(w, p, g, b, f, sae, spe, seed)

			obj.w 		= w;
			obj.p 		= p;
			obj.g 		= g;
			obj.f 		= f;
			obj.b 		= b;
			obj.sae		= sae;
			obj.spe		= spe;
			obj.rngSeed = seed;

			

			obj.simObj = DynamicLayer(w, p, g, b, f, sae, spe, seed);
			obj.simObj.dt = obj.dt;
			
			% Remove the default spatial state output, and add the wiggle ratio output
			remove(obj.simObj.simData,'spatialState');
			obj.simObj.AddSimulationData(BottomWiggleRatio());
			obj.simObj.dataWriters = WriteBottomWiggleRatio(20,obj.simObj.pathName);

			obj.outputTypes = {BottomWiggleData};

			obj.GenerateSaveLocation();

		end

	end


	methods (Access = protected)
		% Helper methods to build the class


		function GenerateSaveLocation(obj)
			% This generates the full path to the specific data file for the simulation
			% If the path doesn't exist it creates the missing folder structure

			obj.saveLocation = obj.simObj.simulationOutputLocation;

		end

		function SimulationCommand(obj)

			obj.simObj.RunToBuckle(obj.buckledWiggleRatio);

		end

	end

end








