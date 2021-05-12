classdef ManageTumourInMembrane < MatlabSimulation
	% Manages the running and data handling of the TumourInMembrane simulation
	% for the analysis in the buckling framework paper


	properties (SetAccess = immutable)

		matlabTest = 'TumourInMembrane'

	end

	properties (SetAccess = private)

		% Number of cells
		r 			double {mustBeNonnegative}

		% Cell cycle phase lengths
		t0 			double {mustBeNonnegative}
		tg 			double {mustBeNonnegative}

		% growthTriggerFraction
		f			double {mustBeNonnegative}

		mpe			double {mustBeNonnegative}
		

		% These are solver parameters
		t 	= 300	double {mustBeNonnegative}
		dt 	= 0.002

		% This is the RNG seed parameter
		rngSeed 	double {mustBeNumeric}

		outputLocation

	end

	methods
		function obj = ManageTumourInMembrane(radius, t0, tg, mpe, f, seed)

			obj.r 		= radius;
			obj.t0 		= t0;
			obj.tg 		= tg;
			obj.mpe		= mpe;
			obj.f 		= f;
	
			obj.rngSeed = seed;

			

			obj.simObj = TumourInMembrane(radius, t0, tg, mpe, f, seed);
			obj.simObj.dt = obj.dt;
			
			% Remove the default spatial state output
			remove(obj.simObj.simData,'spatialState');
			obj.simObj.dataWriters = AbstractDataWriter.empty();

			obj.outputTypes = {MembraneData(), CellCOuntData()};

			obj.GenerateSaveLocation();

			warning('off','sim:LoadFailure')
			obj.LoadSimulationData();
			warning('on','sim:LoadFailure')

			% Only add the data types that are missing
			if isnan(obj.data.membraneData)
				obj.simObj.AddSimulationData(MembraneProperties());
				obj.simObj.AddDataWriter(WriteMembraneProperties(20,obj.simObj.pathName));
			end

			if isnan(obj.data.cellCountData)
				obj.simObj.AddSimulationData(CellCount());
				obj.simObj.AddDataWriter(WriteCellCount(20,obj.simObj.pathName));
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

			obj.simObj.RunToConfluence(obj.t);

		end

	end

end








