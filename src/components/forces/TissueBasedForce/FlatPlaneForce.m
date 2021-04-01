classdef FlatPlaneForce < AbstractTissueBasedForce
	% This adds a force to the bottom cells based on their distance from a flat plane
	% The flat plane is determined by a point and a normal

	% It assumes a single connected layer of SquareCellJoined, so it can find nodeBottomRight


	properties

		point
		normal
		k
		da
		ds
		dl

		c = 5

	end

	methods


		function obj = FlatPlaneForce(springRate, point, normal, da, ds, dl)

			obj.point = point;
			obj.normal = normal;
			obj.k = springRate;
			obj.da = da;
			obj.ds = ds;
			obj.dl = dl;


		end

		function AddTissueBasedForces(obj, tissue)

			for i = 1:length(tissue.cellList)
				c = tissue.cellList(i);
				n = c.nodeBottomRight;
				obj.ApplySpringForce(n);
			end

			% The loop only gets the bottom right, meaning the left node
			% on the left cell gets missed, so need to do it manually
			bcs = tissue.simData('boundaryCells').GetData(tissue);
			leftCell = bcs('left');
			obj.ApplySpringForce(leftCell.nodeBottomLeft);
		end


		function ApplySpringForce(obj, n)

			PtoN = n.position - obj.point;
			x = dot(PtoN, obj.normal);

			Fa = 0;

				
			if (obj.da < x) && ( x < obj.ds)

				Fa = obj.k * log(  ( obj.ds - obj.da ) / ( x - obj.da )  );
			end

			if (obj.ds <= x ) && ( x < obj.dl )

				Fa = obj.k * (  ( obj.ds - x ) / ( obj.ds - obj.da )  ) * exp(obj.c*(obj.ds - x)/obj.ds );

			end

			n.AddForceContribution(Fa);

		end

	end

end