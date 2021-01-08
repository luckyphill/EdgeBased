classdef CentreLineLoop < AbstractSimulationData
	% Calculates the wiggle ratio

	properties 

		% Sneakily keeping the name the same so
		% base functions get the right one no matter
		% the simulation type
		name = 'centreLine'
		data = []

	end

	methods

		function obj = CentreLineLoop
			% No special initialisation

		end

		function CalculateData(obj, t)

			% Makes a sequence of points that defines the centre line of the cells
			cL = [];

			% If it is a loop, then really it doesn't matter where we start
			% in fact, if all we care about is the length, then there's
			% no need to just from one cell to the next in order... Oh well
			
			cs = t.cellList(1); %t.simData('startCell').GetData();

			cL(end + 1, :) = cs.elementLeft.GetMidPoint();
			
			e = cs.elementRight;
			cL(end + 1, :) = e.GetMidPoint();

			% Jump through the cells until we hit the right most cell
			c = e.GetOtherCell(cs);

			while c ~= cs

				e = c.elementRight;
				cL(end + 1, :) = e.GetMidPoint();
				c = e.GetOtherCell(c);
			end

			obj.data = cL;

		end
		
	end


end