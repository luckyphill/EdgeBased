classdef FlatPlaneForceRod < AbstractTissueBasedForce
	% A force for rod cells to keep them on a flat plane


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


		function obj = FlatPlaneForceRod(springRate, point, normal, da, ds, dl)

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
				
				obj.ApplySpringForce(c.elementList.Node1);
				obj.ApplySpringForce(c.elementList.Node2);
			end

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