classdef ManageDynamicCrypt < MatlabSimulation
	% Manages the running and data handling of the DynamicCrypt simulation
	% for the various analyses around buckling


	properties (SetAccess = immutable)

		matlabTest = 'DynamicCrypt'

	end

	properties (SetAccess = private)


		% Cell cycle phase lengths
		p 			double {mustBeNonnegative}
		g 			double {mustBeNonnegative}

		% growthTriggerFraction
		f			double {mustBeNonnegative}

		% Force parameters
		b			double {mustBeNonnegative}
		sae			double {mustBeNonnegative}
		spe			double {mustBeNonnegative}


		% Crypt parameters
		nh			double {mustBeNonnegative}
		ch			double {mustBeNonnegative}
		wnt			double {mustBeNonnegative}

		% These are solver parameters
		t 			double {mustBeNonnegative}
		dt 	= 0.001

		% This is the RNG seed parameter
		rngSeed 	double {mustBeNumeric}

		outputLocation
	end

	properties

		buckledWiggleRatio = 1.1

	end

	methods
		function obj = ManageDynamicCrypt(p, g, b, f, sae, spe, nh, ch, wnt, seed)

			obj.p 		= p;
			obj.g 		= g;
			obj.f 		= f;
			obj.b 		= b;
			obj.sae		= sae;
			obj.spe		= spe;
			obj.nh 		= nh;
			obj.ch		= ch;
			obj.wnt		= wnt;
			obj.rngSeed = seed;

			

			obj.simObj = DynamicCrypt(p, g, b, f, sae, spe, nh, ch, wnt, seed);
			% obj.simObj.dt = obj.dt;
			
			% Remove the default spatial state output
			% remove(obj.simObj.simData,'spatialState');
			% In general we don't want to observe the full spatial state,
			% but it can be handy for debugging and verifying simulations
			% succeeded to have some spatial state output, so we output once per
			% simulation hour
			obj.simObj.dataWriters = AbstractDataWriter.empty();
			obj.simObj.AddDataWriter(WriteSpatialState(ceil(1/obj.simObj.dt),obj.simObj.pathName));


			obj.outputTypes = {CellCountData, DeltaRatioData};

			obj.GenerateSaveLocation();

			warning('off','sim:LoadFailure')
			obj.LoadSimulationData();
			warning('on','sim:LoadFailure')

			% Only add the data types that are missing
			if isnan(obj.data.cellCountData)
				obj.simObj.AddSimulationData(CellCount());
				obj.simObj.AddDataWriter(WriteCellCount(20,obj.simObj.pathName));
			end

			if isnan(obj.data.deltaRatioData)
				obj.simObj.AddSimulationData(DeltaRatio());
				obj.simObj.AddDataWriter(WriteDeltaRatio(20,obj.simObj.pathName));
			end

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

			obj.simObj.RunToTime(300);

		end

	end

end








