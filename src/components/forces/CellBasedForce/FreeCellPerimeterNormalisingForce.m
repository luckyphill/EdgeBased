classdef FreeCellPerimeterNormalisingForce < AbstractCellBasedForce

	% A normalising force to keep the edges around a free cell
	% roughly the same size. It will push each edge to have length
	% P/N, where P is the current perimeter and N the number of edges
	properties

		springRate

	end

	methods


		function obj = FreeCellPerimeterNormalisingForce(springRate)

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

			N = length(c.elementList);
			
			p = c.GetCellPerimeter / N; 

			for i = 1:N
				e = c.elementList(i);

				unitVector1to2 = e.GetVector1to2();

				l = e.GetLength();
				mag = obj.springRate * (p - l);

				force = mag * unitVector1to2;

				e.Node1.AddForceContribution(-force);
				e.Node2.AddForceContribution(force);

			end

		end

	end



end