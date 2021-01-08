classdef RodCellGrowthForce < AbstractCellBasedForce
	% Force to keep a rod cell at its preferred length


	properties

		springRate = 10;

	end

	methods


		function obj = RodCellGrowthForce(springRate)

			obj.springRate = springRate;

		end

		function AddCellBasedForces(obj, cellList)

			% For each cell in the list, calculate the forces
			% and add them to the nodes

			for i = 1:length(cellList)

				c = cellList(i);
				obj.ApplySpringForce(c);

			end

		end


		function ApplySpringForce(obj, c)

			% If the spring is in compression, push the end points away from each
			% other. Since obj.springFunction will give +ve value in this case
			% the unitvector must be made negative on Node1 and positive on Node2
			e = c.elementList;

			unitVector1to2 = e.GetVector1to2();

			n = c.GetCellTargetArea();
			l = c.GetCellArea();
			mag = obj.springRate * (n - l);

			force = mag * unitVector1to2;

			e.Node1.AddForceContribution(-force);
			e.Node2.AddForceContribution(force);

		end

	end



end